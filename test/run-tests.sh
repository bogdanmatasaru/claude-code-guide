#!/usr/bin/env bash
#
# test/run-tests.sh — Valideaza setup.sh fara sa atinga sistemul real.
#
# Ruleaza setup.sh intr-un HOME temporar, cu comenzi externe mock (brew, curl,
# claude, gh, xcode-select). Verifica: sintaxa, shellcheck, scrierile de config,
# JSON valid, persistarea PATH, idempotenta (rulare x2 fara backup-uri).
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$ROOT/setup.sh"
PASS=0; FAIL=0
GREEN=$'\033[32m'; RED=$'\033[31m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'

assert() { # assert "desc" condition...
  local desc="$1"; shift
  if "$@"; then printf "  ${GREEN}PASS${RESET} %s\n" "$desc"; PASS=$((PASS+1))
  else printf "  ${RED}FAIL${RESET} %s\n" "$desc"; FAIL=$((FAIL+1)); fi
}
assert_contains() { # assert_contains "desc" file "needle"
  local desc="$1" file="$2" needle="$3"
  if [ -f "$file" ] && grep -qF -- "$needle" "$file"; then
    printf "  ${GREEN}PASS${RESET} %s\n" "$desc"; PASS=$((PASS+1))
  else printf "  ${RED}FAIL${RESET} %s\n" "$desc"; FAIL=$((FAIL+1)); fi
}
# assert_out "desc" "$OUTPUT" "needle"  — outputul CONTINE needle (substring fix)
assert_out() {
  local desc="$1" out="$2" needle="$3"
  if grep -qF -- "$needle" <<<"$out"; then
    printf "  ${GREEN}PASS${RESET} %s\n" "$desc"; PASS=$((PASS+1))
  else printf "  ${RED}FAIL${RESET} %s\n" "$desc"; FAIL=$((FAIL+1)); fi
}
# assert_not_out "desc" "$OUTPUT" "needle"  — outputul NU contine needle
assert_not_out() {
  local desc="$1" out="$2" needle="$3"
  if grep -qF -- "$needle" <<<"$out"; then
    printf "  ${RED}FAIL${RESET} %s\n" "$desc"; FAIL=$((FAIL+1))
  else printf "  ${GREEN}PASS${RESET} %s\n" "$desc"; PASS=$((PASS+1)); fi
}
section() { printf "\n${BOLD}== %s ==${RESET}\n" "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
section "1. Sintaxa & lint static"
# ─────────────────────────────────────────────────────────────────────────────
assert "bash -n (setup.sh)"            bash -n "$SETUP"
assert "bash -n (run-tests.sh)"        bash -n "$0"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning "$SETUP"; then
    printf "  ${GREEN}PASS${RESET} shellcheck (fara warning-uri)\n"; PASS=$((PASS+1))
  else
    printf "  ${RED}FAIL${RESET} shellcheck a gasit probleme\n"; FAIL=$((FAIL+1))
  fi
else
  printf "  ${DIM}.... shellcheck nu e instalat (brew install shellcheck) — sar peste${RESET}\n"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Construieste un mediu mock: HOME temporar + comenzi false pe PATH.
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox() {
  SBOX="$(mktemp -d)"
  export FAKEHOME="$SBOX/home"; mkdir -p "$FAKEHOME"
  export BREW_STATE="$SBOX/brew-state"; mkdir -p "$BREW_STATE"
  BIN="$SBOX/bin"; mkdir -p "$BIN"

  # xcode-select: pretinde ca CLT sunt deja instalate
  cat > "$BIN/xcode-select" <<'SH'
#!/usr/bin/env bash
[ "$1" = "-p" ] && { echo /Library/Developer/CommandLineTools; exit 0; }
exit 0
SH

  # brew: stateful (markere in $BREW_STATE)
  cat > "$BIN/brew" <<'SH'
#!/usr/bin/env bash
S="$BREW_STATE"
case "$1" in
  --version) echo "Homebrew 4.0.0-mock"; exit 0 ;;
  shellenv)  echo "# mock brew shellenv"; exit 0 ;;
  list)
    # brew list --cask NAME | brew list --formula NAME
    key="${2#--}_$3"
    [ -f "$S/$key" ] && exit 0 || exit 1 ;;
  install)
    # Simuleaza un esec de retea daca testul cere (BREW_FAIL_INSTALL)
    if [ -n "${BREW_FAIL_INSTALL:-}" ]; then echo "mock: network fail"; exit 1; fi
    if [ "$2" = "--cask" ]; then touch "$S/cask_$3"
    else touch "$S/formula_$2"; fi
    echo "mock: installed $*"; exit 0 ;;
esac
exit 0
SH

  # curl: pentru claude.ai/install.sh emite un script ce instaleaza un claude fals
  cat > "$BIN/curl" <<'SH'
#!/usr/bin/env bash
url="${@: -1}"
case "$url" in
  *claude.ai/install.sh*)
    cat <<'INNER'
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\necho "2.1.0 (Claude Code mock)"\n' > "$HOME/.local/bin/claude"
chmod +x "$HOME/.local/bin/claude"
INNER
    ;;
  *) echo "" ;;
esac
exit 0
SH

  cat > "$BIN/gh" <<'SH'
