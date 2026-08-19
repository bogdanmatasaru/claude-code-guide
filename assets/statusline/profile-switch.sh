#!/bin/sh
# profile-switch.sh — provider- and account-aware ccstatusline launcher.
#
# Picks the right ccstatusline profile for the session, then runs ccstatusline
# with it. Wire it into ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "sh $HOME/.config/ccstatusline/profile-switch.sh", "padding": 0 }
#
# WHY this exists
#   ccstatusline's session-usage / weekly-usage / weekly-reset-timer widgets read
#   the five_hour / seven_day rate-limit buckets from api.anthropic.com/api/oauth/usage.
#   MOST Enterprise/Team seats return those buckets as null (but not all — see the
#   payload check in the enterprise branch below), so those widgets render
#   "[Timeout]" (a pessimistic-lock label, not a real network timeout — the API
#   answers 200 in <0.5s). Enterprise exposes a monthly pay-as-you-go bucket
#   (extra_usage) instead. So we ship three profiles and auto-select.
#
#   - settings.custom-endpoint.json : no usage widgets at all (see below)
#   - settings.enterprise.json      : 5h block reset timer + extra-usage-remaining
#   - settings.consumer.json        : the classic 5h/7d usage % + reset widgets
#   - settings.json                 : ccstatusline default, the fallback
#
# CUSTOM ENDPOINTS (ANTHROPIC_BASE_URL) — checked FIRST, and it matters
#   Claude Code omits rate_limits from the status-line payload unless you are on a
#   Claude.ai subscription. When it is missing, ccstatusline does not blank the
#   usage widgets: it falls back to api.anthropic.com/api/oauth/usage using the
#   token in your macOS Keychain. On a session pointed at another provider that
#   renders YOUR ANTHROPIC quota next to that provider's model name — numbers that
#   are plausible, confident, and about a different account than the one answering.
#   Account detection cannot fix this: you can hold a Max seat and still run a
#   session against another endpoint. So provider is decided before account, from
#   ANTHROPIC_BASE_URL (Claude Code exports the settings `env` block into
#   status-line subprocesses), on every invocation and never cached — it is a
#   string comparison, not a network call. If the profile is missing we print a
#   hint rather than falling through to a profile with usage widgets: a blank
#   field costs nothing, a wrong percentage costs you a plan decision.
#
#   Bedrock / Vertex / Foundry have no oauth usage either and set no base URL, so
#   they are detected by their own CLAUDE_CODE_USE_* variables and get the same
#   profile. Deciding to render nothing needs no knowledge of their payload shape.
#
# ENTERPRISE ROUTING AND SHIM (verified on seats of both kinds)
#   ccstatusline fetches usage ONCE per render and shares it across all Usage
#   widgets, UNIONing their required fields. reset-timer requires sessionResetAt.
#   On MOST enterprise seats the statusline payload carries no usable rate_limits,
#   so that field is unsatisfiable and the shared object flips to {error}, which
#   would make extra-usage-remaining show "[Timeout]" too. For those payloads we
#   inject a synthetic rate_limits.five_hour.resets_at (the 5h block reset, read
#   from ccstatusline's own block-cache) so sessionResetAt is satisfied LOCALLY,
#   never enters the API fetch, and the timer + monthly credit both render stably.
#   But SOME enterprise/team seats deliver real five_hour AND seven_day buckets in
#   the payload; those get the consumer profile instead — the routing lives in
#   route_enterprise(), one interpreter run that both decides and shims.
#
# Detection is cached for $TTL seconds. No credential value is ever printed; only
# the subscriptionType field is read from the Keychain item.
set -u

CONFIG_DIR="$HOME/.config/ccstatusline"
ENTERPRISE="$CONFIG_DIR/settings.enterprise.json"
CONSUMER="$CONFIG_DIR/settings.consumer.json"
CUSTOM="$CONFIG_DIR/settings.custom-endpoint.json"
CACHE="$CONFIG_DIR/.active-profile"
TTL=300

CCSTATUSLINE="$(command -v ccstatusline 2>/dev/null || echo /opt/homebrew/bin/ccstatusline)"
PYTHON="$(command -v python3 2>/dev/null || echo /usr/bin/python3)"

# Provider gate. Returns 0 only when this session talks to Anthropic's own API
# on a Claude.ai subscription — the one case where the usage widgets have data.
#
# Bedrock / Vertex / Foundry set no ANTHROPIC_BASE_URL, so a base-URL test alone
# would wave them through to the consumer profile and render the Anthropic quota
# beside a cloud-provider model. They get the custom-endpoint profile too.
#
# The base-URL match is exact, so a lookalike host (api.anthropic.com.example.net)
# does not pass as first-party. Every other spelling — http://, uppercase, an
# explicit :443, stray whitespace — falls to the custom profile, which loses
# widgets rather than showing the wrong ones.
is_first_party() {
  [ -n "${CLAUDE_CODE_USE_BEDROCK:-}" ] && return 1
  [ -n "${CLAUDE_CODE_USE_VERTEX:-}" ]  && return 1
  [ -n "${CLAUDE_CODE_USE_FOUNDRY:-}" ] && return 1
  [ -n "${CLAUDE_CODE_USE_ANTHROPIC_AWS:-}" ] && return 1
  [ -n "${ANTHROPIC_BEDROCK_BASE_URL:-}" ]    && return 1
  [ -n "${ANTHROPIC_VERTEX_BASE_URL:-}" ]     && return 1
  case "${ANTHROPIC_BASE_URL:-}" in
    "") return 0 ;;
    https://api.anthropic.com|https://api.anthropic.com/*) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_first_party; then
  if [ -f "$CUSTOM" ]; then
    exec "$CCSTATUSLINE" --config "$CUSTOM"
  fi
  # Fail closed: never fall through. Bare ccstatusline reads
  # ~/.config/ccstatusline/settings.json, which setup.sh installs as the consumer
  # layout — usage widgets and all. Printing a hint costs nothing; rendering
  # another account's numbers costs a plan decision.
  printf 'custom endpoint · run ./setup.sh to install the status-line profile\n'
  exit 0
