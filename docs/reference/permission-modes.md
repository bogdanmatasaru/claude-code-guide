---
title: Permission modes
description: The six Claude Code permission modes, Shift+Tab cycling, fine-grained allow/deny rules, and protected paths.
---
# Permission modes

Permission modes control how much Claude Code can do without asking. You cycle between the common modes with `Shift+Tab` and fine-tune individual rules with `/permissions`.

## The six modes

| Mode | What it allows |
| --- | --- |
| `default` | Reads only; prompts before edits and commands |
| `acceptEdits` | File edits plus common in-scope filesystem Bash (`mkdir`, `mv`, `cp`, `rm`) without prompting |
| `plan` | Research only — no edits, no side effects |
| `auto` | Everything, gated by a server-side safety classifier |
| `dontAsk` | Only pre-approved tools run; nothing else (for CI) |
| `bypassPermissions` | Skips all permission checks entirely |

> [!NOTE]
> `auto` is a research preview (v2.1.83+) and requires Opus 4.6+ or Sonnet 4.6+. State your provider when relying on model availability — Bedrock/Vertex may resolve to different versions.

## Cycling and setting the default

`Shift+Tab` cycles through the everyday modes: **default → acceptEdits → plan**. To set the mode at launch, use `--permission-mode <mode>`. To set a persistent default, configure `permissions.defaultMode` in your settings:

```json
{
  "permissions": {
    "defaultMode": "plan"
  }
}
```

`bypassPermissions` is reachable via the `--dangerously-skip-permissions` flag.

> [!WARNING]
> `bypassPermissions` / `--dangerously-skip-permissions` removes every safety check. Use it only in fully sandboxed, disposable environments.

## Fine-grained allow/deny rules

Beyond modes, `/permissions` lets you allow or deny specific tool invocations using patterns. This is how you stop repetitive prompts for trusted commands:

```text
Bash(npm run test:*)      # allow any npm test script
Bash(git push:*)          # deny or allow git pushes
Read(./src/**)            # scope reads to a directory
```

Rules live in settings under `permissions.allow` and `permissions.deny`, and `deny` always wins over `allow`. Add a rule once and Claude stops asking for matching calls.

## Protected paths

Certain paths are **never** auto-approved (except under `bypassPermissions`), regardless of mode:

- `.git`
- `.claude`
- Shell rc files (`.bashrc`, `.zshrc`, etc.)
- `.mcp.json`

Edits to these always require explicit confirmation.

## Choosing a mode

| Situation | Mode |
| --- | --- |
| Exploring or asking questions | `default` |
| Designing before touching code | `plan` |
| Actively implementing, want flow | `acceptEdits` |
| Hands-off agentic work, supervised | `auto` |
| Non-interactive CI with a known allowlist | `dontAsk` |
| Throwaway sandbox, maximum speed | `bypassPermissions` |

**Source:** [Permission modes](https://code.claude.com/docs/en/permission-modes)
