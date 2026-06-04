---
title: The context window
description: What the context window is, why Claude Code degrades as it fills, and how /context, /compact, /clear, and subagents keep it lean.
---
# The context window

The context window is Claude Code's **working memory** — everything it can "see" at once: your prompts, the files it has read, command output, and its own previous responses. It's finite, and managing it well is the difference between sharp answers and sluggish, confused ones.

## Why it matters

Every file Claude reads and every command it runs adds to the context window. Two things happen as it fills:

1. **Performance degrades.** The more crowded the context, the harder it is for Claude to focus on what's relevant. Accuracy drops and responses slow down — long before the window is technically "full."
2. **Cost rises.** Larger context means more tokens processed on every turn.

The takeaway: a lean context isn't just cheaper, it makes Claude *better*. Treat context as a resource you actively manage.

## See what's in it: /context

Run this any time to inspect current usage:

```text
/context
```

It shows how much of the window is consumed and by what. Use it when responses start feeling off — bloated context is often the cause.

## /compact vs /clear

Both free up space, but they do different things:

- **`/clear`** wipes the conversation entirely. Start here **between unrelated tasks** — there's no reason to carry the last task's files into the next one.
- **`/compact`** summarizes the conversation so far, preserving the gist while dropping the bulk. Use it **mid-task**, when you still need continuity but the context has grown heavy.

```text
/clear      # done with this task, moving to something new
/compact    # same task continues, but context is getting full
```

> [!NOTE]
> **The prompt-cache nuance.** Claude Code caches your context for about **5 minutes**. Inside that warm window, `/compact` is cheap because most of the conversation is still cached. Outside it (after a long pause), the cache is cold either way — so if you no longer need the history, `/clear` is the cheaper choice. Rule of thumb: compact to *continue* a task, clear to *abandon* one.

## Protect context with subagents

When a task requires reading **many files** — a broad investigation, a wide search — that reading can flood your main context. A **subagent** does the work in its **own** context window and returns only a summary:

```text
use a subagent to find every place we call the payments API and summarize them
```

Your main context stays clean; you get the answer without the clutter. This is one of the most effective ways to take on big investigations without degrading the session.

## A simple routine

- `/clear` between unrelated tasks.
- `/compact` when a long task fills up but you need to keep going.
- `/context` to check before things feel slow.
- **Subagents** for anything that reads a lot of files.

For the full picture on keeping sessions efficient, see [Optimize cost & context](../guides/cost-optimization.md).

**Source:** [Manage cost & context](https://code.claude.com/docs/en/costs)
