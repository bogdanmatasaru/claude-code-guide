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

  # ccstatusline: report which profile the launcher chose, and nothing else.
  # Without this the profile tests are vacuous — on a runner with no
  # ccstatusline installed, "the output contains no usage widget" is true of
  # every possible launcher, including a broken one.
  cat > "$BIN/ccstatusline" <<'SH'
#!/usr/bin/env bash
cfg="DEFAULT"
while [ $# -gt 0 ]; do
  [ "$1" = "--config" ] && { cfg="$2"; shift; }
  shift
done
in=$(cat 2>/dev/null || true)
echo "CCSTATUSLINE_CONFIG=$(basename "$cfg")"
# Lets tests see whether the launcher's shim injected the synthetic reset field.
case "$in" in *resets_at*) echo "CCSTATUSLINE_STDIN_HAS_RESETS_AT=1" ;; esac
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
section "4c. Custom-endpoint profile (ANTHROPIC_BASE_URL sessions)"
# ─────────────────────────────────────────────────────────────────────────────
# On a custom base URL Claude Code omits rate_limits, and ccstatusline's usage
# widgets then fall back to Anthropic's usage API — rendering the wrong
# account's numbers. This profile must therefore carry none of them, and the
# launcher must decide on the provider before the account.
CUSTOM_PROFILE="$CCSL/settings.custom-endpoint.json"
assert "custom-endpoint profile installed"     test -f "$CUSTOM_PROFILE"
assert "custom-endpoint profile valid JSON"    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$CUSTOM_PROFILE"
for widget in session-usage weekly-usage weekly-sonnet-usage weekly-opus-usage \
              reset-timer weekly-reset-timer extra-usage-remaining \
              extra-usage-utilization block-timer session-cost; do
  assert "custom-endpoint profile drops $widget" \
    bash -c "! grep -qF '\"$widget\"' '$CUSTOM_PROFILE'"
done
assert_contains "launcher gates on ANTHROPIC_BASE_URL" "$CCSL/profile-switch.sh" "ANTHROPIC_BASE_URL"
assert_contains "launcher fails closed when the profile is missing" "$CCSL/profile-switch.sh" "custom endpoint · run ./setup.sh"
assert_out "--check reports the custom-endpoint profile" "$OUT3" "custom-endpoint profile"

# Which profile does the launcher actually hand to ccstatusline? The stub in
# make_sandbox echoes it back, so these assertions fail if the provider gate is
# removed — unlike "the output contains no usage widget", which is trivially
# true wherever ccstatusline isn't installed.
#
# env -i keeps this hermetic: without it the launcher resolves the REAL
# `security` binary and reads the developer's login keychain.
STATUS_PAYLOAD='{"model":{"display_name":"test-model"},"session_id":"t","transcript_path":"/dev/null","cwd":"/tmp","workspace":{"current_dir":"/tmp"}}'
launcher_profile() { # launcher_profile VAR=VALUE...
  printf '%s' "$STATUS_PAYLOAD" | env -i HOME="$FAKEHOME" \
    PATH="$SANDBOX_BIN:/usr/bin:/bin:/usr/sbin:/sbin" TERM=dumb "$@" \
    sh "$CCSL/profile-switch.sh" 2>/dev/null
}

# Positive control: with no provider variables set, the usage-bearing consumer
# profile MUST still be chosen. Without this, a launcher that always picked the
# custom profile would pass every other assertion here.
assert_out "first-party session gets the consumer profile" \
  "$(launcher_profile)" "CCSTATUSLINE_CONFIG=settings.consumer.json"

rm -f "$CCSL/.active-profile"
for host in https://api.example.invalid/ https://api.anthropic.com.example.invalid/; do
  assert_out "custom base URL gets the custom-endpoint profile ($host)" \
    "$(launcher_profile ANTHROPIC_BASE_URL="$host")" "CCSTATUSLINE_CONFIG=settings.custom-endpoint.json"
  assert "no profile cache written for $host" test ! -f "$CCSL/.active-profile"
