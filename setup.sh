#!/usr/bin/env bash
#
# setup.sh — Bootstrap a Claude Code + Ghostty environment on a fresh Mac.
#
# Runs everything from zero, in order, idempotent (safe to re-run):
#   Xcode CLT -> Homebrew -> Ghostty -> Node -> Claude Code -> fonts -> configs.
#
# Usage:
#   ./setup.sh              # full install, interactive
#   ./setup.sh --dry-run    # show what it would do, change nothing
#   ./setup.sh --check      # only validate an existing environment (no install)
#   ./setup.sh --no-shell   # don't add aliases/PATH to the shell rc
#   ./setup.sh --no-ask     # skip the optional second-provider question
#   ./setup.sh --help
#
# After running: open Ghostty, type `claude`, log in. Done.
#
# -u: error on unset variables. pipefail: a failed pipe propagates its status.
# We intentionally do NOT use -e / an ERR trap: a step that fails (e.g. brew
# install with no network) must not kill the whole bootstrap. Critical errors
# use an explicit `die`, and validate() at the end reports what's still missing.
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Options & UI
# ─────────────────────────────────────────────────────────────────────────────
DRY_RUN=false
CHECK_ONLY=false
ADD_SHELL_ALIASES=true
ASK_ALT_PROVIDER=true

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --check)    CHECK_ONLY=true ;;
    --no-shell) ADD_SHELL_ALIASES=false ;;
    --no-ask)   ASK_ALT_PROVIDER=false ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $arg (see --help)"; exit 1 ;;
  esac
done

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  BLUE=$'\033[34m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; BLUE=""; RED=""; RESET=""
fi

step()  { printf "\n${BOLD}${BLUE}> %s${RESET}\n" "$*"; }
ok()    { printf "  ${GREEN}OK${RESET} %s\n" "$*"; }
skip()  { printf "  ${DIM}.. %s${RESET}\n" "$*"; }
warn()  { printf "  ${YELLOW}!! %s${RESET}\n" "$*"; }
die()   { printf "\n${RED}xx %s${RESET}\n" "$*" >&2; exit 1; }

run() {
  if $DRY_RUN; then
    printf "  ${DIM}[dry-run] %s${RESET}\n" "$*"
  else
    # Intentional "command as a string" helper (for dry-run). Returns the
    # command's status so the caller can decide (e.g. `run ... || warn`).
    # shellcheck disable=SC2294
    eval "$@"
  fi
}

# Write a file, backing up an existing one if it differs.
write_file() {
  local path="$1" content="$2"
  if [ -f "$path" ] && [ "$(cat "$path")" = "$content" ]; then
    skip "$path (already up to date)"; return
  fi
  if $DRY_RUN; then
    printf "  ${DIM}[dry-run] write %s${RESET}\n" "$path"; return
  fi
  mkdir -p "$(dirname "$path")"
  if [ -f "$path" ]; then
    cp "$path" "$path.bak.$(date +%s)"
    warn "backup made: $path.bak.*"
  fi
  printf '%s\n' "$content" > "$path"
  ok "wrote $path"
}

# Append a line to an rc file exactly once (idempotent, marker-checked).
ensure_line() {
  local file="$1" line="$2"
  [ -f "$file" ] || { $DRY_RUN || touch "$file"; }
  if [ -f "$file" ] && grep -qF -- "$line" "$file" 2>/dev/null; then
    return
  fi
  if $DRY_RUN; then
    printf "  ${DIM}[dry-run] append to %s: %s${RESET}\n" "$file" "$line"; return
  fi
  printf '%s\n' "$line" >> "$file"
}

ghostty_app_present()  { [ -d "/Applications/Ghostty.app" ]; }
ghostty_cask_present() { brew list --cask ghostty >/dev/null 2>&1; }
ghostty_present()      { ghostty_cask_present || ghostty_app_present; }

attempt_ghostty_install() {
  run "brew install --cask ghostty${1:+ $1}" || return 1
  $DRY_RUN && return 0
  ghostty_cask_present
}

