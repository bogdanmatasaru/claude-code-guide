---
title: Installation
description: Install Claude Code on macOS, Linux, or Windows, sign in with a paid plan, and verify your setup with claude doctor.
---
# Installation

Getting Claude Code running takes about two minutes: install the binary, sign in, and confirm everything works.

## Choose an install method

The native installer is recommended because it auto-updates in the background. Pick whichever row fits your setup.

| Method | Command | Notes |
| --- | --- | --- |
| Native (macOS/Linux/WSL) | `curl -fsSL https://claude.ai/install.sh \| bash` | Recommended. Auto-updates. |
| Native (Windows PowerShell) | `irm https://claude.ai/install.ps1 \| iex` | Recommended on Windows. |
| Homebrew | `brew install --cask claude-code` | No auto-update; run `brew upgrade claude-code`. |
| npm | `npm install -g @anthropic-ai/claude-code` | Requires Node.js 18+. |

The native install drops a binary at `~/.local/bin/claude`. Make sure that directory is on your `PATH` if the `claude` command isn't found after installing.

> [!TIP]
> On a fresh Mac, you can skip the manual steps entirely. See [the one-command setup](../environment/bootstrap-setup.md) for a one-command setup that installs everything at once.

## Platform notes

- **Windows:** Installing [Git for Windows](https://git-scm.com/downloads/win) lets Claude Code use the Bash tool; without it, it falls back to PowerShell. WSL setups don't need Git for Windows.
- **Linux:** You can also install via apt, dnf, or apk on Debian, Fedora, RHEL, and Alpine.

## Sign in

Claude Code requires an account on a **paid plan** — the free Claude tier won't work. Any of these work:

- Claude **Pro, Max, Team, or Enterprise** (recommended)
- **Claude Console** (API access with pre-paid credits)
- **Amazon Bedrock, Google Vertex AI, or Microsoft Foundry** (enterprise cloud)

Start a session and you'll be prompted to log in on first use:

```bash
claude
```

This opens your browser to complete authentication. Your credentials are stored afterward, so you only do this once. To switch accounts later, type `/login` inside a running session.

## Verify your setup

Confirm the install and check for common problems:

```bash
claude --version
claude doctor
```

`claude doctor` inspects your installation, PATH, shell, and permissions, and flags anything that needs attention. If it reports a clean bill of health, you're ready.

> [!NOTE]
> If `claude` isn't recognized, open a new terminal so your shell picks up the updated `PATH`, then try `claude doctor` again.

Next: [Quickstart](./quickstart.md)

**Source:** [Set up Claude Code](https://code.claude.com/docs/en/setup)
