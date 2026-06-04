---
title: Hooks
description: Deterministic automation in Claude Code — events, settings.json shape, and worked format-on-edit and guardrail examples.
---
# Hooks

Hooks run shell commands at fixed points in Claude Code's lifecycle. Unlike CLAUDE.md instructions, which Claude *may* follow, hooks are **deterministic** — they execute every time, regardless of what the model decides. Use them when something must always happen: format after an edit, block writes to a protected path, validate a prompt.

## Shape in settings.json

Hooks live under the `hooks` key, grouped by event, each with a `matcher` and a list of handlers:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "prettier --write \"$file\"", "timeout": 30 }
        ]
      }
    ]
  }
}
```

The `command` handler is the most common. Other handler types exist (`http`, `prompt`, `agent`, `mcp_tool`); verify the current set in the docs before relying on them.

## Events

| Event | Fires when | Can block? |
| --- | --- | --- |
| `PreToolUse` | Before a tool runs | Yes |
| `PostToolUse` | After a tool succeeds | No |
| `UserPromptSubmit` | You submit a prompt | Yes |
| `SessionStart` | Session begins (`startup` / `resume` / `clear` / `compact`) | No |
| `SessionEnd` | Session ends | No |
| `Stop` | Claude finishes responding | Yes |
| `SubagentStop` | A subagent finishes | Yes |
| `PreCompact` | Before context compaction (`manual` / `auto`) | Yes |
| `Notification` | Claude emits a notification | No |

> [!NOTE]
> Claude Code defines additional events beyond these core ones. Check the latest docs for the full table and which events support blocking.

### Matchers

For tool events, `matcher` filters by tool name: `Bash`, `Edit|Write` (pipe-separated), `mcp__.*` (regex). MCP tools are named `mcp__<server>__<tool>`. A `"*"`, `""`, or omitted matcher fires on every occurrence. Non-tool events match other sources — e.g. `SessionStart` matches `startup` / `resume` / `clear` / `compact`.

## Exit codes

A command hook signals its result through its exit code. The exact effect depends on
whether the event **can block** (see the table above):

| Exit code | Meaning |
| --- | --- |
| `0` | Success. On `UserPromptSubmit` and `SessionStart`, `stdout` is added to Claude's context; for other events `stdout` goes to the debug log. |
| `2` | **Block** — but only on blocking-capable events (e.g. `PreToolUse`, `Stop`). `stderr` is fed back to Claude. On non-blocking events like `PostToolUse` the action already ran, so exit `2` doesn't undo it; `stderr` is shown to Claude as context. |
| other | Non-blocking error; `stderr` goes to the debug log. |

> [!NOTE]
> A hook can also return structured JSON on stdout (exit `0`) for finer control. The fields and which events honor them are documented at the source below — check it before relying on a specific behavior.

## Example: format on edit

Run a formatter automatically after every `Edit` or `Write`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs -r prettier --write",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

The hook receives a JSON payload on `stdin`; here `jq` extracts the edited file path and pipes it to `prettier`.

## Example: guardrail with exit code 2

Block edits to a protected path before they happen. Save as `guard.sh`:

```bash
#!/usr/bin/env bash
path=$(jq -r '.tool_input.file_path')
if [[ "$path" == *".env"* ]]; then
  echo "Refusing to modify secret file: $path" >&2
  exit 2   # blocks the tool call; stderr is shown to Claude
fi
exit 0
```

Wire it to `PreToolUse`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "$CLAUDE_PROJECT_DIR/guard.sh" }
        ]
      }
    ]
  }
}
```

Because `PreToolUse` can block, exiting `2` cancels the edit and tells Claude why.

> [!TIP]
> Hooks are configured in [settings.json](./settings.md), so they follow the same scope precedence. Ready-made hook scripts live in [`assets/hooks/`](https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets/hooks).

> [!WARNING]
> Hooks run with your shell's privileges. Review any hook before adding it, especially from untrusted sources.

**Source:** [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks)
