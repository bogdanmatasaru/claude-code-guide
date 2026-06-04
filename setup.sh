#!/usr/bin/env bash
#
# setup.sh — Bootstrap mediu Claude Code + Ghostty pe un Mac nou.
#
# Rulează totul de la zero, în ordine, idempotent (poți re-rula fără frică):
#   Xcode CLT -> Homebrew -> Ghostty -> Node -> Claude Code -> fonturi -> config-uri.
#
# Utilizare:
#   ./setup.sh              # instalare completa, interactiv
#   ./setup.sh --dry-run    # arata ce ar face, fara sa schimbe nimic
#   ./setup.sh --check      # doar valideaza un mediu deja instalat (nu instaleaza)
#   ./setup.sh --no-shell   # nu adauga alias-uri/PATH in shell rc
#   ./setup.sh --help
#
# Dupa rulare: deschizi Ghostty, scrii `claude`, te loghezi. Gata.
#
# -u: eroare la variabile nesetate. pipefail: un pipe esuat propaga statusul.
# NU folosim -e/trap ERR intentionat: un pas care esueaza (ex. brew install fara
# retea) nu trebuie sa omoare tot bootstrap-ul. Erorile critice au `die` explicit,
# iar validate() de la final raporteaza clar ce a ramas neinstalat.
set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Optiuni & UI
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
    *) echo "Optiune necunoscuta: $arg (vezi --help)"; exit 1 ;;
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
    # Helper intentionat de tip "comanda ca string" (pentru dry-run). Intoarce
    # statusul comenzii ca apelantul sa decida (ex. `run ... || warn`).
    # shellcheck disable=SC2294
    eval "$@"
  fi
}

# Scrie un fisier, backup la cel existent daca difera.
write_file() {
  local path="$1" content="$2"
  if [ -f "$path" ] && [ "$(cat "$path")" = "$content" ]; then
    skip "$path (deja la zi)"; return
  fi
  if $DRY_RUN; then
    printf "  ${DIM}[dry-run] scriu %s${RESET}\n" "$path"; return
  fi
  mkdir -p "$(dirname "$path")"
  if [ -f "$path" ]; then
    cp "$path" "$path.bak.$(date +%s)"
    warn "backup facut: $path.bak.*"
  fi
  printf '%s\n' "$content" > "$path"
  ok "scris $path"
}

# Adauga o linie intr-un rc file o singura data (idempotent, marcata).
ensure_line() {
  local file="$1" line="$2"
  [ -f "$file" ] || { $DRY_RUN || touch "$file"; }
  if [ -f "$file" ] && grep -qF -- "$line" "$file" 2>/dev/null; then
    return
  fi
  if $DRY_RUN; then
    printf "  ${DIM}[dry-run] adaug in %s: %s${RESET}\n" "$file" "$line"; return
  fi
  printf '%s\n' "$line" >> "$file"
}

