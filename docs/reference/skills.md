---
title: Skills
description: Author SKILL.md files to extend Claude Code — auto-invoked or run as slash commands, with dynamic context and arguments.
---
# Skills

A skill is a folder with a `SKILL.md` file that teaches Claude Code a procedure or body of knowledge. Claude applies it automatically when it's relevant, or you invoke it by hand with `/skill-name`.

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, so the same `SKILL.md` works across tools. Custom commands have been merged into skills: an existing `.claude/commands/deploy.md` and a `.claude/skills/deploy/SKILL.md` both create `/deploy`.

## SKILL.md format

The directory name becomes the command name (`deploy/` → `/deploy`). Each file is YAML frontmatter plus a Markdown body. Only `description` is required.

```markdown
---
description: Run our release checklist and tag a version. Use when cutting a release.
allowed-tools: Bash(git tag *), Bash(git push *)
---

# Release

1. Confirm the working tree is clean.
2. Bump the version in `package.json`.
3. Tag and push: `git tag v$ARGUMENTS && git push --tags`.
```

| Field | Required | Purpose |
| --- | --- | --- |
| `description` | Yes | What the skill does and when to use it. Claude reads this to decide auto-invocation. |
| `disable-model-invocation` | No | `true` means only you can trigger it with `/name`. Default `false`. |
| `allowed-tools` | No | Tools Claude may use without prompting while the skill is active. Does not restrict other tools. |

> [!NOTE]
> Changes are detected live — edit a `SKILL.md` and the new version applies on the next turn. No restart needed.

## Arguments and dynamic context

The body can pull in live data and user input before Claude ever sees it:

- `$ARGUMENTS` expands to everything typed after the command. `$0`, `$1`, … access positional args.
- `` !`command` `` runs a shell command and inlines its output. Example: `` !`git diff HEAD` `` injects the current diff.

```markdown
---
description: Summarize a pull request from live GitHub data.
allowed-tools: Bash(gh *)
---

Summarize this PR for the changelog:

!`gh pr diff $ARGUMENTS`
```

## Locations

| Scope | Path |
| --- | --- |
| Personal | `~/.claude/skills/<name>/SKILL.md` |
| Project | `.claude/skills/<name>/SKILL.md` (commit to share with the team) |
| Plugin | `<plugin>/skills/<name>/SKILL.md` (invoked namespaced as `/plugin:skill`) |

## Auto-invocation vs manual

By default a skill is **model-invoked**: Claude reads the `description`, and when a task matches, it loads the body and applies it — no command needed. Write descriptions that name the trigger ("Use when reviewing a PR").

Set `disable-model-invocation: true` for **manual-only** skills. Use it for side-effecting workflows — `/commit`, `/deploy`, `/send-slack` — where you don't want Claude deciding to act on its own.

| Setting | Auto-invoked | Manual `/name` | In context |
| --- | --- | --- | --- |
| (default) | Yes | Yes | `description` always loaded; body loads on use |
| `disable-model-invocation: true` | No | Yes | Body loads only when you invoke |

## Skill vs slash command vs CLAUDE.md

- **Skill beats a slash command** when it should fire *autonomously* based on context. A plain command only runs when you type it; a skill can do both.
- **Skill beats CLAUDE.md** for knowledge that's *only relevant sometimes*. CLAUDE.md loads on every turn and costs context continuously. A skill's body loads only when used, so long reference material is free until needed. Move a CLAUDE.md section into a skill once it grows from a fact into a procedure.

## Bundled skills

Claude Code ships several: `/code-review`, `/debug`, `/loop`, `/run`, `/verify`.

See ready-to-copy examples in [`assets/commands/`](https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets/commands) and [`assets/skills/`](https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets/skills), plus the workflow [guides](../guides/onboard-a-codebase.md).

**Source:** [code.claude.com/docs/en/skills](https://code.claude.com/docs/en/skills)
