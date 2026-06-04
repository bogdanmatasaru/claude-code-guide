# Settings

Starter `settings.json` files for Claude Code. JSON can't hold comments, so the explanations
live here.

| File | Copy to | Scope |
| --- | --- | --- |
| `minimal-settings.json` | `~/.claude/settings.json` | You, across all projects. A tiny safe allowlist for read-only git/inspection commands plus tests/build. |
| `team-settings.json` | `<repo>/.claude/settings.json` | The team, committed to source control. A broader allowlist for a shared repo's test/build/lint commands. |

## What's inside

**`minimal-settings.json`** allows only read-only, non-destructive Bash commands
(`git status/diff/log`, `ls`, `cat`) plus `npm run test`/`build`, and denies reads of `.env`
and `secrets/`. Everything else still prompts.

**`team-settings.json`** adds common dev-loop commands (lint, typecheck, turbo tasks) and a
few write commands (`git add`, `git commit`). It explicitly **denies** dangerous actions
— `git push`, `rm -rf` — and puts `git commit` behind an `ask` so it always confirms.
Keep destructive operations (deploy, force-push) out of `allow` on purpose.

## Precedence (highest wins)

Claude Code merges settings from several layers. On conflict, the higher layer wins —
**except permission rules, which merge across layers, and `deny` always beats `allow`.**

1. **Managed** — system `managed-settings.json` (MDM / org policy). Cannot be overridden.
2. **Local** — `.claude/settings.local.json` (gitignored; just you, this project).
3. **Project** — `.claude/settings.json` (committed; your team).
4. **User** — `~/.claude/settings.json` (just you, all projects).

So: put personal defaults in **user** settings, team defaults in **project** settings, and
machine-specific or secret-adjacent overrides in **local** settings (which is gitignored).

## Tips

- Edit interactively with `/config` (model, theme, output style) or `/permissions`
  (allow / deny / ask rules) instead of hand-editing JSON.
- A bare tool name (e.g. `WebFetch`) matches all uses; `Tool(pattern:*)` scopes it.

See the full reference: [`../../docs/reference/settings.md`](../../docs/reference/settings.md).