# ─────────────────────────────────────────────────────────────────────────────
# Validare (folosita la final si pentru --check)
# ─────────────────────────────────────────────────────────────────────────────
validate() {
  step "Validare mediu"
  # claude (installer nativ) ajunge in ~/.local/bin, care poate sa nu fie inca
  # in PATH-ul unui shell curat (ex. rulare directa cu --check). Il adaugam.
  export PATH="$HOME/.local/bin:$PATH"
  local fails=0
  check() { # check "label" cmd...
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$label"; else warn "$label — LIPSESTE"; fails=$((fails+1)); fi
  }
  check "Homebrew (brew)"            command -v brew
  check "Node.js (node)"             command -v node
  check "Claude Code (claude)"       command -v claude
  check "Ghostty (cask)"            bash -c 'brew list --cask ghostty'
  check "Config Ghostty exista"      test -f "$HOME/.config/ghostty/config"
  check "Config Claude (~/.claude)"  test -d "$HOME/.claude"
  # JSON valid daca settings.json exista
  if [ -f "$HOME/.claude/settings.json" ]; then
    if command -v node >/dev/null 2>&1 && \
       node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$HOME/.claude/settings.json" >/dev/null 2>&1; then
      ok "settings.json e JSON valid"
    else
      warn "settings.json — JSON INVALID"; fails=$((fails+1))
    fi
  fi
  echo
  if [ "$fails" -eq 0 ]; then
    printf "${BOLD}${GREEN}MEDIU VALID — totul e la locul lui.${RESET}\n"
    return 0
  else
    printf "${BOLD}${RED}%d probleme. Re-ruleaza ./setup.sh ca sa le repari.${RESET}\n" "$fails"
    return 1
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# 0. Pre-checks
# ─────────────────────────────────────────────────────────────────────────────
printf "${BOLD}Claude Code + Ghostty — bootstrap${RESET}\n"

if $CHECK_ONLY; then
  # Propagam codul lui validate ca exit code (0 = valid, 1 = lipsesc lucruri),
  # util in scripturi/CI.
  if validate; then exit 0; else exit 1; fi
fi

$DRY_RUN && warn "MOD DRY-RUN: nu se schimba nimic, doar se afiseaza."

if [ "$(uname -s)" != "Darwin" ]; then
  warn "Scriptul e calibrat pentru macOS. Pe Linux instaleaza Ghostty/Node din package manager."
fi

# rc file unde persistam PATH + alias-uri (zsh e default pe macOS modern).
# Folosim .zshrc: e sourceat de TOATE shell-urile interactive (login si non-login:
# Ghostty, terminal VS Code, tmux, zsh imbricat). Asa, `claude` si alias-urile sunt
# mereu pe PATH — nu doar in shell-uri de login (cum ar fi cazul cu .zprofile).
SHELL_RC="$HOME/.zshrc"

# ─────────────────────────────────────────────────────────────────────────────
# 1. Xcode Command Line Tools (git, compilatoare) — cu auto-wait
# ─────────────────────────────────────────────────────────────────────────────
step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "deja instalate"
elif $DRY_RUN; then
  skip "[dry-run] xcode-select --install + asteptare"
else
  warn "Se deschide dialogul Apple — apasa Install (descarcare cativa GB)."
  xcode-select --install >/dev/null 2>&1 || true
  printf "  Astept sa termini instalarea (max ~30 min)"
  waited=0
  until xcode-select -p >/dev/null 2>&1; do
    printf "."; sleep 5; waited=$((waited+5))
    if [ "$waited" -ge 1800 ]; then
      printf "\n"
      die "Xcode CLT nu s-au instalat in 30 min. Daca ai inchis dialogul, ruleaza 'xcode-select --install' manual, apoi reia ./setup.sh"
    fi
  done
  printf "\n"; ok "instalate"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 2. Homebrew (+ persista PATH in .zshrc)
# ─────────────────────────────────────────────────────────────────────────────
step "Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "deja instalat ($(brew --version | head -1))"
else
  run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
    || warn "Instalarea Homebrew a esuat — verific mai jos daca exista totusi"
fi
# Pune brew in PATH pentru sesiunea curenta + persista pentru terminale viitoare.
BREW_BIN="$(command -v brew || true)"
[ -z "$BREW_BIN" ] && [ -x /opt/homebrew/bin/brew ] && BREW_BIN=/opt/homebrew/bin/brew
[ -z "$BREW_BIN" ] && [ -x /usr/local/bin/brew ]    && BREW_BIN=/usr/local/bin/brew
if [ -n "$BREW_BIN" ]; then
  eval "$("$BREW_BIN" shellenv)"
  if $ADD_SHELL_ALIASES; then
    ensure_line "$SHELL_RC" "eval \"\$($BREW_BIN shellenv)\""
  fi
elif ! $DRY_RUN; then
  die "Homebrew nu s-a putut localiza dupa instalare."
fi

# ─────────────────────────────────────────────────────────────────────────────
# 3. Ghostty + font + Node + git tooling (via brew)
# ─────────────────────────────────────────────────────────────────────────────
# La esec de instalare (ex. retea) NU oprim tot scriptul: avertizam si continuam.
# validate() de la final raporteaza clar ce a ramas neinstalat, iar scriptul fiind
# idempotent il re-rulezi ca sa reia doar ce lipseste.
brew_cask() {
  local cask="$1" label="${2:-$1}"
  if brew list --cask "$cask" >/dev/null 2>&1; then ok "$label deja instalat"
  else run "brew install --cask $cask" || warn "$label nu s-a instalat — reia ./setup.sh dupa ce verifici reteaua"; fi
}
brew_formula() {
  local f="$1" label="${2:-$1}"
  if brew list --formula "$f" >/dev/null 2>&1; then ok "$label deja instalat"
  else run "brew install $f" || warn "$label nu s-a instalat — reia ./setup.sh dupa ce verifici reteaua"; fi
}

step "Ghostty (terminal recomandat pentru Claude Code)"
brew_cask ghostty "Ghostty"

step "Font — JetBrains Mono"
brew_cask font-jetbrains-mono "JetBrains Mono"

step "Node.js (runtime pentru Claude Code & multe proiecte)"
brew_formula node "Node.js"

step "GitHub CLI (gh) — pentru PR-uri / MCP github"
brew_formula gh "gh"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Claude Code (installer nativ oficial, fallback npm) + persista PATH
# ─────────────────────────────────────────────────────────────────────────────
step "Claude Code"
# installer-ul nativ pune binarul de obicei in ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
if command -v claude >/dev/null 2>&1; then
  ok "deja instalat ($(claude --version 2>/dev/null | head -1))"
elif $DRY_RUN; then
  skip "[dry-run] curl -fsSL https://claude.ai/install.sh | bash"
else
  if curl -fsSL https://claude.ai/install.sh | bash; then
    ok "instalat prin installer nativ"
  else
    warn "Installer nativ a esuat — fallback pe npm"
    npm install -g @anthropic-ai/claude-code
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi
# Persista ~/.local/bin in PATH pentru terminale viitoare
if $ADD_SHELL_ALIASES; then
  ensure_line "$SHELL_RC" 'export PATH="$HOME/.local/bin:$PATH"'
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. Config Ghostty (~/.config/ghostty/config)
# ─────────────────────────────────────────────────────────────────────────────
step "Config Ghostty"
read -r -d '' GHOSTTY_CONFIG <<'EOF' || true
# ~/.config/ghostty/config — generat de claude-code-guide/setup.sh
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
# 6. Config Claude Code (~/.claude/settings.json) — doar daca nu exista
# ─────────────────────────────────────────────────────────────────────────────
step "Config global Claude Code (~/.claude/settings.json)"
read -r -d '' CLAUDE_SETTINGS <<'EOF' || true
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "includeCoAuthoredBy": true,
  "permissions": {
    "allow": [
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(ls:*)",
      "Bash(cat:*)"
    ]
  }
}
EOF
if [ -f "$HOME/.claude/settings.json" ]; then
  # shellcheck disable=SC2088  # tilde e text afisat, nu cale de expandat
  skip "~/.claude/settings.json exista deja — nu il suprascriu"