done

# Bedrock / Vertex / Foundry set no base URL and have no oauth usage either.
for var in CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY; do
  assert_out "$var gets the custom-endpoint profile" \
    "$(launcher_profile "$var=1")" "CCSTATUSLINE_CONFIG=settings.custom-endpoint.json"
  assert "no profile cache written for $var" test ! -f "$CCSL/.active-profile"
done

# ─────────────────────────────────────────────────────────────────────────────
section "4d. Enterprise routing — the payload has the final word"
# ─────────────────────────────────────────────────────────────────────────────
# The sandbox `security` stub fails, so pick_profile falls back to this
# credentials fixture; without it every run lands on the consumer profile and
# the enterprise branch is unreachable from tests, in any direction.
CREDS="$FAKEHOME/.claude/.credentials.json"
printf '%s' '{"claudeAiOauth":{"subscriptionType":"enterprise"}}' > "$CREDS"
enterprise_launch() { # enterprise_launch PAYLOAD
  rm -f "$CCSL/.active-profile"
  printf '%s' "$1" | env -i HOME="$FAKEHOME" \
    PATH="$SANDBOX_BIN:/usr/bin:/bin:/usr/sbin:/sbin" TERM=dumb \
    sh "$CCSL/profile-switch.sh" 2>/dev/null
}
PAYLOAD_BASE='"model":{"display_name":"t"},"session_id":"t","cwd":"/tmp","workspace":{"current_dir":"/tmp"}'

# Bucketless payload: the classic enterprise seat — shim injects the synthetic
# five_hour.resets_at so reset-timer never poisons the shared usage fetch.
OUT_ENT="$(enterprise_launch "{$PAYLOAD_BASE}")"
assert_out "no buckets → enterprise profile"  "$OUT_ENT" "CCSTATUSLINE_CONFIG=settings.enterprise.json"
assert_out "no buckets → shim injected resets_at" "$OUT_ENT" "CCSTATUSLINE_STDIN_HAS_RESETS_AT=1"

# Hollow rate_limits (present but null buckets): must behave exactly like no
# rate_limits at all. This is the predicate-drift case — a probe keyed on
# five_hour.used_percentage and a shim keyed on mere rate_limits presence would
# each decline it, and the timer would render [Timeout].
OUT_HOLLOW="$(enterprise_launch "{$PAYLOAD_BASE,\"rate_limits\":{\"five_hour\":null,\"seven_day\":null}}")"
assert_out "hollow buckets → enterprise profile" "$OUT_HOLLOW" "CCSTATUSLINE_CONFIG=settings.enterprise.json"
assert_out "hollow buckets → shim injected resets_at" "$OUT_HOLLOW" "CCSTATUSLINE_STDIN_HAS_RESETS_AT=1"

# Both buckets real: the usage widgets have data, so hiding them behind the
# enterprise layout would be wrong — consumer profile wins.
OUT_BOTH="$(enterprise_launch "{$PAYLOAD_BASE,\"rate_limits\":{\"five_hour\":{\"used_percentage\":19,\"resets_at\":1787156400},\"seven_day\":{\"used_percentage\":2,\"resets_at\":1787648400}}}")"
assert_out "real 5h+7d buckets → consumer profile" "$OUT_BOTH" "CCSTATUSLINE_CONFIG=settings.consumer.json"

# five_hour alone is not enough: the consumer profile's weekly widgets would
# flip the shared usage object to {error} and take the 5h gauge down with it.
OUT_5H="$(enterprise_launch "{$PAYLOAD_BASE,\"rate_limits\":{\"five_hour\":{\"used_percentage\":19,\"resets_at\":1787156400},\"seven_day\":null}}")"
assert_out "five_hour-only → enterprise profile" "$OUT_5H" "CCSTATUSLINE_CONFIG=settings.enterprise.json"

