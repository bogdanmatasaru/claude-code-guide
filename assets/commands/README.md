# Commands / Skills

Ready-to-use Claude Code skills. Each `.md` here is a self-contained `SKILL.md` with YAML
frontmatter (`name`, `description`, optional `allowed-tools`) and a Markdown body.

| File | Slash command | What it does |
| --- | --- | --- |
| `commit.md` | `/commit` | Stage changes and write a Conventional Commit from the diff (no push). |
| `review-pr.md` | `/review-pr` | Review the current diff for bugs and suggest fixes (read-only). |
| `write-tests.md` | `/write-tests <target>` | Write tests for a file/function and run them. |

## Install

The directory (or file) name becomes the command name: `commit` → `/commit`.

**Personal (all your projects):** copy into `~/.claude/skills/<name>/SKILL.md`

```bash
mkdir -p ~/.claude/skills/commit
cp commit.md ~/.claude/skills/commit/SKILL.md
```

**Project (shared with your team, commit it to the repo):** either layout works —

```bash
# As a skill folder:
mkdir -p .claude/skills/commit && cp commit.md .claude/skills/commit/SKILL.md

# Or as a flat command file (custom commands are merged into skills):
mkdir -p .claude/commands && cp commit.md .claude/commands/commit.md
```

Changes are picked up live — no restart needed. Type `/` in Claude Code to see the command,
or just describe the task and Claude may invoke the skill automatically based on its
`description`.

## Notes

- `allowed-tools` lists tools the skill may use **without** a permission prompt while it's
  active. It does not grant anything destructive — review before installing.
- `$ARGUMENTS` in a body is replaced with whatever you type after the command name.

See the full reference: [`../../docs/reference/skills.md`](../../docs/reference/skills.md).