else
  write_file "$HOME/.claude/settings.json" "$CLAUDE_SETTINGS"
fi

step "Global CLAUDE.md (~/.claude/CLAUDE.md)"
read -r -d '' GLOBAL_CLAUDE_MD <<'EOF' || true
# Preferinte globale

- Raspunde concis. Cod care se citeste ca restul codebase-ului.
- Inainte de task complex: Plan mode. Verifica cu teste/lint cand exista.
- Nu adauga comentarii redundante.
EOF
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  # shellcheck disable=SC2088  # tilde e text afisat, nu cale de expandat
  skip "~/.claude/CLAUDE.md exista deja — nu il ating"
else
  write_file "$HOME/.claude/CLAUDE.md" "$GLOBAL_CLAUDE_MD"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 7. Alias-uri shell (optional)
# ─────────────────────────────────────────────────────────────────────────────
if $ADD_SHELL_ALIASES; then
  step "Alias-uri zsh (~/.zshrc)"
  MARKER="# >>> claude-code-guide aliases >>>"
  if [ -f "$SHELL_RC" ] && grep -qF "$MARKER" "$SHELL_RC"; then
    skip "alias-uri deja prezente"
  elif $DRY_RUN; then
    skip "[dry-run] as adauga alias-uri in $SHELL_RC"
  else
    cat >> "$SHELL_RC" <<'EOF'

# >>> claude-code-guide aliases >>>
alias cc='claude'
alias ccc='claude --continue'        # reia ultima sesiune
alias ccp='claude --permission-mode plan'
# <<< claude-code-guide aliases <<<
EOF
    ok "alias-uri adaugate (cc, ccc, ccp) — fac efect la urmatorul terminal"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# Validare + final
# ─────────────────────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  validate || warn "Vezi mesajele de mai sus."
fi

printf "\n${BOLD}${GREEN}Gata.${RESET} Pasii urmatori:\n"
cat <<EOF
  1. Deschide ${BOLD}Ghostty${RESET} (Cmd+Space -> Ghostty). Deschide o fereastra NOUA.
  2. Scrie ${BOLD}claude${RESET} si autentifica-te (login in browser).
  3. Intra intr-un proiect si ruleaza ${BOLD}/init${RESET} (sau skill-ul /project-onboard).
  4. Oricand: ${BOLD}./setup.sh --check${RESET} verifica mediul; ${BOLD}claude doctor${RESET} verifica Claude.

  ${DIM}Ghid complet: claude-code-ghid.html / .pdf${RESET}
EOF
$DRY_RUN && warn "A fost dry-run — nimic nu s-a schimbat efectiv."
exit 0