install_ghostty() {
  if ! $DRY_RUN && ! command -v brew >/dev/null 2>&1; then
    warn "Ghostty skipped — Homebrew is unavailable"
    return 1
  fi
  if ghostty_cask_present; then
    ok "Ghostty already installed (brew)"
    return 0
  fi

  local adopt_existing_app=""
  if ghostty_app_present; then
    skip "Ghostty.app present — adopting it into Homebrew"
    adopt_existing_app="--adopt"
  fi

  if attempt_ghostty_install "$adopt_existing_app"; then
    ok "Ghostty installed"
    return 0
  fi

  warn "Ghostty install failed — refreshing Homebrew and retrying once"
  run "brew update --quiet" || true
  if attempt_ghostty_install "$adopt_existing_app"; then
    ok "Ghostty installed after retry"
    return 0
  fi

  if ghostty_app_present && attempt_ghostty_install "--force"; then
    ok "Ghostty installed by replacing the existing app"
    return 0
  fi

  warn "Ghostty could not be installed — install it from https://ghostty.org (Claude Code runs in any terminal)"
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Account detection (for the account-aware status line)
# ─────────────────────────────────────────────────────────────────────────────
# Read ONLY the subscriptionType field from the Claude Code credential (never the
# token). macOS: Keychain item "Claude Code-credentials"; else ~/.claude/.credentials.json.
# Empty string if not logged in / undetectable — callers then default to consumer.
detect_subscription() {
  local creds="" py
  py="$(command -v python3 || echo /usr/bin/python3)"
  [ -x "$py" ] || return 0
  if command -v security >/dev/null 2>&1; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
  fi
  [ -z "$creds" ] && [ -f "$HOME/.claude/.credentials.json" ] && creds=$(cat "$HOME/.claude/.credentials.json" 2>/dev/null || true)
  [ -z "$creds" ] && return 0
  printf '%s' "$creds" | "$py" -c 'import sys, json
try:
    d = json.load(sys.stdin) or {}
    print(((d.get("claudeAiOauth") or {}).get("subscriptionType")) or "")
except Exception:
    print("")' 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Validation (used at the end and for --check)
# ─────────────────────────────────────────────────────────────────────────────
validate() {
  step "Validating environment"
  # claude (native installer) lands in ~/.local/bin, which may not yet be on a
  # clean shell's PATH (e.g. running --check directly). Add it.
  export PATH="$HOME/.local/bin:$PATH"
  local fails=0
  check() { # check "label" cmd...
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$label"; else warn "$label — MISSING"; fails=$((fails+1)); fi
  }
  check "Homebrew (brew)"            command -v brew
  check "Node.js (node)"             command -v node
  check "Claude Code (claude)"       command -v claude
  check "Ghostty"                    ghostty_present
  check "Ghostty config exists"      test -f "$HOME/.config/ghostty/config"
  check "Claude config (~/.claude)"  test -d "$HOME/.claude"
  # Validate JSON if settings.json exists
  if [ -f "$HOME/.claude/settings.json" ]; then
    if command -v node >/dev/null 2>&1 && \
       node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
      ok "settings.json is valid JSON"
    else
      warn "settings.json — INVALID JSON"; fails=$((fails+1))
    fi
  fi
  # Account-aware status line: profiles present + valid, and which one is active.
  local sl="$HOME/.config/ccstatusline"
  if [ -f "$sl/profile-switch.sh" ]; then
    ok "status-line profile switcher installed"
    for p in settings.enterprise.json settings.consumer.json; do
      if [ ! -f "$sl/$p" ]; then
        warn "ccstatusline $p — MISSING (re-run ./setup.sh)"; fails=$((fails+1))
      elif command -v node >/dev/null 2>&1 && \
           node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$sl/$p" >/dev/null 2>&1; then
        ok "ccstatusline $p is valid JSON"
      else
        warn "ccstatusline $p — INVALID JSON"; fails=$((fails+1))
      fi
    done
    case "$(detect_subscription)" in
      enterprise|team) ok "Claude account: enterprise/team → enterprise profile, unless the payload carries real 5h/7d buckets (then the usage bars show)" ;;
      "")              skip "Claude account: not detected (log in to Claude Code) → consumer profile by default" ;;
      *)               ok "Claude account: consumer (Pro/Max) → consumer profile (5h/7d usage)" ;;
    esac
    # The custom-endpoint profile: ABSENT is informational (most people never use
    # a custom base URL, and failing --check would break their CI). But PRESENT
    # AND WRONG is a real failure — ccstatusline silently overwrites a config it
    # cannot parse with its own defaults, and setup.sh will never restore it.
    cep="$sl/settings.custom-endpoint.json"
    if [ ! -f "$cep" ]; then
      skip "custom-endpoint profile not installed — re-run ./setup.sh if you use a custom ANTHROPIC_BASE_URL"
    elif ! command -v node >/dev/null 2>&1 || \
         ! node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$cep" >/dev/null 2>&1; then
      warn "custom-endpoint profile — INVALID JSON (delete it and re-run ./setup.sh)"; fails=$((fails+1))
    elif grep -qE '"(session-usage|weekly-usage|weekly-sonnet-usage|weekly-opus-usage|reset-timer|weekly-reset-timer|extra-usage-remaining|extra-usage-utilization|block-timer|session-cost)"' "$cep"; then
      warn "custom-endpoint profile contains a usage widget — it would show your ANTHROPIC quota"
      warn "  on another provider's session. Delete it and re-run ./setup.sh."; fails=$((fails+1))
    else
      ok "custom-endpoint profile present and free of usage widgets"
    fi
    # The one setting that decides whether any of this runs at all.
    st="$HOME/.claude/settings.json"
    if [ -f "$st" ] && command -v node >/dev/null 2>&1; then
      case "$(node -e 'const fs=require("fs");let s;try{s=JSON.parse(fs.readFileSync(process.argv[1],"utf8"))}catch(e){process.stdout.write("unreadable");process.exit(0)}
