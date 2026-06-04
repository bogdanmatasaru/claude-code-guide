---
title: settings.json
description: How Claude Code resolves settings.json across scopes, the keys that matter most, and permission rule syntax.
---
# settings.json

`settings.json` configures Claude Code's behavior — permissions, environment, model, hooks, and more. The same keys work at every scope; what changes is precedence.

## Precedence

Claude Code reads settings from five layers. Higher layers win on conflict. Permission rules are the exception: they **merge** across scopes rather than override, with `deny` taking precedence.

| Priority | Layer | Location | Shared with |
| --- | --- | --- | --- |
| 1 (highest) | Managed | System `managed-settings.json` (MDM/policy) | Whole organization |
| 2 | `--settings` flag | Path passed on the CLI | Current session |
| 3 | Local | `.claude/settings.local.json` (gitignored) | Just you (this project) |
| 4 | Project | `.claude/settings.json` | Team, via source control |
| 5 (lowest) | User | `~/.claude/settings.json` | Just you (all projects) |

> [!NOTE]
> Managed settings cannot be overridden by any other layer. Use them for organization-wide enforcement.

## Key settings

```json
{
  "model": "claude-opus-4-8",
  "outputStyle": "Explanatory",
  "includeCoAuthoredBy": true,
  "autoMemoryEnabled": true,
  "env": {
    "NODE_ENV": "development"
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": ["Bash(npm run test:*)"],
    "deny": ["Read(./.env)", "Read(./.env.*)"],
    "additionalDirectories": ["../shared-lib"]
  }
}
```

| Key | Purpose |
| --- | --- |
| `permissions` | `allow` / `deny` / `ask` rules, `defaultMode`, `additionalDirectories` |
| `env` | Environment variables exported to every command and hook |
| `hooks` | Lifecycle automation — see [Hooks](./hooks.md) |
| `model` | Default model for the session |
| `availableModels` | Models offered in the picker |
| `effortLevel` | Reasoning effort level |
| `outputStyle` | Active output style — see [Output styles](./output-styles.md) |
| `autoMemoryEnabled` | Toggle auto memory — see [CLAUDE.md & memory](./claude-md.md) |
| `includeCoAuthoredBy` | Add the Claude co-author trailer to commits |
| `autoUpdatesChannel` | Which release channel to auto-update from |

> [!NOTE]
> Claude Code ships many more keys (e.g. `statusLine`, `claudeMdExcludes`, `autoMemoryDirectory`). Check the official reference for the full, current list.

## Permission rule syntax

Rules take the form `Tool(pattern)`:

```text
Bash(npm run test:*)     # any command starting with "npm run test"
Read(./.env)             # exact path
Read(./secrets/**)       # everything under secrets/
Edit(src/**)             # any file under src/
```

- `*` matches a single path segment; `**` matches multiple segments.
- A bare tool name (e.g. `WebFetch`) applies to all uses of that tool.
- `deny` always wins over `allow`; rules from all scopes are combined.

For interactive permission flow control, see [Permission modes](./permission-modes.md).

## `/config` and `/permissions`

- `/config` opens an interactive panel to edit common settings (model, output style, theme). Selections save to the appropriate `settings.json`.
- `/permissions` opens a dedicated panel to review and edit `allow` / `deny` / `ask` rules without hand-editing JSON.

Both write to the same files described above, so changes persist across sessions.

> [!TIP]
> Commit `.claude/settings.json` for team-wide defaults and keep machine-specific or secret-adjacent overrides in `.claude/settings.local.json` (gitignored).

**Source:** [code.claude.com/docs/en/settings](https://code.claude.com/docs/en/settings)
