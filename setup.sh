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

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --check)    CHECK_ONLY=true ;;
    --no-shell) ADD_SHELL_ALIASES=false ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
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
  check "Ghostty (cask)"            bash -c 'brew list --cask ghostty'
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
brew_cask ghostty "Ghostty"

step "Font — JetBrains Mono"
brew_cask font-jetbrains-mono "JetBrains Mono"

step "Node.js (runtime for Claude Code & many projects)"
brew_formula node "Node.js"

step "GitHub CLI (gh) — for PRs / the GitHub MCP"
brew_formula gh "gh"

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
# 7. Shell aliases (optional)
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