const c=String((s.statusLine||{}).command||"");
process.stdout.write(!s.statusLine?"none":c.includes("profile-switch.sh")?"routed":/ccstatusline/.test(c)?"direct":"other")' "$st" 2>/dev/null)" in
        routed) ok "settings.json routes the status line through the launcher" ;;
        direct) warn "settings.json calls ccstatusline directly — a non-Anthropic session would show your Anthropic quota"
                warn "  point statusLine.command at profile-switch.sh (re-run ./setup.sh)"; fails=$((fails+1)) ;;
        none|other|unreadable) skip "settings.json has no ccstatusline status line — nothing to route" ;;
      esac
    fi
  fi
  echo
  if [ "$fails" -eq 0 ]; then
    printf "${BOLD}${GREEN}ENVIRONMENT OK — everything's in place.${RESET}\n"
    return 0
  else
    printf "${BOLD}${RED}%d problem(s). Re-run ./setup.sh to fix them.${RESET}\n" "$fails"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 0. Pre-checks
# ─────────────────────────────────────────────────────────────────────────────
printf "${BOLD}Claude Code + Ghostty — bootstrap${RESET}\n"

if $CHECK_ONLY; then
  # Propagate validate's result as the exit code (0 = valid, 1 = things missing),
  # useful in scripts/CI.
  if validate; then exit 0; else exit 1; fi
fi

$DRY_RUN && warn "DRY-RUN MODE: nothing is changed, only shown."

if [ "$(uname -s)" != "Darwin" ]; then
  warn "This script is tuned for macOS. On Linux, install Ghostty/Node from your package manager."
fi

# rc file where we persist PATH + aliases (zsh is default on modern macOS).
# We use .zshrc: it's sourced by ALL interactive shells (login and non-login:
# Ghostty, the VS Code terminal, tmux, nested zsh). That way `claude` and the
# aliases are always on PATH — not only in login shells (as .zprofile would be).
SHELL_RC="$HOME/.zshrc"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Xcode Command Line Tools (git, compilers) — with auto-wait
# ─────────────────────────────────────────────────────────────────────────────
step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "already installed"
elif $DRY_RUN; then
  skip "[dry-run] xcode-select --install + wait"
else
  warn "Apple's dialog will open — click Install (a few GB download)."
  xcode-select --install >/dev/null 2>&1 || true
  printf "  Waiting for the install to finish (max ~30 min)"
  waited=0
  until xcode-select -p >/dev/null 2>&1; do
    printf "."; sleep 5; waited=$((waited+5))
    if [ "$waited" -ge 1800 ]; then
      printf "\n"
      die "Xcode CLT didn't install within 30 min. If you closed the dialog, run 'xcode-select --install' manually, then re-run ./setup.sh"
    fi
  done
  printf "\n"; ok "installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. Homebrew (+ persist PATH in .zshrc)
# ─────────────────────────────────────────────────────────────────────────────
step "Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "already installed ($(brew --version | head -1))"
else
  run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
    || warn "Homebrew install failed — checking below whether it exists anyway"
fi
# Put brew on PATH for the current session + persist for future terminals.
BREW_BIN="$(command -v brew || true)"
[ -z "$BREW_BIN" ] && [ -x /opt/homebrew/bin/brew ] && BREW_BIN=/opt/homebrew/bin/brew
[ -z "$BREW_BIN" ] && [ -x /usr/local/bin/brew ]    && BREW_BIN=/usr/local/bin/brew
if [ -n "$BREW_BIN" ]; then
  eval "$("$BREW_BIN" shellenv)"
  if $ADD_SHELL_ALIASES; then
    ensure_line "$SHELL_RC" "eval \"\$($BREW_BIN shellenv)\""
  fi
elif ! $DRY_RUN; then
  die "Could not locate Homebrew after install."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Ghostty + font + Node + git tooling (via brew)
# ─────────────────────────────────────────────────────────────────────────────
# On install failure (e.g. network) we do NOT stop the whole script: we warn and
# continue. validate() at the end clearly reports what's missing, and since the
# script is idempotent you just re-run it to resume only what's left.
brew_cask() {
  local cask="$1" label="${2:-$1}"
  if brew list --cask "$cask" >/dev/null 2>&1; then ok "$label already installed"
  else run "brew install --cask $cask" || warn "$label could not be installed — re-run ./setup.sh after checking your network"; fi
}
brew_formula() {
  local f="$1" label="${2:-$1}"
  if brew list --formula "$f" >/dev/null 2>&1; then ok "$label already installed"
  else run "brew install $f" || warn "$label could not be installed — re-run ./setup.sh after checking your network"; fi
}

