# Hooks

Drop-in `hooks` snippets for `settings.json`. Hooks run shell commands at fixed points in
Claude Code's lifecycle — they're **deterministic** (they always run), unlike CLAUDE.md
instructions, which Claude may or may not follow.

| File | Event | What it does |
| --- | --- | --- |
| `format-on-edit.json` | `PostToolUse` | Formats a file with Prettier / Ruff after Claude edits it. |
| `protect-paths.json` | `PreToolUse` | Blocks edits to `.env`, secrets, migrations, and keys (exit 2). |
| `notify-on-stop.json` | `Stop` + `Notification` | macOS desktop notification when Claude finishes or needs you. |

## How to install

Each file contains a top-level `"hooks"` object. **Merge** it into your settings — don't
overwrite the whole file. Paste it into one of:

- `~/.claude/settings.json` — applies to all your projects.
- `.claude/settings.json` — project-scoped; commit it to share with your team.

If you already have a `hooks` key, merge the event arrays (e.g. append to the existing
`PostToolUse` list) rather than replacing them.

These hooks require [`jq`](https://jqlang.github.io/jq/) on your `PATH` (used to read the
JSON payload Claude pipes to the hook on stdin). `notify-on-stop.json` uses macOS
`osascript`; on Linux swap it for `notify-send`.

## Exit-code semantics

A command hook reports its result through its exit code:

| Exit code | Meaning |
| --- | --- |
| `0` | Success. `stdout` is parsed as JSON if present. |
| `2` | **Block.** The tool call is cancelled; `stderr` is shown to Claude as feedback. Only blocking events (e.g. `PreToolUse`, `UserPromptSubmit`, `Stop`) honor this. |
| other | Non-blocking error; `stderr` goes to the debug log, the action proceeds. |

`format-on-edit.json` always `exit 0` so a formatter failure never blocks your work.
`protect-paths.json` uses `exit 2` to cancel the write before it happens.

## Safety

Hooks run with your shell's privileges. Read any hook before adding it. These three are
intentionally conservative: the formatter never blocks, the guardrail only blocks (never
deletes or modifies), and the notifier only displays a message.

See the full reference: [`../../docs/reference/hooks.md`](../../docs/reference/hooks.md).