fi

# Read subscriptionType from the macOS Keychain (only that field; never the token).
# On non-macOS, fall back to ~/.claude/.credentials.json.
read_subscription() {
  creds=""
  if command -v security >/dev/null 2>&1; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  fi
  [ -z "$creds" ] && [ -f "$HOME/.claude/.credentials.json" ] && creds=$(cat "$HOME/.claude/.credentials.json" 2>/dev/null)
  printf '%s' "$creds" | "$PYTHON" -c 'import sys, json
try:
    d = json.load(sys.stdin) or {}
    print(((d.get("claudeAiOauth") or {}).get("subscriptionType")) or "")
except Exception:
    print("")' 2>/dev/null
}

pick_profile() {
  case "$(read_subscription)" in
    enterprise|team) [ -f "$ENTERPRISE" ] && printf '%s' "$ENTERPRISE" ;;
    *)               [ -f "$CONSUMER" ]   && printf '%s' "$CONSUMER" ;;
  esac
}

# Enterprise only: one interpreter run both routes and shims, so the two verdicts
# cannot drift. Exit 3 = the payload carries usable five_hour AND seven_day buckets
# (printed unchanged; render the consumer profile — the usage widgets have data).
# Exit 0 = enterprise layout; when five_hour.resets_at is missing OR hollow, a
# synthetic one is injected (5h block reset, from ccstatusline's block-cache) so
# reset-timer's required field is met locally and never poisons the shared usage
# fetch. "Hollow" matters: some seats send rate_limits with null buckets, which is
# not the same as no rate_limits at all, and a shim keyed on mere presence would
# skip exactly the payloads it exists for.
route_enterprise() {
  "$PYTHON" -c 'import sys, json, glob, os, time, datetime
try:
    d = json.load(sys.stdin)
    if not isinstance(d, dict):
        d = {}
except Exception:
    d = {}
rl = d.get("rate_limits") or {}
fh = rl.get("five_hour") or {}
sd = rl.get("seven_day") or {}
if fh.get("used_percentage") is not None and sd.get("used_percentage") is not None:
    json.dump(d, sys.stdout)
    sys.exit(3)
if fh.get("resets_at") is None:
    r = None
    bc = sorted(glob.glob(os.path.expanduser("~/.cache/ccstatusline/block-cache-*.json")))
    if bc:
        try:
            s = json.load(open(bc[-1])).get("startTime")
            t = datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))
            r = int(t.timestamp()) + 5 * 3600
        except Exception:
            r = None
    if r is None:
        r = int(time.time()) + 5 * 3600
    d["rate_limits"] = dict(rl, five_hour={"resets_at": r, "used_percentage": fh.get("used_percentage") or 0})
json.dump(d, sys.stdout)'
}

cfg=""
if [ -f "$CACHE" ]; then
  now=$(date +%s)
  mtime=$(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0)
  if [ $(( now - mtime )) -lt "$TTL" ]; then
    cfg=$(cat "$CACHE" 2>/dev/null)
  fi
fi

if [ -z "$cfg" ] || [ ! -f "$cfg" ]; then
  cfg=$(pick_profile)
  [ -n "$cfg" ] && { printf '%s' "$cfg" > "$CACHE"; } 2>/dev/null
fi

if [ "$cfg" = "$ENTERPRISE" ] && [ -f "$cfg" ]; then
  # "Enterprise means no 5h/7d buckets" is per-org, not universal: some team and
  # enterprise seats deliver rate_limits in the statusline payload like any
  # consumer plan, and for them the enterprise profile hides a live quota while
  # rendering "credit n/a" beside it. The payload is the authority, checked per
  # render from the payload already in hand — no network call; the cache keeps
  # deciding only the subscription tier. Consumer needs BOTH buckets: its weekly
  # widgets make a five_hour-only payload flip the shared usage object to {error}
  # and take the working 5h gauge down with it. Known trade-off: a bucket-bearing
  # seat with a funded extra_usage balance loses the credit widget to this route;
  # that combination has not been observed — build a combined profile if it shows
  # up, do not re-hide the quota.
  input=$(cat)
  routed=$(printf '%s' "$input" | route_enterprise 2>/dev/null)
  rc=$?
  if [ "$rc" = "3" ]; then
    if [ -f "$CONSUMER" ]; then
      printf '%s' "$routed" | "$CCSTATUSLINE" --config "$CONSUMER"
    else
      # Same convention as the custom-endpoint branch: a hint beats silently
      # rendering the layout this branch just proved wrong.
      printf 'consumer profile missing · run ./setup.sh to reinstall the status-line profiles\n'
    fi
  elif [ "$rc" = "0" ] && [ -n "$routed" ]; then
    printf '%s' "$routed" | "$CCSTATUSLINE" --config "$cfg"
  else
    # python3 unavailable or the route died: fall back to the raw payload rather
    # than showing nothing.
    printf '%s' "$input" | "$CCSTATUSLINE" --config "$cfg"
  fi
elif [ -n "$cfg" ] && [ -f "$cfg" ]; then
  exec "$CCSTATUSLINE" --config "$cfg"
else
  exec "$CCSTATUSLINE"
fi
