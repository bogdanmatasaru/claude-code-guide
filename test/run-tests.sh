#!/usr/bin/env bash
#
# test/run-tests.sh — Validate setup.sh without touching the real system.
#
# Runs setup.sh in a temporary HOME with mocked external commands (brew, curl,
# claude, gh, xcode-select). Checks: syntax, shellcheck, config writes, valid
# JSON, PATH persistence, idempotency (run x2 with no backups).
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
# assert_out "desc" "$OUTPUT" "needle"  — output CONTAINS needle (fixed substring)
assert_out() {
  local desc="$1" out="$2" needle="$3"
  if grep -qF -- "$needle" <<<"$out"; then
    printf "  ${GREEN}PASS${RESET} %s\n" "$desc"; PASS=$((PASS+1))
  else printf "  ${RED}FAIL${RESET} %s\n" "$desc"; FAIL=$((FAIL+1)); fi
}
# assert_not_out "desc" "$OUTPUT" "needle"  — output does NOT contain needle
assert_not_out() {
  local desc="$1" out="$2" needle="$3"
  if grep -qF -- "$needle" <<<"$out"; then
    printf "  ${RED}FAIL${RESET} %s\n" "$desc"; FAIL=$((FAIL+1))
  else printf "  ${GREEN}PASS${RESET} %s\n" "$desc"; PASS=$((PASS+1)); fi
}
section() { printf "\n${BOLD}== %s ==${RESET}\n" "$*"; }

# ─────────────────────────────────────────────────────────────────────────────
section "1. Syntax & static lint"
# ─────────────────────────────────────────────────────────────────────────────
assert "bash -n (setup.sh)"            bash -n "$SETUP"
assert "bash -n (run-tests.sh)"        bash -n "$0"
if command -v shellcheck >/dev/null 2>&1; then
  if shellcheck -S warning "$SETUP"; then
    printf "  ${GREEN}PASS${RESET} shellcheck (no warnings)\n"; PASS=$((PASS+1))
  else
    printf "  ${RED}FAIL${RESET} shellcheck found problems\n"; FAIL=$((FAIL+1))
  fi