step "Ghostty (recommended terminal for Claude Code)"
install_ghostty

step "Font — JetBrains Mono"
brew_cask font-jetbrains-mono "JetBrains Mono"

step "Node.js (runtime for Claude Code & many projects)"
brew_formula node "Node.js"

step "GitHub CLI (gh) — for PRs / the GitHub MCP"
brew_formula gh "gh"

step "jq — used by hooks and the status line"
brew_formula jq "jq"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Claude Code (official native installer, npm fallback) + persist PATH
# ─────────────────────────────────────────────────────────────────────────────
step "Claude Code"
# the native installer usually drops the binary in ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
  ok "already installed ($(claude --version 2>/dev/null | head -1))"
elif $DRY_RUN; then
  skip "[dry-run] curl -fsSL https://claude.ai/install.sh | bash"
else
  if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "installed via native installer"
  else
    warn "Native installer failed — falling back to npm"
    npm install -g @anthropic-ai/claude-code
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi
# Persist ~/.local/bin on PATH for future terminals
if $ADD_SHELL_ALIASES; then
  ensure_line "$SHELL_RC" 'export PATH="$HOME/.local/bin:$PATH"'
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Ghostty config (~/.config/ghostty/config)
# ─────────────────────────────────────────────────────────────────────────────
step "Ghostty config"
read -r -d '' GHOSTTY_CONFIG <<'EOF' || true
# ~/.config/ghostty/config — generated by claude-code-guide/setup.sh
# Catppuccin auto dark/light. Reload in Ghostty: Cmd+Shift+,

theme = dark:Catppuccin Mocha,light:Catppuccin Latte
font-family = JetBrains Mono
font-size = 14
font-thicken = true
background-opacity = 0.96
background-blur = 20
window-padding-x = 14
window-padding-y = 14
window-padding-balance = true
macos-titlebar-style = tabs
cursor-style = block
mouse-hide-while-typing = true
copy-on-select = clipboard
EOF
write_file "$HOME/.config/ghostty/config" "$GHOSTTY_CONFIG"

# ─────────────────────────────────────────────────────────────────────────────
# 6. Claude Code config (~/.claude/settings.json) — only if absent
# ─────────────────────────────────────────────────────────────────────────────
step "Global Claude Code config (~/.claude/settings.json)"
read -r -d '' CLAUDE_SETTINGS <<'EOF' || true
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "includeCoAuthoredBy": true,
  "statusLine": { "type": "command", "command": "sh $HOME/.config/ccstatusline/profile-switch.sh", "padding": 0 },
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(ls:*)",
      "Bash(cat:*)"
    ]
  }
}
EOF
if [ -f "$HOME/.claude/settings.json" ]; then
  # shellcheck disable=SC2088  # tilde is displayed text, not a path to expand
  skip "~/.claude/settings.json already exists — not overwriting"
else
  write_file "$HOME/.claude/settings.json" "$CLAUDE_SETTINGS"
fi

step "Global CLAUDE.md (~/.claude/CLAUDE.md)"
read -r -d '' GLOBAL_CLAUDE_MD <<'EOF' || true
# Global preferences

- Answer concisely. Write code that reads like the rest of the codebase.
- Before a complex task: Plan mode. Verify with tests/lint when they exist.
- Don't add redundant comments.
EOF
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  # shellcheck disable=SC2088  # tilde is displayed text, not a path to expand
  skip "~/.claude/CLAUDE.md already exists — leaving it alone"
else
  write_file "$HOME/.claude/CLAUDE.md" "$GLOBAL_CLAUDE_MD"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. Status line — model, context, 5h/weekly limits, branch, session, disk
