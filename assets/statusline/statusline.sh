#!/usr/bin/env bash
# Self-contained Claude Code status line — model, context %, your Max-plan limits
# (5-hour window + weekly) with time-to-reset, and the git branch.
#
# Needs: bash + jq + git. Lighter than ccstatusline (no Node). The rate-limit
# fields depend on your Claude Code version exposing them in the status payload;
# if it doesn't, those segments are simply omitted.
#
# Enable: copy to ~/.claude/statusline.sh, then set in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }

input=$(cat)
field() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

model=$(field '.model.display_name // "?"')
ctx=$(field '.context_window.used_percentage // 0' | cut -d. -f1)
h5_pct=$(field '.rate_limits.five_hour.used_percentage // empty')
h5_reset=$(field '.rate_limits.five_hour.resets_at // empty')
w_pct=$(field '.rate_limits.seven_day.used_percentage // empty')
w_reset=$(field '.rate_limits.seven_day.resets_at // empty')
cwd=$(field '.workspace.current_dir // .cwd // empty')

now=$(date +%s)

fmt_left() {  # seconds -> "2h 13m" / "3d 4h"
  local secs=$1
  [ -z "$secs" ] && { printf '?'; return; }
  (( secs < 0 )) && secs=0
  local d=$(( secs / 86400 )) h=$(( (secs % 86400) / 3600 )) m=$(( (secs % 3600) / 60 ))
  if   (( d > 0 )); then printf '%dd %dh' "$d" "$h"
  elif (( h > 0 )); then printf '%dh %dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

bar() {  # 0-100% -> a 10-segment bar
  local pct=${1%.*}; [ -z "$pct" ] && pct=0
  local filled=$(( pct / 10 )); (( filled > 10 )) && filled=10
  local i out=""
  for ((i=0;i<10;i++)); do (( i < filled )) && out+="█" || out+="░"; done
  printf '%s' "$out"
}

seg="🤖 $model  🧠 ${ctx}% ctx"

branch=$(git -C "${cwd:-.}" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -n "$branch" ] && seg+="  🌿 $branch"

if [ -n "$h5_pct" ]; then
  p=${h5_pct%.*}; seg+="  ⏱️ 5h $(bar "$p") ${p}% (reset $(fmt_left $(( h5_reset - now ))))"
fi
if [ -n "$w_pct" ]; then
  p=${w_pct%.*}; seg+="  📅 7d $(bar "$p") ${p}% (reset $(fmt_left $(( w_reset - now ))))"
fi

printf '%s' "$seg"