else
  printf "  ${DIM}.... shellcheck not installed (brew install shellcheck) — skipping${RESET}\n"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Build a mock environment: temporary HOME + fake commands on PATH.
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox() {
  SBOX="$(mktemp -d)"
  export FAKEHOME="$SBOX/home"; mkdir -p "$FAKEHOME"
  export BREW_STATE="$SBOX/brew-state"; mkdir -p "$BREW_STATE"
  BIN="$SBOX/bin"; mkdir -p "$BIN"

  # xcode-select: pretend CLT are already installed
  cat > "$BIN/xcode-select" <<'SH'
#!/usr/bin/env bash
[ "$1" = "-p" ] && { echo /Library/Developer/CommandLineTools; exit 0; }
exit 0
SH

  # brew: stateful (markers in $BREW_STATE)
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
    # Simulate a network failure if the test asks (BREW_FAIL_INSTALL)
    if [ -n "${BREW_FAIL_INSTALL:-}" ]; then echo "mock: network fail"; exit 1; fi
    if [ "$2" = "--cask" ]; then touch "$S/cask_$3"
    else touch "$S/formula_$2"; fi
    echo "mock: installed $*"; exit 0 ;;
esac
exit 0
SH

  # curl: for claude.ai/install.sh emit a script that installs a fake claude
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

  # security: pretend there's no Claude credential in the keychain, so the
  # account-aware status line detection is deterministic (defaults to consumer)
  # and never touches the real login keychain during tests.
  cat > "$BIN/security" <<'SH'
#!/usr/bin/env bash
exit 1
SH

  chmod +x "$BIN"/*
  # The real node is needed inside for setup.sh's JSON validation (validate()).
  # We symlink it in so we don't add /opt/homebrew/bin (which would shadow the brew mock).
  REAL_NODE="$(command -v node || true)"
  [ -n "$REAL_NODE" ] && ln -sf "$REAL_NODE" "$BIN/node"
  export SANDBOX_BIN="$BIN"
}

run_setup() { # run_setup [args...] ; run setup.sh in the sandbox
  env -i \
    HOME="$FAKEHOME" \
    BREW_STATE="$BREW_STATE" \
    BREW_FAIL_INSTALL="${BREW_FAIL_INSTALL:-}" \
    PATH="$SANDBOX_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
    TERM=dumb \
    bash "$SETUP" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
section "2. Full run on a 'fresh Mac' (mock) — writes configs"
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox
OUT1="$(run_setup 2>&1)"; RC1=$?
echo "$OUT1" | sed 's/^/    | /'
assert "exit code 0 on first run"             test "$RC1" -eq 0

assert "Ghostty config exists"                test -f "$FAKEHOME/.config/ghostty/config"
assert_contains "Ghostty: Catppuccin theme"   "$FAKEHOME/.config/ghostty/config" "Catppuccin Mocha"
assert_contains "Ghostty: JetBrains Mono"     "$FAKEHOME/.config/ghostty/config" "font-family = JetBrains Mono"

assert "settings.json exists"                 test -f "$FAKEHOME/.claude/settings.json"
# the path goes through argv (process.argv[1]), not interpolated into JS source -> robust to spaces
assert "settings.json is valid JSON"          node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$FAKEHOME/.claude/settings.json"
assert "global CLAUDE.md exists"              test -f "$FAKEHOME/.claude/CLAUDE.md"

assert "claude 'installed' (mock) on PATH"    test -x "$FAKEHOME/.local/bin/claude"
# PATH + shellenv must be in .zshrc (sourced by non-login interactive shells)
assert_contains "PATH ~/.local/bin persisted" "$FAKEHOME/.zshrc" '.local/bin'
assert_contains "brew shellenv persisted"     "$FAKEHOME/.zshrc" 'shellenv'
assert_contains "alias cc in zshrc"           "$FAKEHOME/.zshrc" "alias cc='claude'"

assert "brew installed ghostty (marker)"      test -f "$BREW_STATE/cask_ghostty"
assert "brew installed node (marker)"         test -f "$BREW_STATE/formula_node"
assert_out "final report: ENVIRONMENT OK"     "$OUT1" "ENVIRONMENT OK"

# ─────────────────────────────────────────────────────────────────────────────
section "3. Idempotency — a second run breaks nothing"
# ─────────────────────────────────────────────────────────────────────────────
OUT2="$(run_setup 2>&1)"; RC2=$?
assert "exit code 0 on second run"            test "$RC2" -eq 0
assert_out "second run: 'already installed'"  "$OUT2" "already installed"
assert_out "second run: config 'up to date'"  "$OUT2" "already up to date"
# No backup should be created (identical content, files intact)
BAKS=$(find "$FAKEHOME" -name '*.bak.*' 2>/dev/null | wc -l | tr -d ' ')
assert "zero .bak files (idempotent)"         test "$BAKS" -eq 0

# ─────────────────────────────────────────────────────────────────────────────
section "4. --check mode on a valid environment"
# ─────────────────────────────────────────────────────────────────────────────
OUT3="$(run_setup --check 2>&1)"; RC3=$?
assert "exit code 0 on --check"               test "$RC3" -eq 0
assert_out "--check reports ENVIRONMENT OK"   "$OUT3" "ENVIRONMENT OK"

# ─────────────────────────────────────────────────────────────────────────────
section "4b. Account-aware status-line profiles"
# ─────────────────────────────────────────────────────────────────────────────
CCSL="$FAKEHOME/.config/ccstatusline"
assert "profile-switch.sh installed (exec)"   test -x "$CCSL/profile-switch.sh"
assert "consumer profile installed"           test -f "$CCSL/settings.consumer.json"
assert "enterprise profile installed"         test -f "$CCSL/settings.enterprise.json"
assert "consumer profile valid JSON"          node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$CCSL/settings.consumer.json"
assert "enterprise profile valid JSON"        node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$CCSL/settings.enterprise.json"
assert_contains "enterprise profile uses extra-usage"  "$CCSL/settings.enterprise.json" "extra-usage-remaining"
assert_contains "consumer profile uses session-usage"  "$CCSL/settings.consumer.json" "session-usage"
assert "enterprise profile drops weekly-usage"  bash -c "! grep -qF weekly-usage '$CCSL/settings.enterprise.json'"
assert_contains "launcher carries the enterprise shim"  "$CCSL/profile-switch.sh" "rate_limits"
assert_contains "settings.json points at the launcher" "$FAKEHOME/.claude/settings.json" "profile-switch.sh"
assert_out "--check reports the profile switcher"      "$OUT3" "profile switcher installed"

# ─────────────────────────────────────────────────────────────────────────────
section "5. --check on a broken environment detects the problem"
# ─────────────────────────────────────────────────────────────────────────────
rm -f "$FAKEHOME/.config/ghostty/config"
OUT4="$(run_setup --check 2>&1)"; RC4=$?
assert "exit code != 0 when config missing"   test "$RC4" -ne 0
assert_out "reports 'problem' (clean fail)"   "$OUT4" "problem"

# ─────────────────────────────────────────────────────────────────────────────
section "6. --help is clean (no leaked code lines)"
# ─────────────────────────────────────────────────────────────────────────────
OUT_HELP="$(run_setup --help 2>&1)"
assert_out "--help shows usage"               "$OUT_HELP" "Usage:"
assert_not_out "--help doesn't leak 'set'"    "$OUT_HELP" "set -uo"

# ─────────────────────────────────────────────────────────────────────────────
section "7. A network failure on 'brew install' does NOT kill the script"
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox
OUT_FAIL="$(BREW_FAIL_INSTALL=1 run_setup 2>&1)"; RC_FAIL=$?
assert "script doesn't crash (exit 0)"        test "$RC_FAIL" -eq 0
assert_out "runs to the end (Done. banner)"   "$OUT_FAIL" "Done."
assert_out "warns it could not be installed"  "$OUT_FAIL" "could not be installed"
# Continues past brew: still writes the configs
assert "Ghostty config written after fail"    test -f "$FAKEHOME/.config/ghostty/config"

# ─────────────────────────────────────────────────────────────────────────────
section "8. Dry-run writes nothing"
# ─────────────────────────────────────────────────────────────────────────────
make_sandbox
run_setup --dry-run >/dev/null 2>&1
WRITES=$(find "$FAKEHOME" -type f 2>/dev/null | wc -l | tr -d ' ')
assert "dry-run: zero files written"          test "$WRITES" -eq 0

# ─────────────────────────────────────────────────────────────────────────────
section "Result"
# ─────────────────────────────────────────────────────────────────────────────
printf "\n${BOLD}%d PASS, %d FAIL${RESET}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}${BOLD}ALL TESTS PASS.${RESET}\n"; exit 0; }
printf "${RED}${BOLD}TESTS FAILED.${RESET}\n"; exit 1