rm -f "$CREDS" "$CCSL/.active-profile"

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
section "9. Second-provider setup never runs unattended"
# ─────────────────────────────────────────────────────────────────────────────
# It writes an inference endpoint and an API key, so it must happen only when a
# human typed yes at a terminal. The sandbox has no TTY, which is the same shape
# as CI and as any provisioning script — so every assertion here is checking that
# nothing happened.
# Its own sandbox and its own run: $FAKEHOME and $OUT1 belong to earlier
# sections by now, and asserting "nothing was written" against a sandbox that
# was never written to would pass for the wrong reason.
make_sandbox
OUT_ALT="$(run_setup 2>&1)"
assert_out "the step runs at all"                 "$OUT_ALT" "Second provider"
assert_out "and skips without an interactive terminal" \
  "$OUT_ALT" "not an interactive terminal"
assert "no alt config directory was created"      test ! -d "$FAKEHOME/.claude-alt"
assert "no alt settings file was written"         test ! -f "$FAKEHOME/.claude-alt/settings.json"
assert_not_out "no credential prompt was printed" "$OUT_ALT" "API key (input hidden)"
assert "no alt alias reached the shell rc" \
  bash -c "! grep -q 'claude-alt' '$FAKEHOME/.zshrc'"

# --dry-run must announce the step and still write nothing.
make_sandbox
OUT_DRY_ALT="$(run_setup --dry-run 2>&1)"
assert_out "dry-run announces the step"           "$OUT_DRY_ALT" "would offer to configure a second provider"
assert "dry-run writes no alt config"             test ! -d "$FAKEHOME/.claude-alt"

# Everything above runs without a TTY, so it can only prove the step stays shut.
# Proving what it does when a human says yes — and that it then refuses to
# overwrite — needs a real terminal, so drive one with a pty.
if command -v python3 >/dev/null 2>&1; then
  make_sandbox
  PTY_OUT="$(python3 - "$SETUP" "$FAKEHOME" "$SANDBOX_BIN" "$BREW_STATE" <<'PYEOF'
import os, pty, sys, time, select, json, stat

setup, home, sbin, brew_state = sys.argv[1:5]
env = {"HOME": home, "PATH": sbin + ":/usr/bin:/bin:/usr/sbin:/sbin",
       "TERM": "dumb", "BREW_STATE": brew_state}

def run(answers):
    pid, fd = pty.fork()
    if pid == 0:
        os.execve("/bin/bash", ["bash", setup], env)
    out, i, deadline = b"", 0, time.time() + 240
    while time.time() < deadline:
        r, _, _ = select.select([fd], [], [], 1.0)
        if r:
            try: chunk = os.read(fd, 8192)
            except OSError: break
            if not chunk: break
            out += chunk
            if i < len(answers) and answers[i][0] in out:
                time.sleep(0.2); os.write(fd, answers[i][1]); i += 1
        elif i >= len(answers):
            break
    try: os.waitpid(pid, os.WNOHANG)
    except Exception: pass
    return out.decode("utf-8", "replace")

first = run([(b"Type 'yes'", b"yes\n"), (b"Base URL", b"\n"),
             (b"API key", b"sk-PTY-CANARY\n"), (b"Model ID", b"\n"),
             (b"Context window", b"\n"), (b"Alias to launch", b"\n")])

path = os.path.join(home, ".claude-alt", "settings.json")
res = []
res.append(("prompted for a key", "API key (input hidden)" in first))
res.append(("key never echoed", "sk-PTY-CANARY" not in first))
if os.path.exists(path):
    d = json.load(open(path))
    e = d.get("env", {})
    models = {v for k, v in e.items() if k.endswith("_MODEL") or k == "ANTHROPIC_MODEL"}
    res.append(("wrote the alt settings file", True))
    res.append(("file mode is 600", oct(stat.S_IMODE(os.stat(path).st_mode)) == "0o600"))
    res.append(("key stored verbatim", e.get("ANTHROPIC_API_KEY") == "sk-PTY-CANARY"))
    res.append(("all six model slots set", len(models) == 1 and len([k for k in e if k.endswith("_MODEL") or k == "ANTHROPIC_MODEL"]) == 6))
    res.append(("WebSearch denied", d.get("permissions", {}).get("deny") == ["WebSearch"]))
    res.append(("alias reached the shell rc", "claude-alt" in open(os.path.join(home, ".zshrc")).read()))
