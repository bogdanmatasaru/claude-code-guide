---
title: When to use what
description: A decision guide for Claude Code — plan mode vs not, subagents, skills vs commands vs hooks vs MCP, model selection, and /clear vs /compact.
---
# When to use what

Claude Code gives you many levers. This page is a quick decision guide so you reach for the right one without overthinking it.

## Plan mode vs. just doing it

- **Use plan mode** for non-trivial or multi-file tasks — anything where you'd want to review the approach before code is written.
- **Skip it** when you can describe the diff in a single sentence ("add a docstring to `main`"). Planning a trivial change just adds friction.

Rule of thumb: if you can't say exactly what the change is in one breath, plan it first.

## Subagent vs. inline

- **Subagent** when a task reads **many files** or you want to protect your main context. The subagent investigates in its own context window and returns a summary. See [Subagents](../reference/subagents.md).
- **Inline** (just ask in the main session) for focused work where you want to see and steer every step.

## Skill vs. command vs. hook vs. MCP

These look similar but solve different problems:

| Mechanism | Use when… | Trigger |
| --- | --- | --- |
| **Skill** | a capability is **sometimes relevant** and reusable | loads when the task matches |
| **Command** | you want a **named shortcut** you invoke on demand | you type `/name` |
| **Hook** | something must happen **every time**, deterministically | fires automatically on an event |
| **MCP** | you need to **connect an external tool** (database, API, service) | available once configured |

- **Use a skill when** you have know-how that applies now and then — a testing convention, a deploy procedure — and you want Claude to pull it in automatically.
- **Use a command when** you want to trigger something yourself by name.
- **Use a hook when** the action is non-negotiable: format on every edit, block commits to `main`, log every tool call.
- **Use MCP when** Claude needs to reach a system it can't touch with files and shell — but keep your MCP set **lean**, since each server adds context and surface area.

See the reference pages for each: [Skills](../reference/skills.md), [Hooks](../reference/hooks.md), [MCP](../reference/mcp.md).

## Model selection by task

- **Sonnet** — your default. Handles roughly **80%** of work: features, refactors, bug fixes, tests.
- **Opus** — reach for it on **hard multi-file work, architecture decisions, and tricky bugs** where deeper reasoning pays off.
- **Haiku** — for **trivial** tasks: quick edits, simple lookups, mechanical changes where speed matters most.

Start on Sonnet. Step up to Opus when a task is genuinely hard; drop to Haiku when it's genuinely simple.

## /clear vs. /compact

- **`/clear`** between **unrelated** tasks — start each task with clean working memory.
- **`/compact`** mid-task when context grows heavy but you still need continuity.

And one more reset worth memorizing: if you've **corrected Claude two or more times** on the same point, stop fighting the thread. Run `/clear` and **rewrite the prompt** from scratch — a clean start beats a confused one. (Why context hygiene matters: [./context-window.md](./context-window.md).)

## At a glance

- One-sentence change → just do it. Otherwise → **plan mode**.
- Reads many files → **subagent**.
- Sometimes-relevant know-how → **skill**. Must happen every time → **hook**. External system → **MCP**.
- Default to **Sonnet**; **Opus** for hard, **Haiku** for trivial.
- New task → **/clear**. Long task filling up → **/compact**.

**Source:** https://code.claude.com/docs/en/overview
