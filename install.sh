#!/usr/bin/env bash
#
# install.sh — TRUE one-command bootstrap for Claude Code + Ghostty on a fresh Mac.
#
#   curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash
#
# Downloads this repo (no git required — uses a tarball) and runs setup.sh.
# Flags pass straight through to setup.sh:
#   curl -fsSL .../install.sh | bash -s -- --dry-run
#
# Override where it lands: CLAUDE_GUIDE_DIR=~/code/ccg curl ... | bash
#
set -uo pipefail

REPO="bogdanmatasaru/claude-code-guide"
BRANCH="main"
DEST="${CLAUDE_GUIDE_DIR:-$HOME/claude-code-guide}"

if [ -t 1 ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; BLUE=$'\033[34m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; BLUE=""; RED=""; RESET=""
fi
say() { printf "${BLUE}> %s${RESET}\n" "$*"; }
die() { printf "${RED}xx %s${RESET}\n" "$*" >&2; exit 1; }

# Fetch the repo into "$1". Uses git when present, else a curl+tar tarball
# (so it works on a brand-new Mac that doesn't have git yet).
download_into() {
  local dest="$1"
  if command -v git >/dev/null 2>&1; then
    rm -rf "$dest"
    git clone --depth 1 --branch "$BRANCH" "https://github.com/$REPO.git" "$dest" --quiet
  else
    local tmp; tmp="$(mktemp -d)"
    curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar xz -C "$tmp" \
      || die "Download failed. Check your network and try again."
    rm -rf "$dest"
    mv "$tmp/claude-code-guide-$BRANCH" "$dest"
    rm -rf "$tmp"
  fi
}

# Is "$1" our guide checkout? (safe to overwrite)
is_guide() { [ -f "$1/setup.sh" ] && grep -q 'claude-code-guide' "$1/setup.sh" 2>/dev/null; }

printf "${BOLD}Claude Code + Ghostty — one-command install${RESET}\n"

if [ -e "$DEST" ]; then
  if is_guide "$DEST"; then
    say "Updating the guide at $DEST"
    if [ -d "$DEST/.git" ] && command -v git >/dev/null 2>&1; then
      git -C "$DEST" pull --ff-only --quiet || say "(couldn't fast-forward; keeping local copy)"
    else
      download_into "$DEST"
    fi
  else
    die "$DEST already exists and isn't the guide. Set CLAUDE_GUIDE_DIR=<other path> and re-run."
  fi
else
  say "Downloading the guide into $DEST"
  download_into "$DEST"
fi

cd "$DEST" || die "Could not enter $DEST"
chmod +x setup.sh
printf "${GREEN}Got it.${RESET} Running setup...\n\n"
exec ./setup.sh "$@"