else:
    res.append(("wrote the alt settings file", False))

# Second run, same answers: the guard must refuse and leave the file byte-identical.
before = open(path).read() if os.path.exists(path) else ""
second = run([(b"Type 'yes'", b"yes\n")])
after = open(path).read() if os.path.exists(path) else ""
# Assert on the message the guard itself prints, not on the absence of a later
# prompt: a broken guard that re-prompts and then stalls on the next question
# would satisfy the weaker test without the guard existing at all.
res.append(("re-run reports the config already exists",
            "second provider already configured" in second))
res.append(("re-run never reaches the key prompt", "API key (input hidden)" not in second))
res.append(("re-run leaves the file untouched", before == after and before != ""))

# Hostile inputs. Each of these could otherwise close the env object and append a
# top-level hooks block — a shell command run at every session start, in a file
# that still parses as JSON and still holds the right key.
for label, answers in [
    ("a base URL carrying a quote is rejected",
     [(b"Type 'yes'", b"yes\n"),
      (b"Base URL", b'https://a.test/"},"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"echo PWNED"}]}]},"env":{"X":"1\n')]),
    ("a model ID carrying a quote is rejected",
     [(b"Type 'yes'", b"yes\n"), (b"Base URL", b"\n"), (b"API key", b"sk-X\n"),
      (b"Model ID", b'k3","evil":"yes\n')]),
    ("an alias starting with a dash is rejected",
     [(b"Type 'yes'", b"yes\n"), (b"Base URL", b"\n"), (b"API key", b"sk-X\n"),
      (b"Model ID", b"\n"), (b"Context window", b"\n"), (b"Alias to launch", b"-n\n")]),
]:
    if os.path.exists(path):
        os.remove(path)
    out = run(answers)
    wrote = os.path.exists(path)
    res.append((label, ("aborting" in out) and not wrote))

# A planted symlink must not be followed. [ -f ] is false for a dangling link, so
# without an explicit check the already-configured guard is skipped and the key
# is written to the link target instead — anywhere the user can write.
import shutil as _sh
alt_dir = os.path.dirname(path)
_sh.rmtree(alt_dir, ignore_errors=True)
os.makedirs(alt_dir, exist_ok=True)
victim = os.path.join(home, "VICTIM-should-not-exist")
os.symlink(victim, path)
out = run([(b"Type 'yes'", b"yes\n"), (b"Base URL", b"\n"), (b"API key", b"sk-X\n"),
           (b"Model ID", b"\n"), (b"Context window", b"\n"), (b"Alias to launch", b"\n")])
res.append(("a symlinked settings.json is refused", "symlink" in out))
res.append(("no key written through the symlink", not os.path.exists(victim)))

for name, okness in res:
    print(("PTYPASS " if okness else "PTYFAIL ") + name)
PYEOF
)"
  while IFS= read -r line; do
    case "$line" in
      PTYPASS\ *) printf "  ${GREEN}PASS${RESET} %s\n" "${line#PTYPASS }"; PASS=$((PASS+1)) ;;
      PTYFAIL\ *) printf "  ${RED}FAIL${RESET} %s\n" "${line#PTYFAIL }"; FAIL=$((FAIL+1)) ;;
    esac
  done <<< "$PTY_OUT"
else
  printf "  ${DIM}.... python3 missing — skipping the interactive pty tests${RESET}\n"
fi

# ─────────────────────────────────────────────────────────────────────────────
section "Result"
# ─────────────────────────────────────────────────────────────────────────────
printf "\n${BOLD}%d PASS, %d FAIL${RESET}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}${BOLD}ALL TESTS PASS.${RESET}\n"; exit 0; }
printf "${RED}${BOLD}TESTS FAILED.${RESET}\n"; exit 1
