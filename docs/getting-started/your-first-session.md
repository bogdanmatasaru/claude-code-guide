---
title: Your first real session
description: Learn the prefixes, permission modes, /init, and the explore-plan-code-commit loop that make Claude Code productive on real work.
---
# Your first real session

The quickstart got you a quick win. This page turns that into a repeatable workflow you'll use every day: the prefixes, permission modes, and the loop that keeps Claude on track.

## The three prefixes

Most of the time you just type in plain English. Three prefixes give you shortcuts:

- `/` runs a **command** — `/help`, `/init`, `/clear`, `/login`, and more. Type `/` alone to browse the list.
- `@` references a **file or directory** — `@src/api/auth.ts` pulls that file into context directly.
- `!` runs a **shell command** and feeds the output to Claude — `!git status`, `!npm test`.

> [!TIP]
> Use `@` when you already know which file matters. It saves Claude a search and keeps context focused.

## Permission modes

Press `Shift+Tab` to cycle through three modes. The footer shows the current one:

- **default** — Claude asks before each edit or command. Safest; best while you're learning.
- **acceptEdits** — auto-applies file edits but still confirms riskier actions. Good once you trust the task.
- **plan** — investigates and proposes, but makes **no changes**. Best for non-trivial or multi-file work.

A good rule: reach for **plan mode** whenever you can't describe the change in a single sentence.

## Set up project memory with /init

Run this once per project:

```text
/init
```

`/init` scans the repo and generates a **CLAUDE.md** file — durable notes about your stack, conventions, and commands that Claude reads automatically every session. Edit it over time to record anything you find yourself repeating. See [../reference/](../reference/) for the full CLAUDE.md reference.

## The core loop: explore → plan → code → commit

Real tasks go best in this order:

1. **Explore** — let Claude read the relevant code first. Ask questions, drop in `@files`. Don't rush to edits.
2. **Plan** — in plan mode, have it propose an approach. Refine the plan in chat until it's right. Fixing a plan is far cheaper than fixing code.
3. **Code** — approve the plan and let Claude implement it.
4. **Commit** — ask it to commit with a clear message once you're satisfied.

The single biggest lever: **give Claude a way to verify its own work.** Point it at a test suite, a build command, or a screenshot to check against:

```text
implement this, then run npm test and fix anything that fails
```

With a verifiable target, Claude self-corrects in a loop instead of guessing.

## Course-correct without starting over

- **Esc** interrupts Claude mid-action — use it the moment it goes the wrong way.
- **Esc Esc** rewinds the conversation so you can edit an earlier message and branch from there.
- If you've corrected Claude **two or more times** on the same point, stop. Run `/clear` and rewrite your prompt from scratch — it's faster than digging out of a confused thread.

## /clear discipline

Each task should start with a clean slate:

```text
/clear
```

Run it between unrelated tasks. A lean context keeps Claude sharp; a cluttered one makes it slower and less accurate. (More on why in [../explanation/context-window.md](../explanation/context-window.md).)

## Where to go next

- Task-focused walkthroughs: [../guides/](../guides/)
- Commands, flags, and config: [../reference/](../reference/)

**Source:** https://code.claude.com/docs/en/quickstart
