---
layout: home

hero:
  name: Claude Code Guide
  text: From first session to expert workflows
  tagline: Every command, flag, hook, MCP, and best practice — plus a one-command terminal + Ghostty setup. Beginner-friendly, always current.
  actions:
    - theme: brand
      text: Get started
      link: /getting-started/quickstart
    - theme: alt
      text: Learning path
      link: /learning-path
    - theme: alt
      text: Cheatsheet
      link: /cheatsheet

features:
  - icon: 🚀
    title: Zero to first win in 5 minutes
    details: Install, open a repo, and ship your first Claude-assisted change. A guided quickstart that respects your time.
    link: /getting-started/quickstart
  - icon: 🧭
    title: Structured for every level
    details: Tutorials to learn, how-to guides to get the job done, and a deep reference to look anything up. Pick your track.
    link: /learning-path
  - icon: ⚡
    title: One-command environment
    details: A reproducible setup.sh that gets a fresh Mac to a fully-configured Claude Code + Ghostty in one command.
    link: /environment/bootstrap-setup
  - icon: 🧩
    title: Copy-paste asset library
    details: Ready-to-use CLAUDE.md templates, slash commands, hooks, and settings you can drop into your own projects.
    link: https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets
  - icon: 💸
    title: Go faster and cheaper
    details: Model selection, context management, and the optimizations experienced developers actually use.
    link: /guides/cost-optimization
  - icon: ✅
    title: Accurate and cited
    details: Facts checked against the official docs and version-stamped, so you can trust what you read.
    link: /best-practices
---

## Install the whole stack in one command

Fresh Mac? This takes you from nothing to a fully-configured Claude Code + Ghostty —
**no git, Homebrew, or Node needed first.** The script installs the whole stack for you.

```bash
curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash
```

Then open **Ghostty**, type `claude`, and log in. That's it. →
[Full setup guide](/environment/bootstrap-setup)

### What that one command does

It runs an idempotent, re-runnable bootstrap that installs and configures everything, in order:

| Step | What it sets up |
| --- | --- |
| 1 | **Xcode Command Line Tools** — git & compilers |
| 2 | **Homebrew** — the macOS package manager |
| 3 | **Ghostty** + JetBrains Mono — the recommended terminal |
| 4 | **Node.js** + GitHub CLI |
| 5 | **Claude Code** — the `claude` CLI |
| 6 | **Configs** — Ghostty theme, `~/.claude` settings, shell PATH & aliases |
| 7 | **Live status line** — model · context · 5h/weekly limits · branch · session · disk |

> [!TIP]
> Want to preview it first, changing nothing? Add `--dry-run`:
> `curl -fsSL …/install.sh | bash -s -- --dry-run`.
> Already set up? Run `./setup.sh --check` anytime to validate your environment.

Prefer to do it step by step, or not on a Mac? See the
[installation guide](/getting-started/installation) and the
[one-command setup](/environment/bootstrap-setup) page.