#!/usr/bin/env bash
echo "gh mock"; exit 0
SH

  chmod +x "$BIN"/*
  # node real e nevoie inauntru pentru validarea JSON din setup.sh (validate()).
  # Il aducem prin symlink ca sa nu includem /opt/homebrew/bin (ar umbri brew-ul mock).
  REAL_NODE="$(command -v node || true)"
  [ -n "$REAL_NODE" ] && ln -sf "$REAL_NODE" "$BIN/node"
  export SANDBOX_BIN="$BIN"
}

run_setup() { # run_setup [args...] ; ruleaza setup.sh in sandbox
  env -i \
    HOME="$FAKEHOME" \
    BREW_STATE="$BREW_STATE" \
    BREW_FAIL_INSTALL="${BREW_FAIL_INSTALL:-}" \
    PATH="$SANDBOX_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    TERM=dumb \
    bash "$SETUP" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
section "2. Rulare completa pe 'Mac nou' (mock) — scrie config-uri"
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox
OUT1="$(run_setup 2>&1)"; RC1=$?
echo "$OUT1" | sed 's/^/    | /'
assert "exit code 0 la prima rulare"          test "$RC1" -eq 0

assert "config Ghostty exista"                test -f "$FAKEHOME/.config/ghostty/config"
assert_contains "Ghostty: tema Catppuccin"    "$FAKEHOME/.config/ghostty/config" "Catppuccin Mocha"
assert_contains "Ghostty: JetBrains Mono"     "$FAKEHOME/.config/ghostty/config" "font-family = JetBrains Mono"

assert "settings.json exista"                 test -f "$FAKEHOME/.claude/settings.json"
# path-ul trece prin argv (process.argv[1]), nu interpolat in sursa JS -> robust la spatii
assert "settings.json e JSON valid"           node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$FAKEHOME/.claude/settings.json"
assert "global CLAUDE.md exista"              test -f "$FAKEHOME/.claude/CLAUDE.md"

assert "claude 'instalat' (mock) pe PATH"     test -x "$FAKEHOME/.local/bin/claude"
# PATH + shellenv trebuie sa fie in .zshrc (sourceat de shell-uri interactive non-login)
assert_contains "PATH ~/.local/bin persistat" "$FAKEHOME/.zshrc" '.local/bin'
assert_contains "brew shellenv persistat"     "$FAKEHOME/.zshrc" 'shellenv'
assert_contains "alias cc in zshrc"           "$FAKEHOME/.zshrc" "alias cc='claude'"

assert "brew a instalat ghostty (marker)"     test -f "$BREW_STATE/cask_ghostty"
assert "brew a instalat node (marker)"        test -f "$BREW_STATE/formula_node"
assert_out "raport final: MEDIU VALID"        "$OUT1" "MEDIU VALID"

# ─────────────────────────────────────────────────────────────────────────────
section "3. Idempotenta — a doua rulare nu strica nimic"
# ─────────────────────────────────────────────────────────────────────────────
OUT2="$(run_setup 2>&1)"; RC2=$?
assert "exit code 0 la a doua rulare"         test "$RC2" -eq 0
assert_out "a doua rulare: 'deja instalat'"   "$OUT2" "deja instalat"
assert_out "a doua rulare: config 'deja la zi'" "$OUT2" "deja la zi"
# Niciun backup nu trebuie creat (continut identic, fisiere intacte)
BAKS=$(find "$FAKEHOME" -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' ')
assert "zero fisiere .bak (idempotent)"       test "$BAKS" -eq 0

# ─────────────────────────────────────────────────────────────────────────────
section "4. Mod --check pe mediu valid"
# ─────────────────────────────────────────────────────────────────────────────
OUT3="$(run_setup --check 2>&1)"; RC3=$?
assert "exit code 0 la --check"               test "$RC3" -eq 0
assert_out "--check raporteaza MEDIU VALID"   "$OUT3" "MEDIU VALID"

# ─────────────────────────────────────────────────────────────────────────────
section "5. --check pe mediu rupt detecteaza problema"
# ─────────────────────────────────────────────────────────────────────────────
rm -f "$FAKEHOME/.config/ghostty/config"
OUT4="$(run_setup --check 2>&1)"; RC4=$?
assert "exit code != 0 cand lipseste config"  test "$RC4" -ne 0
assert_out "raporteaza 'probleme' (esec curat)" "$OUT4" "probleme"

# ─────────────────────────────────────────────────────────────────────────────
section "6. --help e curat (fara linii de cod scapate)"
# ─────────────────────────────────────────────────────────────────────────────
OUT_HELP="$(run_setup --help 2>&1)"
assert_out "--help arata utilizarea"          "$OUT_HELP" "Utilizare:"
assert_not_out "--help nu scapa linia 'set'"  "$OUT_HELP" "set -uo"

# ─────────────────────────────────────────────────────────────────────────────
section "7. Esec de retea la 'brew install' NU omoara scriptul"
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox
OUT_FAIL="$(BREW_FAIL_INSTALL=1 run_setup 2>&1)"; RC_FAIL=$?
assert "scriptul nu crapa (exit 0)"           test "$RC_FAIL" -eq 0
assert_out "ruleaza pana la capat (banner Gata)" "$OUT_FAIL" "Gata."
assert_out "avertizeaza ca nu s-a instalat"   "$OUT_FAIL" "nu s-a instalat"
# Continua dincolo de brew: scrie totusi config-urile
assert "config Ghostty scris dupa esec brew"  test -f "$FAKEHOME/.config/ghostty/config"

# ─────────────────────────────────────────────────────────────────────────────
section "8. Dry-run nu scrie nimic"
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox
run_setup --dry-run >/dev/null 2>&1
WRITES=$(find "$FAKEHOME" -type f 2>/dev/null | wc -l | tr -d ' ')
assert "dry-run: zero fisiere scrise"         test "$WRITES" -eq 0

# ─────────────────────────────────────────────────────────────────────────────
section "Rezultat"
# ─────────────────────────────────────────────────────────────────────────────
printf "\n${BOLD}%d PASS, %d FAIL${RESET}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}${BOLD}TOATE TESTELE TREC.${RESET}\n"; exit 0; }
printf "${RED}${BOLD}AU ESUAT TESTE.${RESET}\n"; exit 1
