---
title: How Claude Code works
description: The mental model behind Claude Code — the agent loop, its tools, why verifiable targets matter, and how CLAUDE.md, skills, subagents, and hooks fit in.
---
# How Claude Code works

Claude Code isn't autocomplete. It's an **agent**: it reads your files, runs commands, and edits code in a loop until the task is done. Understanding that loop is the key to getting good results.

## The agent loop

Every task runs through the same cycle:

1. **Observe** — Claude reads context: your prompt, relevant files, command output.
2. **Decide** — it picks the next action (search, read a file, run a test, make an edit).
3. **Act** — it uses a tool to take that action.
4. **Repeat** — it observes the result and loops, until the goal is met or it needs your input.

You're not asking a question and getting one answer. You're handing a goal to something that will take many small steps to reach it.

## Its tools

Claude reaches the world through a fixed set of built-in tools: read and edit files, search the codebase, run shell commands, fetch web pages, and spawn subagents. It chooses which to use at each step. This is why it can find code you didn't point it at, run your test suite, and react to the output — all without you wiring anything up.

## Why verifiable targets matter

Because Claude acts in a loop, it can **check its own work** — but only if you give it something to check against. A test suite, a build command, a type checker, or a screenshot turns guessing into self-correction:

```text
add the feature, then run the test suite and fix failures until it's green
```

With a verifiable target, each loop iteration moves closer to correct. Without one, Claude writes plausible code and stops, with no signal about whether it actually works. **This is the highest-leverage habit in all of Claude Code.**

## The context window

Everything Claude knows in a session lives in its **context window** — its working memory. It's finite, and performance degrades as it fills. Keeping context lean (clearing between tasks, compacting mid-task) is central to good results. See [the context window](./context-window.md) for the details.

## The customization layers

Four mechanisms let you shape how Claude behaves, each for a different need:

- **CLAUDE.md** — durable project facts (stack, conventions, commands) that load automatically every session. Your project's memory. See [CLAUDE.md & memory](../reference/claude-md.md).
- **Skills** — reusable capabilities that load **when relevant** to the task at hand. Good for "sometimes you need this" know-how. See [Skills](../reference/skills.md).
- **Subagents** — isolated helpers that investigate in their **own context window** and report back a summary, protecting your main context from clutter. Ideal for tasks that read many files. See [Subagents](../reference/subagents.md).
- **Hooks** — shell commands that run **automatically** on specific events (before an edit, after a tool runs). Use these when something must happen *every time*, deterministically. See [Hooks](../reference/hooks.md).

A simple way to remember the difference: CLAUDE.md is *always* loaded, a skill is loaded *when relevant*, a subagent runs in *isolation*, and a hook runs *every time* — guaranteed.

## Putting it together

The loop does the work; the layers shape it. Give Claude a clear goal, a lean context, and a way to verify itself, and it behaves like a capable colleague rather than a fancy autocomplete.

**Source:** [How Claude Code works](https://code.claude.com/docs/en/how-claude-code-works)
