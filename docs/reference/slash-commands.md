---
title: Slash commands & prompt prefixes
description: Built-in slash commands, the / @ ! prompt prefixes, custom commands as skills, and MCP prompts.
---
# Slash commands & prompt prefixes

Inside an interactive session, type a prefix as the first character of your input to trigger special behavior. This page covers built-in slash commands, the prompt prefixes, and where custom commands come from.

## Prompt prefixes

| Prefix | Meaning | Example |
| --- | --- | --- |
| `/` | Run a slash command or skill | `/clear` |
| `@` | Mention a file or MCP resource (adds it to context) | `@src/app.ts` |
| `!` | Shell mode — runs the command and adds its output to context | `!git status` |

> [!NOTE]
> To save something to memory, use `/memory` or just ask Claude to remember it. The `#` chat prefix is **not** a memory shortcut.

## Built-in slash commands

| Command | What it does |
| --- | --- |
| `/help` | List commands and basic usage |
| `/init` | Generate a `CLAUDE.md` for the current repo |
| `/clear` | Clear the conversation and free context |
| `/compact` | Summarize and compact the conversation |
| `/context` | Show what's currently in the context window |
| `/model` | Pick the model (see [models & effort](./models-and-effort.md)) |
| `/effort` | Set reasoning effort level |
| `/permissions` | View and edit allow/deny rules (see [permission modes](./permission-modes.md)) |
| `/config` | Open settings (theme, editor/vim mode, and more) |
| `/usage` | Show token and cost usage |
| `/rewind` | Roll back to an earlier point in the session |
| `/resume` | Switch to another session |
| `/doctor` | Run install and config diagnostics |
| `/agents` | Manage subagents |
| `/mcp` | View and manage MCP servers |
| `/memory` | Edit memory files |
| `/code-review` | Review the current changes |
| `/export` | Export the conversation transcript |

This is not the full list — type `/` in a session to see everything available, including commands contributed by plugins.

## Custom commands

Custom slash commands live as **skills**. Define a skill and it becomes invocable with `/` (and, where applicable, automatically by Claude). See [skills](./skills.md) for how to author them.

## MCP prompts

Prompts exposed by MCP servers appear as slash commands namespaced by server:

```text
/mcp__<server>__<prompt>
```

For example, a `github` server exposing a `summarize_pr` prompt is invoked as `/mcp__github__summarize_pr`. Use `/mcp` to inspect connected servers and the prompts they provide.

> [!TIP]
> Combine prefixes with arguments freely — `@` a file, then describe the change you want in the same message.

**Source:** [Slash commands](https://code.claude.com/docs/en/slash-commands) · [Interactive mode](https://code.claude.com/docs/en/interactive-mode)
