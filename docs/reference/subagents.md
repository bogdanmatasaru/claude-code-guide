---
title: Subagents
description: Delegate focused work to subagents that run in their own context window and report back only a summary.
---
# Subagents

A subagent is a specialized assistant that handles a side task in its own context window and returns only a summary. Use one when work would otherwise flood your main conversation with search results, logs, or file contents you'll never reference again.

Each subagent runs with its own system prompt, tool access, and permissions. Claude reads each subagent's `description` to decide when to delegate. This keeps the main conversation lean while the subagent does the heavy reading.

## Definition format

Subagents are Markdown files with YAML frontmatter in `.claude/agents/` (project) or `~/.claude/agents/` (user). You can also pass them inline with the `--agents` JSON flag. Manage them with `/agents`.

```markdown
---
name: auth-investigator
description: Investigates how authentication works. Use when tracing auth, sessions, or token logic.
tools: Read, Grep, Glob
model: haiku
---

You are a codebase investigator. Trace the requested auth flow across files
and report a concise summary with file paths and line references. Do not edit.
```

| Field | Required | Purpose |
| --- | --- | --- |
| `name` | Yes | Identifier used to invoke and reference the subagent. |
| `description` | Yes | When Claude should delegate to it. |
| `tools` | No | Tools it may use. Inherits all if omitted. |
| `model` | No | `sonnet`, `opus`, `haiku`, a full model ID, or `inherit`. Defaults to `inherit`. |
| `permissionMode` | No | `default`, `acceptEdits`, `plan`, `bypassPermissions`, etc. |
| `isolation` | No | `worktree` runs it in a temporary git worktree with an isolated copy of the repo. |
| `color` | No | Display color in the task list and transcript. |

## Built-in subagents

| Subagent | Tools | Use for |
| --- | --- | --- |
| **Explore** | Read-only | Searching and understanding a codebase without changing it. |
| **Plan** | Read-only | Research during plan mode before presenting a plan. |
| **general-purpose** | All tools | Tasks needing both exploration and edits, or multi-step reasoning. |

Explore and Plan skip CLAUDE.md and git status to stay fast and cheap; other subagents load both.

## When to use one

Reach for a subagent when the task reads many files or needs isolated focus and you only care about the conclusion:

```text
Use a subagent to investigate how auth handles token refresh.
```

The subagent burns its own context on the search and hands back a short report. Your main thread stays focused on the change you're making.

## Adversarial review

A powerful pattern: run a reviewer in a **fresh subagent** that sees only the diff plus the review criteria — not the reasoning that produced the change. Without that context it can't rationalize the author's choices, so it catches issues the original thread would wave through.

```text
Spawn a reviewer subagent. Give it only the diff and these criteria:
correctness, error handling, missing tests. Report findings, nothing else.
```

## The one limit: no nesting

Subagents cannot spawn subagents. Delegation is one level deep — this prevents infinite nesting. In plan mode, the Plan subagent does the research precisely so the main thread (not a nested agent) keeps control.

> [!TIP]
> Route cheap, bulky work to a faster model with `model: haiku` to cut cost without slowing the main conversation.

Related: define reusable procedures as [skills](./skills.md) and have subagents run them.

**Source:** [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)