# ─────────────────────────────────────────────────────────────────────────────
step "Status line (cost / rate-limits / branch)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SL_ASSETS="$SCRIPT_DIR/assets/statusline"
if [ -d "$SL_ASSETS" ]; then
  # ccstatusline (the rich multi-line display the settings.json points to)
  if command -v ccstatusline >/dev/null 2>&1; then
    ok "ccstatusline already installed"
  else
    # @2 pins the major version so the shipped config (schema v3) keeps working
    run "npm install -g ccstatusline@2" \
      || warn "ccstatusline not installed (needs npm) — the status line stays blank until it is"
  fi
  # ccstatusline config + account-aware profiles. We ship TWO profiles plus a tiny
  # launcher (profile-switch.sh) that auto-selects by account type: consumer
  # (Pro/Max) keeps the 5h/7d usage bars; enterprise/team swap to a 5h-timer +
  # monthly-credit profile, because on most such seats the five_hour/seven_day
  # buckets come back null and the usage widgets would otherwise show "[Timeout]".
  # Seats that DO send real buckets in the payload are routed back to the consumer
  # bars per render — the payload has the final word (see profile-switch.sh).
  CCSL_DIR="$HOME/.config/ccstatusline"
  if $DRY_RUN; then
    skip "[dry-run] install ccstatusline profiles + profile-switch.sh into $CCSL_DIR"
  else
    mkdir -p "$CCSL_DIR"
    # default config (consumer layout) and the named consumer profile, only if absent
    if [ -f "$CCSL_DIR/settings.json" ]; then
      skip "ccstatusline settings.json exists — not overwriting"
    else
      cp "$SL_ASSETS/ccstatusline-settings.json" "$CCSL_DIR/settings.json"
      ok "wrote $CCSL_DIR/settings.json"
    fi
    if [ -f "$CCSL_DIR/settings.consumer.json" ]; then
      skip "settings.consumer.json exists — not overwriting"
    else
      cp "$SL_ASSETS/ccstatusline-settings.json" "$CCSL_DIR/settings.consumer.json"
      ok "wrote $CCSL_DIR/settings.consumer.json"
    fi
    if [ -f "$CCSL_DIR/settings.enterprise.json" ]; then
      skip "settings.enterprise.json exists — not overwriting"
    else
      cp "$SL_ASSETS/ccstatusline-settings.enterprise.json" "$CCSL_DIR/settings.enterprise.json"
      ok "wrote $CCSL_DIR/settings.enterprise.json"
    fi
    # Sessions on a custom ANTHROPIC_BASE_URL get a profile with no usage
    # widgets at all: without rate_limits in the payload those widgets fall back
    # to Anthropic's usage API and would render your Anthropic quota next to
    # another provider's model. See profile-switch.sh for the full reasoning.
    if [ -f "$CCSL_DIR/settings.custom-endpoint.json" ]; then
      skip "settings.custom-endpoint.json exists — not overwriting"
    else
      cp "$SL_ASSETS/ccstatusline-settings.custom-endpoint.json" "$CCSL_DIR/settings.custom-endpoint.json"
      ok "wrote $CCSL_DIR/settings.custom-endpoint.json"
    fi
    # The launcher is always refreshed so bug fixes propagate on re-run — but
    # back up a divergent copy first, so local edits are never lost silently.
    if [ -f "$CCSL_DIR/profile-switch.sh" ] && \
       ! cmp -s "$SL_ASSETS/profile-switch.sh" "$CCSL_DIR/profile-switch.sh"; then
      cp "$CCSL_DIR/profile-switch.sh" "$CCSL_DIR/profile-switch.sh.bak"
      warn "backup made: $CCSL_DIR/profile-switch.sh.bak"
    fi
    cp "$SL_ASSETS/profile-switch.sh" "$CCSL_DIR/profile-switch.sh"
    chmod +x "$CCSL_DIR/profile-switch.sh"
    ok "installed $CCSL_DIR/profile-switch.sh (auto-selects profile by account)"
    case "$(detect_subscription)" in
      enterprise|team) ok "detected enterprise/team account → enterprise profile, consumer bars if the payload sends real buckets" ;;
      "")              skip "account not detected yet (log in to Claude Code) → consumer profile by default" ;;
      *)               ok "detected consumer (Pro/Max) account → consumer profile active" ;;
    esac
  fi
  # also drop the no-Node alternative (handy if you'd rather not use ccstatusline)
  if [ -f "$HOME/.claude/statusline.sh" ]; then
    # shellcheck disable=SC2088  # tilde is displayed text, not a path to expand
    skip "~/.claude/statusline.sh exists — not overwriting"
  elif $DRY_RUN; then
    skip "[dry-run] write ~/.claude/statusline.sh"
  else
    cp "$SL_ASSETS/statusline.sh" "$HOME/.claude/statusline.sh"
    chmod +x "$HOME/.claude/statusline.sh"
    ok "wrote ~/.claude/statusline.sh (alternative)"
  fi
  # Wire the status line into an EXISTING settings.json too — so re-running this
  # script updates users who set up before the status line existed, AND upgrades
  # older installs that call ccstatusline directly to the account-aware launcher.
  #
  # Classify on substance, not string equality. A direct call is a direct call
  # whether it was written as `ccstatusline`, `/opt/homebrew/bin/ccstatusline`,
  # `npx -y ccstatusline@latest` or `bunx ccstatusline` — and every one of those
  # renders your Anthropic quota on a session pointed at another provider. Only a
  # direct call with NO extra arguments is rewritten; one carrying its own
  # --config is a deliberate choice, so it is kept and flagged instead.
  SETTINGS="$HOME/.claude/settings.json"
  STATUSLINE_CMD='sh $HOME/.config/ccstatusline/profile-switch.sh'
  if [ -f "$SETTINGS" ] && command -v node >/dev/null 2>&1; then
    action=$(node -e 'const f=process.argv[1],cmd=process.argv[2],fs=require("fs");
let s;try{s=JSON.parse(fs.readFileSync(f,"utf8"))}catch(e){process.stdout.write("error");process.exit(0)}
if(!s.statusLine){process.stdout.write("add");process.exit(0)}
const cur=String(s.statusLine.command||"").trim();
if(cur===cmd){process.stdout.write("current");process.exit(0)}
if(cur.includes("profile-switch.sh")){process.stdout.write("current");process.exit(0)}
const bare=cur.replace(/^(npx\s+(-y\s+)?|bunx\s+|bun\s+x\s+)/,"").trim();
if(/^(\S*\/)?ccstatusline(@[\w.\-]+)?$/.test(bare)){process.stdout.write("upgrade");process.exit(0)}
process.stdout.write(/ccstatusline/.test(cur)?"keep-direct":"keep")' "$SETTINGS" "$STATUSLINE_CMD" 2>/dev/null)
    case "$action" in
      current) skip "settings.json status line already account-aware" ;;
      keep)    skip "settings.json has a custom statusLine — leaving it alone" ;;
      keep-direct)
        warn "settings.json calls ccstatusline directly with its own arguments — leaving it alone"
        warn "  on a non-Anthropic endpoint that renders YOUR Anthropic quota; point it at profile-switch.sh" ;;
      add|upgrade)
        if $DRY_RUN; then
          skip "[dry-run] $action account-aware statusLine in settings.json"
        else
          cp "$SETTINGS" "$SETTINGS.bak.$(date +%s)"
          if node -e 'const f=process.argv[1],cmd=process.argv[2],fs=require("fs");const s=JSON.parse(fs.readFileSync(f,"utf8"));s.statusLine={type:"command",command:cmd,padding:0};fs.writeFileSync(f,JSON.stringify(s,null,2)+"\n")' "$SETTINGS" "$STATUSLINE_CMD"; then
            ok "wired account-aware statusLine into settings.json ($action, backup made)"
          else
            warn "couldn't update settings.json — add a statusLine key manually"
          fi
        fi ;;
      *) warn "couldn't read settings.json to check statusLine" ;;
    esac
  fi
