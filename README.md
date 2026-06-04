<div align="center">

<img src="media/logo.svg" alt="Claude Code Guide" width="120" />

# Claude Code Guide

**The complete, always-current guide to [Claude Code](https://code.claude.com/docs) — from your first session to expert workflows.**

Every command, flag, hook, MCP, subagent, and best practice — plus a one-command terminal + Ghostty setup. Beginner-friendly, accurate, and cited.

[![Stars](https://img.shields.io/github/stars/bogdanmatasaru/claude-code-guide?style=flat&logo=github&color=8b5cf6)](https://github.com/bogdanmatasaru/claude-code-guide/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Last commit](https://img.shields.io/github/last-commit/bogdanmatasaru/claude-code-guide?color=8b5cf6)](https://github.com/bogdanmatasaru/claude-code-guide/commits/main)
[![Docs site](https://img.shields.io/badge/docs-online-8b5cf6)](https://bogdanmatasaru.github.io/claude-code-guide/)
[![CI](https://github.com/bogdanmatasaru/claude-code-guide/actions/workflows/ci.yml/badge.svg)](https://github.com/bogdanmatasaru/claude-code-guide/actions/workflows/ci.yml)

[**📖 Read the guide →**](https://bogdanmatasaru.github.io/claude-code-guide/) · [**🧭 Learning path**](docs/learning-path.md) · [**⚡ Cheatsheet**](docs/cheatsheet.md)

<img src="media/demo.gif" alt="setup.sh bootstrapping a fresh Mac" width="720" />

</div>

---

## 30-second start

On a fresh Mac, go from zero to a fully-configured Claude Code + Ghostty in **one command**:

```bash
git clone https://github.com/bogdanmatasaru/claude-code-guide.git
cd claude-code-guide && ./setup.sh
```

Then open Ghostty, type `claude`, and log in. That's it. → [Full setup guide](docs/environment/bootstrap-setup.md)

Already set up? Jump straight to the [**Cheatsheet**](docs/cheatsheet.md) or pick your [**Learning path**](docs/learning-path.md).

## Why this exists

The official docs are excellent reference material — but they don't hold your hand on day one, and they don't show you the *workflows*. This guide is the missing layer:

- **Structured for every level** — tutorials to learn, how-to guides to get the job done, and a deep reference to look anything up ([Diátaxis](https://diataxis.fr/)).
- **Simple → complex** — a first-timer and a power user both find their level.
- **Accurate & cited** — facts checked against the [official docs](https://code.claude.com/docs) and version-stamped.
- **Copy-paste assets** — drop-in `CLAUDE.md` templates, slash commands, hooks, and settings.
- **A real environment, not just docs** — a reproducible one-command setup plus cost and rate-limit monitoring you won't find in other guides.

## What's inside

| Section | For |
|---|---|
| 🚀 [Getting started](docs/getting-started/quickstart.md) | Install → first win → first real session |
| 🛠️ [Guides](docs/guides/onboard-a-codebase.md) | Task recipes: onboard a codebase, fix a bug, refactor, parallel work, CI |
| 📚 [Reference](docs/reference/cli.md) | One page per feature: CLI, hooks, MCP, skills, subagents, settings, models… |
| 🧠 [Explanation](docs/explanation/how-claude-works.md) | Mental models: how it works, the context window, when to use what |
| 💻 [Environment](docs/environment/bootstrap-setup.md) | Terminal & Ghostty, the `setup.sh` bootstrap, cost monitoring |
| ⭐ [Best practices](docs/best-practices.md) | Curated, attributed tips — official vs community |
| 🧩 [Asset library](assets/) | `CLAUDE.md` templates · commands · hooks · settings · skills |

## Quick links

- **New to Claude Code?** → [Quickstart (5 min)](docs/getting-started/quickstart.md)
- **Want a map?** → [Learning path](docs/learning-path.md) (diagnostic → personalized track)
- **Need a fact fast?** → [Cheatsheet](docs/cheatsheet.md) (one page, Cmd-F friendly)
- **Optimizing?** → [Cost & context](docs/guides/cost-optimization.md) · [Subagents](docs/reference/subagents.md) · [Hooks](docs/reference/hooks.md)

## Contributing

This guide stays valuable only if it stays accurate and current — and that's a team sport. Corrections, new recipes, and assets are all welcome, no matter how small. See [CONTRIBUTING.md](CONTRIBUTING.md) and look for `good first issue`.

## Star history

<a href="https://star-history.com/#bogdanmatasaru/claude-code-guide&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=bogdanmatasaru/claude-code-guide&type=Date&theme=dark" />
    <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=bogdanmatasaru/claude-code-guide&type=Date" width="600" />
  </picture>
</a>

## License & disclaimer

[MIT](LICENSE) © Bogdan Matasaru. A community guide — **not affiliated with Anthropic**. "Claude" and "Claude Code" are trademarks of Anthropic. Facts are cited against the official docs; when in doubt, [code.claude.com/docs](https://code.claude.com/docs) is the source of truth.
