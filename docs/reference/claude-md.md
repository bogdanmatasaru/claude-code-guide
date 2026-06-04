---
title: CLAUDE.md & memory
description: How Claude Code loads CLAUDE.md files, imports, path-scoped rules, and auto memory across sessions.
---
# CLAUDE.md & memory

`CLAUDE.md` gives Claude persistent, project-specific instructions that load at the start of every session. Auto memory complements it by letting Claude record its own learnings over time.

## Load order

Files load broadest scope first, so more specific instructions appear later in context and take precedence in practice.

| Scope | Location | Shared with |
| --- | --- | --- |
| Managed policy | macOS `/Library/Application Support/ClaudeCode/CLAUDE.md` · Linux/WSL `/etc/claude-code/CLAUDE.md` | Whole organization |
| User | `~/.claude/CLAUDE.md` | Just you (all projects) |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team, via source control |
| Local | `./CLAUDE.local.md` (gitignore it) | Just you (this project) |

Claude walks up the directory tree from your working directory and loads every `CLAUDE.md` it finds, root-to-leaf. Files in subdirectories load **on demand** when Claude reads files there. Run `/init` to generate a starting project file.

> [!NOTE]
> Claude Code reads `CLAUDE.md`, not `AGENTS.md`. To reuse an existing `AGENTS.md`, import it (`@AGENTS.md`) or symlink it.

## Imports

Pull in other files with `@path` syntax. Relative paths resolve against the file doing the import. Imports can nest up to **four hops** deep.

```markdown
# Project Guide
See @README.md for an overview and @package.json for scripts.
- Git workflow: @docs/git-instructions.md
```

Imported files still load into context at launch — imports aid organization, not token savings.

## Path-scoped rules

Put topic files in `.claude/rules/*.md`. Add optional `paths:` frontmatter to load a rule only when Claude touches matching files:

```markdown
---
paths:
  - "src/api/**/*.ts"
---
# API rules
- Validate all endpoint inputs.
- Use the standard error response format.
```

Rules without `paths` load unconditionally, like `.claude/CLAUDE.md`.

## Keep it short

Target **under 200 lines** per file. CLAUDE.md loads in full every session and consumes context; bloat both costs tokens and *reduces* adherence. When a file grows, move detail into path-scoped rules or skills.

### What to include

- Build, test, and lint commands
- Project layout and architecture
- Naming and code-style conventions
- "Always do X" / "never do Y" rules

### What to leave out

- One-off, task-specific procedures (use a skill)
- Instructions that only matter for one directory (use a path-scoped rule)
- Long prose, changelogs, or generated content
- Secrets or machine-specific paths (use `CLAUDE.local.md`)

See [cost-optimization.md](../guides/cost-optimization.md) for why a lean memory file saves money. Starter templates live in [`assets/claude-md/`](https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets/claude-md).

## A tiny example

```markdown
# Acme API

## Commands
- Test: `npm test`
- Lint: `npm run lint` (run before every commit)

## Conventions
- 2-space indentation; TypeScript strict mode.
- API handlers live in `src/api/handlers/`.
```

## Auto memory

Available in v2.1.59+ and **on by default**. Claude writes learnings — build quirks, debugging insights, preferences — to `~/.claude/projects/<project>/memory/MEMORY.md`. The first 200 lines (or 25 KB) of `MEMORY.md` load each session; topic files load on demand.

Toggle it from `/memory`, or set `autoMemoryEnabled: false` in [settings.json](./settings.md).

> [!IMPORTANT]
> CLAUDE.md and auto memory are context, not enforcement. For actions that must happen every time, use a [hook](./hooks.md).

**Source:** [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory)