else
  skip "status-line assets not found (run setup.sh from the repo) — skipping"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 8. Shell aliases (optional)
# ─────────────────────────────────────────────────────────────────────────────
if $ADD_SHELL_ALIASES; then
  step "zsh aliases (~/.zshrc)"
  MARKER="# >>> claude-code-guide aliases >>>"
  if [ -f "$SHELL_RC" ] && grep -qF "$MARKER" "$SHELL_RC"; then
    skip "aliases already present"
  elif $DRY_RUN; then
    skip "[dry-run] would add aliases to $SHELL_RC"
  else
    cat >> "$SHELL_RC" <<'EOF'

# >>> claude-code-guide aliases >>>
alias cc='claude'
alias ccc='claude --continue'        # resume the last session
alias ccp='claude --permission-mode plan'
# <<< claude-code-guide aliases <<<
EOF
    ok "aliases added (cc, ccc, ccp) — active in your next terminal"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# 9. Optional: a second provider alongside Claude (interactive, opt-in)
# ─────────────────────────────────────────────────────────────────────────────
# Claude Code can be pointed at any endpoint that speaks the Anthropic protocol.
# This writes a SECOND config directory so your Claude setup is never touched,
# and adds an alias to launch it. See docs/guides/non-anthropic-endpoints.md.
#
# WHY THIS IS INTERACTIVE AND READS /dev/tty
#   This script is distributed by `curl … | bash`, where stdin is the script
#   itself — a plain `read` would eat the remaining bytes. Reading /dev/tty gets
#   the real terminal in that case, and simply fails where there is no terminal
#   (CI, the test suite, a provisioning script), which is exactly when a prompt
#   for a credential must not appear. Nothing here runs unattended: no terminal
#   means skipped, --dry-run means skipped, and the default answer is no.
#
#   Writing an inference endpoint and a key into someone's config without them
#   asking would make a single bad commit here a way to redirect other people's
#   traffic. So this never happens without a typed yes.
setup_alt_provider() {
  local dir="$HOME/.claude-alt" settings base key model ctx alias_name reply old_umask

  if ! $ASK_ALT_PROVIDER; then
    skip "--no-ask given — not offering the second-provider setup"
    return 0
  fi
  if $DRY_RUN; then
    skip "[dry-run] would offer to configure a second provider"
    return 0
  fi
  # `[ -r /dev/tty ]` looks like an interactivity test and is not one: /dev/tty is
  # crw-rw-rw-, so the permission bit is always set even where the device cannot
  # be opened. Open it for real instead, and require BOTH that the open succeeds
  # and that stdout is a terminal. That covers the `curl … | bash` case, where
  # only stdin is the pipe, and stays out of the way when output is redirected.
  #
  # It does NOT defeat automation that deliberately allocates a pty (`script(1)`),
  # and nothing based on file descriptors can. `--no-ask` is the guarantee for
  # unattended runs; the docs say so rather than claiming more than this enforces.
  if [ ! -t 1 ] || ! : < /dev/tty 2>/dev/null; then
    skip "not an interactive terminal — skipping the optional second-provider setup"
    return 0
  fi

  # Refuse to follow a symlink anywhere on this path. `[ -f ]` is false for a
  # dangling symlink, so without this a planted link would skip the
  # already-configured guard and write the key to the link's target instead.
  settings="$dir/settings.json"
  if [ -L "$dir" ] || [ -L "$settings" ]; then
    warn "$dir or its settings.json is a symlink — refusing to write a credential through it"
    return 0
  fi
  if [ -e "$settings" ]; then
    skip "second provider already configured ($settings) — not touching it"
    return 0
  fi

  printf "\n  Claude Code can also run against a non-Anthropic endpoint, in a separate\n"
  printf "  config directory, so your Claude setup stays exactly as it is.\n"
  printf "  You will need an API key from that provider. Docs: docs/guides/non-anthropic-endpoints.md\n"
  # Drain anything already sitting in the terminal buffer, so a stray keystroke
  # from the long Homebrew phase cannot be consumed as the answer to this.
  while read -r -t 0.01 -n 1 _ < /dev/tty 2>/dev/null; do :; done
  # Full word, not a bare y: this writes a credential, so it should not be one
  # keystroke away. -t 60 is a backstop; a timeout reads as no.
  printf "  Set one up now? Type 'yes' to continue: "
  read -r -t 60 reply < /dev/tty || { printf "\n"; skip "no answer — skipped"; return 0; }
  case "$reply" in
    [yY][eE][sS]) ;;
    *) skip "skipped — run ./setup.sh again any time to set it up"; return 0 ;;
  esac

  printf "  Base URL [https://api.kimi.com/coding/]: "
  read -r -t 120 base < /dev/tty || { printf "\n"; warn "timed out — nothing written"; return 0; }
  base="${base:-https://api.kimi.com/coding/}"
  # Every field below is interpolated into a file Claude Code executes behaviour
  # from, so each is validated against a strict allowlist. A base URL carrying a
  # quote could close the env object and append a top-level hooks block — a shell
  # command run at every session start, in a file that still parses as JSON and
  # still holds the right key, so nothing would look wrong.
  case "$base" in
    https://*) ;;
    *) warn "base URL must start with https:// — aborting, nothing written"; return 0 ;;
  esac
  case "$base" in
    *[!A-Za-z0-9:/._~%?\#\[\]@!\$\&\'\(\)\*+,\;=-]*)
      warn "base URL contains characters that are not valid in a URL — aborting"; return 0 ;;
  esac

  # No echo: a key must never land in the scrollback or a screenshot. If stty
  # cannot turn echo off we say so rather than letting the key be typed in the
  # clear. The trap covers every way out of the prompt, including a closed
  # terminal (HUP), so echo is never left off.
  printf "  API key (input hidden): "
  if ! stty -echo < /dev/tty 2>/dev/null; then
    printf "\n"; warn "cannot hide input on this terminal — not asking for a key here"
    warn "  use the manual path instead: docs/guides/non-anthropic-endpoints.md"
    return 0
  fi
  trap 'stty echo < /dev/tty 2>/dev/null; printf "\n"; exit 130' INT TERM HUP
  read -r -t 120 key < /dev/tty || key=""
  stty echo < /dev/tty 2>/dev/null
  trap - INT TERM HUP
  printf "\n"
  key="${key%$'\r'}"
  case "$key" in
    "") warn "no key given — aborting, nothing written"; return 0 ;;
    *[![:print:]]*) warn "key contains a control character — aborting rather than writing a broken file"; return 0 ;;
  esac

  printf "  Model ID [k3-256k]: "
  read -r -t 120 model < /dev/tty || { printf "\n"; warn "timed out — nothing written"; return 0; }
  model="${model:-k3-256k}"
  case "$model" in
    ''|*[!A-Za-z0-9._\[\]-]*)
      warn "model ID may only contain letters, digits, dot, underscore, dash or square brackets — aborting"; return 0 ;;
  esac

  printf "  Context window in tokens [262144]: "
  read -r -t 120 ctx < /dev/tty || { printf "\n"; warn "timed out — nothing written"; return 0; }
  ctx="${ctx:-262144}"
  case "$ctx" in
    ''|*[!0-9]*) warn "context window must be a whole number — aborting, nothing written"; return 0 ;;
  esac

  printf "  Alias to launch it [alt]: "
  read -r -t 120 alias_name < /dev/tty || { printf "\n"; warn "timed out — nothing written"; return 0; }
  alias_name="${alias_name:-alt}"
  # Must start with a letter or underscore: a leading dash parses as an option to
  # `alias` and would print an error in every future interactive shell.
  case "$alias_name" in
    ''|[!a-zA-Z_]*|*[!a-zA-Z0-9_-]*)
      warn "alias must start with a letter and contain only letters, digits, dash or underscore — aborting"; return 0 ;;
  esac

  # umask in THIS shell, not a subshell: a subshell umask does not apply to the
  # file created after it, so the settings file would exist world-readable for
  # the moment between creation and chmod — long enough for a local process to
  # hold an fd open and read the key once it is written into the same inode.
  old_umask=$(umask); umask 077
  mkdir -p "$dir" || { umask "$old_umask"; warn "could not create $dir"; return 0; }
  chmod 700 "$dir" 2>/dev/null

  # Build the JSON with an encoder rather than a heredoc, so no input can alter
  # the file's structure even if the validation above ever misses a case.
  if ! command -v node >/dev/null 2>&1; then
    umask "$old_umask"
    warn "node is required to write this config safely — skipping"
    warn "  set it up by hand instead: docs/guides/non-anthropic-endpoints.md"
    return 0
  fi
  local statusline_arg="no"
  [ -f "$HOME/.config/ccstatusline/profile-switch.sh" ] && statusline_arg="yes"
  if ! ALT_KEY="$key" node -e '
