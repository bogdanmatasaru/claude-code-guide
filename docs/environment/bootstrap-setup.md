---
title: One-command setup (setup.sh)
description: Bootstrap a complete Claude Code + Ghostty environment on a fresh Mac with one idempotent, network-tolerant script.
---
# One-command setup (setup.sh)

[`../../setup.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/setup.sh) takes a clean Mac to a working Claude Code environment in one command — terminal, runtime, CLI, fonts, and configs — and it's safe to re-run.

## What it does

The script runs everything from zero, in order:

1. **Xcode Command Line Tools** — installs git and compilers, then waits (up to ~30 min) for Apple's installer to finish.
2. **Homebrew** — installs it if missing and persists `brew shellenv` to your `~/.zshrc`.
3. **Ghostty** — `brew install --cask ghostty`, the recommended terminal.
4. **JetBrains Mono** — `brew install --cask font-jetbrains-mono`.
5. **Node.js** — the runtime for Claude Code and many projects.
6. **GitHub CLI (`gh`)** — for pull requests and the GitHub MCP.
7. **Claude Code** — via the official native installer (`curl -fsSL https://claude.ai/install.sh | bash`), with an npm fallback. Persists `~/.local/bin` on your PATH.
8. **Ghostty config** — writes `~/.config/ghostty/config` (Catppuccin auto dark/light, JetBrains Mono).
9. **Global Claude config** — writes `~/.claude/settings.json` and `~/.claude/CLAUDE.md`, but only if they don't already exist.
10. **Shell aliases** — adds `cc`, `ccc`, `ccp` to `~/.zshrc`.
11. **Validation** — runs `validate()` to report what's in place and what's missing.

## Flags

| Flag | Effect |
| --- | --- |
| `--dry-run` | Show what it would do, change nothing. |
| `--check` | Only validate an existing environment (no install). Exits non-zero if anything is missing — useful in CI. |
| `--no-shell` | Don't touch your shell rc (no PATH lines, no aliases). |
| `--help` / `-h` | Print usage and exit. |

## Step-by-step on a fresh Mac

The fastest path — **one command**, nothing installed first (not even git; the script
pulls everything in):

```bash
curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash
```

[`install.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/install.sh)
downloads this repo (via a tarball, so git isn't required yet) and runs `setup.sh` for
you. Flags pass straight through, e.g. preview without changing anything:

```bash
curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash -s -- --dry-run
```

> [!TIP]
> Piping a script to `bash` runs code from the internet. You can read
> [`install.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/install.sh)
> and [`setup.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/setup.sh)
> first, or use `--dry-run` to see every action before anything is written.

Prefer to clone and run it yourself? Same result:

```bash
git clone https://github.com/bogdanmatasaru/claude-code-guide.git
cd claude-code-guide
./setup.sh
```

Then:

1. Open **Ghostty** (Cmd+Space → Ghostty). Open a **new** window so the updated `~/.zshrc` is sourced.
2. Type `claude` and authenticate (log in via the browser).
3. Enter a project and run `/init` (or the `/project-onboard` skill) to generate a `CLAUDE.md` and propose permissions.

> [!TIP]
> Want to see exactly what will happen before committing? Run `./setup.sh --dry-run` first — it prints every action and writes nothing.

## What it writes

| Path | Contents |
| --- | --- |
| `~/.config/ghostty/config` | Ghostty theme, font, padding, cursor settings. |
| `~/.claude/settings.json` | Global settings with a small safe permission allowlist (only if absent). |
| `~/.claude/CLAUDE.md` | Global preferences (only if absent). |
| `~/.zshrc` | `brew shellenv`, `~/.local/bin` on PATH, and the `cc` / `ccc` / `ccp` aliases. |

The aliases: `cc` = `claude`, `ccc` = `claude --continue` (resume the last session), `ccp` = `claude --permission-mode plan`.

## Idempotency & network tolerance

The script is **safe to re-run**. It backs up a file only when its contents would actually change, skips anything already installed, and adds each `~/.zshrc` line exactly once (marker-checked).

It also **does not abort on a failed install**. If a `brew install` fails (e.g. no network), it warns and keeps going. Because the script is idempotent, you just re-run it later to finish only what's left.

> [!NOTE]
> The script deliberately avoids `set -e`. One failing step must not kill the whole bootstrap — `validate()` at the end reports precisely what's still missing.

## Validate anytime

```bash
./setup.sh --check    # validate the environment (non-zero exit if broken)
claude doctor         # check the Claude Code install itself
```

`--check` confirms `brew`, `node`, `claude`, the Ghostty cask, both config files, and that `settings.json` is valid JSON.

## The test suite

The script ships with a **test suite (32 checks)** that runs `setup.sh` in a temporary `HOME` with mocked commands — no changes to your real system:

```bash
./test/run-tests.sh
```

See [`../../test/run-tests.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/test/run-tests.sh). It covers syntax and shellcheck, a full fresh-Mac run, config writes and valid JSON, PATH persistence, idempotency (a second run makes zero `.bak` files), `--check` on both healthy and broken environments, clean `--help` output, network-failure tolerance, and that `--dry-run` writes nothing.

## Next steps

- Tune your terminal further in [Terminal & Ghostty setup](./terminal-and-ghostty.md).
- Keep an eye on spend with [Monitor cost & rate limits](./monitoring-cost-ratelimits.md).
