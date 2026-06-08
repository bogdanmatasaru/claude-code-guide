#!/bin/sh
# profile-switch.sh — account-aware ccstatusline launcher.
#
# Picks the right ccstatusline profile by your Claude account's subscriptionType,
# then runs ccstatusline with it. Wire it into ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "sh $HOME/.config/ccstatusline/profile-switch.sh", "padding": 0 }
#
# WHY this exists
#   ccstatusline's session-usage / weekly-usage / weekly-reset-timer widgets read
#   the five_hour / seven_day rate-limit buckets from api.anthropic.com/api/oauth/usage.
#   Enterprise/Team seats return those buckets as null, so those widgets render
#   "[Timeout]" (a pessimistic-lock label, not a real network timeout — the API
#   answers 200 in <0.5s). Enterprise exposes a monthly pay-as-you-go bucket
#   (extra_usage) instead. So we ship two profiles and auto-select.
#
#   - settings.enterprise.json : 5h block reset timer + extra-usage-remaining
#   - settings.consumer.json   : the classic 5h/7d usage % + reset widgets
#   - settings.json            : ccstatusline default, the fallback
#
# ENTERPRISE SHIM (verified)
#   ccstatusline fetches usage ONCE per render and shares it across all Usage
#   widgets, UNIONing their required fields. reset-timer requires sessionResetAt;
#   Claude Code's statusline payload carries NO rate_limits, so on enterprise that
#   field is unsatisfiable and the shared object flips to {error}, which would make
#   extra-usage-remaining show "[Timeout]" too. We inject a synthetic
#   rate_limits.five_hour.resets_at (the 5h block reset, read from ccstatusline's
#   own block-cache) so sessionResetAt is satisfied LOCALLY, never enters the API
#   fetch, and the timer + monthly credit both render stably.
#
# Detection is cached for $TTL seconds. No credential value is ever printed; only
# the subscriptionType field is read from the Keychain item.
set -u

CONFIG_DIR="$HOME/.config/ccstatusline"
ENTERPRISE="$CONFIG_DIR/settings.enterprise.json"
CONSUMER="$CONFIG_DIR/settings.consumer.json"
CACHE="$CONFIG_DIR/.active-profile"
TTL=300

CCSTATUSLINE="$(command -v ccstatusline 2>/dev/null || echo /opt/homebrew/bin/ccstatusline)"
PYTHON="$(command -v python3 2>/dev/null || echo /usr/bin/python3)"

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

# Enterprise only: inject rate_limits.five_hour.resets_at (5h block reset, from
# ccstatusline's block-cache) when the payload lacks rate_limits, so reset-timer's
# required field is met locally and never poisons the shared usage fetch.
enterprise_shim() {
  "$PYTHON" -c 'import sys, json, glob, os, time, datetime
try:
    d = json.load(sys.stdin)
except Exception:
    sys.stdout.write("{}"); sys.exit(0)
if not d.get("rate_limits"):
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
    d["rate_limits"] = {"five_hour": {"resets_at": r, "used_percentage": 0}}
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
  [ -n "$cfg" ] && printf '%s' "$cfg" > "$CACHE" 2>/dev/null
fi

if [ "$cfg" = "$ENTERPRISE" ] && [ -f "$cfg" ]; then
  enterprise_shim | "$CCSTATUSLINE" --config "$cfg"
elif [ -n "$cfg" ] && [ -f "$cfg" ]; then
  exec "$CCSTATUSLINE" --config "$cfg"
else
  exec "$CCSTATUSLINE"
fi