const [out, base, model, ctx, wantStatusLine] = process.argv.slice(1);
const s = {
  env: {
    ANTHROPIC_BASE_URL: base,
    ANTHROPIC_API_KEY: process.env.ALT_KEY,
    ANTHROPIC_MODEL: model,
    ANTHROPIC_DEFAULT_OPUS_MODEL: model,
    ANTHROPIC_DEFAULT_SONNET_MODEL: model,
    ANTHROPIC_DEFAULT_HAIKU_MODEL: model,
    ANTHROPIC_DEFAULT_FABLE_MODEL: model,
    CLAUDE_CODE_SUBAGENT_MODEL: model,
    CLAUDE_CODE_EFFORT_LEVEL: "high",
    CLAUDE_CODE_MAX_CONTEXT_TOKENS: ctx,
    CLAUDE_CODE_AUTO_COMPACT_WINDOW: ctx,
  },
  permissions: { deny: ["WebSearch"] },
};
if (wantStatusLine === "yes") {
  s.statusLine = { type: "command", command: "sh $HOME/.config/ccstatusline/profile-switch.sh", padding: 0 };
}
require("fs").writeFileSync(out, JSON.stringify(s, null, 2) + "\n", { mode: 0o600, flag: "wx" });
' "$settings" "$base" "$model" "$ctx" "$statusline_arg" 2>/dev/null; then
    umask "$old_umask"
    rm -f "$settings"
    warn "could not write $settings — nothing left behind"
    return 0
  fi
  umask "$old_umask"
  chmod 600 "$settings" 2>/dev/null
  ok "wrote $settings (mode 600)"
  printf "     it also sets all six model aliases to %s, denies WebSearch (it cannot\n" "$model"
  printf "     work off Anthropic's backend), and sets effort to high — which answers\n"
  printf "     better and spends more of your provider quota. Edit the file to change them.\n"

  if $ADD_SHELL_ALIASES; then
    ensure_line "$SHELL_RC" "alias $alias_name='CLAUDE_CONFIG_DIR=\$HOME/.claude-alt claude'"
    ok "alias '$alias_name' added to $SHELL_RC — active in your next terminal"
  else
    ok "add this to your shell rc: alias $alias_name='CLAUDE_CONFIG_DIR=\$HOME/.claude-alt claude'"
  fi
  warn "that model ID and context size must match your provider's plan — see docs/guides/non-anthropic-endpoints.md"
}

step "Second provider (optional)"
setup_alt_provider

# ─────────────────────────────────────────────────────────────────────────────
# Validation + final
# ─────────────────────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  validate || warn "See the messages above."
fi

printf "\n${BOLD}${GREEN}Done.${RESET} Next steps:\n"
cat <<EOF
  1. Open ${BOLD}Ghostty${RESET} (Cmd+Space -> Ghostty). Open a NEW window.
  2. Type ${BOLD}claude${RESET} and authenticate (log in via the browser).
  3. Enter a project and run ${BOLD}/init${RESET} (or the /project-onboard skill).
  4. Anytime: ${BOLD}./setup.sh --check${RESET} validates the environment; ${BOLD}claude doctor${RESET} checks Claude.

  ${DIM}Full guide: https://github.com/bogdanmatasaru/claude-code-guide${RESET}
EOF
$DRY_RUN && warn "That was a dry-run — nothing actually changed."
exit 0
