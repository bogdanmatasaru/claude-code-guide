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
#   But a base URL that is not api.anthropic.com is not proof of a foreign
#   account. A local pass-through proxy — a usage collector on 127.0.0.1, a
#   corporate gateway — still talks to Anthropic with your own credentials, and
#   blanking the quota there hides live numbers for no gain. Claude Code marks
#   the difference in the payload it already hands this script: it emits
#   rate_limits ONLY for a Claude.ai subscription session on an endpoint it
#   accepts as first-party. So when BOTH buckets arrive, the percentages describe
#   the account answering this session, the widgets read them from stdin and make
#   no oauth fetch, and the consumer profile is the right one. That is the same
#   rule route_enterprise applies a few lines down: the payload has the final
#   word. Bedrock / Vertex / Foundry are exempt from the override — they are
#   decided by their own variables, before stdin is ever read.
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

# Claude Code sends a rate-limit window as null when it has no data for it (seen
# since 2026-10-23: five_hour null, seven_day set). ccstatusline's schema accepts a
# missing window but rejects null, and then prints "Invalid status JSON format"
# instead of the whole bar, context included. Dropping the null keys turns them into
# the missing case it already handles. Unparseable input passes through unchanged.
run_ccstatusline() {
  "$PYTHON" -I -c 'import sys, json
raw = sys.stdin.read()
try:
    d = json.loads(raw)
    rl = d.get("rate_limits")
    if rl is None:
        d.pop("rate_limits", None)
    elif isinstance(rl, dict):
        d["rate_limits"] = {k: v for k, v in rl.items() if v is not None}
    raw = json.dumps(d)
except Exception:
    pass
sys.stdout.write(raw)' 2>/dev/null | "$CCSTATUSLINE" "$@"
}

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
uses_cloud_provider() {
  [ -n "${CLAUDE_CODE_USE_BEDROCK:-}" ] && return 0
  [ -n "${CLAUDE_CODE_USE_VERTEX:-}" ]  && return 0
  [ -n "${CLAUDE_CODE_USE_FOUNDRY:-}" ] && return 0
  [ -n "${CLAUDE_CODE_USE_ANTHROPIC_AWS:-}" ] && return 0
  [ -n "${ANTHROPIC_BEDROCK_BASE_URL:-}" ]    && return 0
  [ -n "${ANTHROPIC_VERTEX_BASE_URL:-}" ]     && return 0
  return 1
}

base_url_is_first_party() {
  case "${ANTHROPIC_BASE_URL:-}" in
    "") return 0 ;;
    https://api.anthropic.com|https://api.anthropic.com/*) return 0 ;;
    *) return 1 ;;
  esac
}

# Fail closed: never fall through to bare ccstatusline. It reads
# ~/.config/ccstatusline/settings.json, which setup.sh installs as the consumer
# layout — usage widgets and all. Printing a hint costs nothing; rendering
# another account's numbers costs a plan decision.
render_custom_endpoint() {
  if [ -f "$CUSTOM" ]; then
    run_ccstatusline --config "$CUSTOM"
    return
  fi
  printf 'custom endpoint · run ./setup.sh to install the status-line profile\n'
}

# Exit 0 only when the payload carries BOTH usage buckets with a real percentage.
# A missing python3, a malformed payload or a hollow bucket all exit non-zero and
# keep the quota off screen, which is the safe direction.
payload_has_buckets() {
  "$PYTHON" -I -c 'import sys, json
try:
    d = json.load(sys.stdin)
    rl = (d if isinstance(d, dict) else {}).get("rate_limits") or {}
except Exception:
    sys.exit(1)
fh = rl.get("five_hour") or {}
sd = rl.get("seven_day") or {}
sys.exit(0 if fh.get("used_percentage") is not None
         and sd.get("used_percentage") is not None else 1)' 2>/dev/null
}

if uses_cloud_provider; then
  # Nothing stdin could say changes this, so it is never read here.
  render_custom_endpoint </dev/null
  exit 0
fi

if ! base_url_is_first_party; then
  input=$(cat)
  if [ -f "$CONSUMER" ] && printf '%s' "$input" | payload_has_buckets; then
    printf '%s' "$input" | run_ccstatusline --config "$CONSUMER"
  else
    printf '%s' "$input" | render_custom_endpoint
  fi
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
  printf '%s' "$creds" | "$PYTHON" -I -c 'import sys, json
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
  "$PYTHON" -I -c 'import sys, json, glob, os, time, datetime
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
      printf '%s' "$routed" | run_ccstatusline --config "$CONSUMER"
    else
      # Same convention as the custom-endpoint branch: a hint beats silently
      # rendering the layout this branch just proved wrong.
      printf 'consumer profile missing · run ./setup.sh to reinstall the status-line profiles\n'
    fi
  elif [ "$rc" = "0" ] && [ -n "$routed" ]; then
    printf '%s' "$routed" | run_ccstatusline --config "$cfg"
  else
    # python3 unavailable or the route died: fall back to the raw payload rather
    # than showing nothing.
    printf '%s' "$input" | run_ccstatusline --config "$cfg"
  fi
elif [ -n "$cfg" ] && [ -f "$cfg" ]; then
  run_ccstatusline --config "$cfg"
else
  run_ccstatusline
fi
