# Asset library

Copy-paste, ready-to-use files you can drop into your own projects. Everything here is
safe by default — no destructive actions are ever auto-approved.

| Folder | What's inside | Drop it into |
|---|---|---|
| [`claude-md/`](claude-md/) | `CLAUDE.md` starter templates (Node, Python, monorepo, minimal) | your repo root as `CLAUDE.md` |
| [`commands/`](commands/) | Slash-command skills (commit, review-pr, write-tests) | `~/.claude/skills/<name>/SKILL.md` |
| [`hooks/`](hooks/) | Hook snippets (format-on-edit, protect-paths, notify-on-stop) | your `settings.json` `hooks` block |
| [`settings/`](settings/) | `settings.json` examples (minimal, team) | `~/.claude/settings.json` or `.claude/settings.json` |
| [`skills/`](skills/) | Full shareable skills (e.g. project-onboard) | `~/.claude/skills/<name>/` |
| [`statusline/`](statusline/) | A cost / rate-limit / branch status line | `~/.claude` + `~/.config/ccstatusline/` |

Each folder has its own `README.md` with install instructions.

## How to use

1. Pick the asset you need and read the folder's `README.md`.
2. Copy it to the location in the table above.
3. For skills/commands, the directory name becomes the `/command-name`.

New to these concepts? See [Skills](../docs/reference/skills.md),
[Hooks](../docs/reference/hooks.md), [settings.json](../docs/reference/settings.md),
and [CLAUDE.md & memory](../docs/reference/claude-md.md).

> Contributions welcome — got a template, command, or hook you use? See
> [CONTRIBUTING.md](../CONTRIBUTING.md).
