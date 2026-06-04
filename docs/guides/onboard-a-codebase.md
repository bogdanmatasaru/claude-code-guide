---
title: Onboard to a new codebase
description: Use Claude Code to understand an unfamiliar repo fast — explore, ask senior-engineer questions, and generate a CLAUDE.md.
---
# Onboard to a new codebase

Dropping into an unfamiliar repo is the task Claude Code is best at. Treat it like a senior engineer who has already read every file: explore first, ask sharp questions, then capture what you learn in a `CLAUDE.md`.

## The recipe

1. **Explore without editing.** Press `Shift+Tab` to enter plan mode so Claude reads and answers but cannot touch files. This keeps the first session read-only and safe.
2. **Map the codebase at a high level.** Ask for the lay of the land before drilling in.
3. **Ask the questions you'd ask a senior engineer.** Logging, auth, data flow, why a specific line exists, the edge cases that bite newcomers.
4. **Delegate the legwork to subagents.** Parallel investigation keeps your main context clean.
5. **Generate a `CLAUDE.md` with `/init`** so the next session starts with shared knowledge.

## Step 1 — Get the map

In plan mode, paste:

> Give me a high-level tour of this repository. What are the main entry points, the major modules, and how do they fit together? Where does a request enter and where does it exit? Keep it to a one-page overview, then list the five files I should read first.

This gives you a mental model before you spend tokens on detail.

## Step 2 — Ask senior-engineer questions

The fastest way to ramp is to interrogate the code the way you'd interrogate a teammate. Real prompts to paste:

> How does logging work in this service? Where is it configured, and what's the convention for adding a new log line?

> Walk me through what happens when a user signs in, from the HTTP handler down to the database. Name the files and functions in order.

> Why does `src/billing/invoice.ts:333` call `reconcile()` before saving? What breaks if I remove it?

> What are the non-obvious edge cases or gotchas a new engineer trips over in this codebase?

Claude reads the actual code to answer, so you get grounded answers, not guesses — but verify anything load-bearing against the source it cites.

## Step 3 — Delegate research to subagents

For a large repo, fan out investigation so each thread does focused reading and reports back a summary. This protects your main session from filling up with raw file dumps.

> Use subagents to investigate in parallel: one maps the data layer and its migrations, one maps the API routes and middleware, one maps the test setup and CI. Have each report a short summary, then synthesize the three into an architecture overview.

See [Subagents](../reference/subagents.md) for how delegation and isolated context windows work.

## Step 4 — Capture it in CLAUDE.md

Once you understand the shape of the project, run:

```
/init
```

`/init` scaffolds a `CLAUDE.md` documenting the codebase — build/test commands, architecture notes, and conventions — that every future session reads automatically.

> [!TIP]
> Keep `CLAUDE.md` lean. A bloated file causes Claude to ignore your instructions. Capture the handful of things that change behavior (how to run tests, where the core logic lives, project-specific conventions) and cut the rest. See [CLAUDE.md](../reference/claude-md.md).

After `/init`, review the generated file and prune anything Claude could trivially rediscover.

## Why this works

Anthropic's best practices recommend exploring before acting and giving Claude room to read the codebase first. Onboarding is the pure read phase of that loop — no edits, just understanding — which is exactly when plan mode and subagent delegation pay off most.

> [!NOTE]
> Start a fresh session (`/clear`) before you begin actual feature work. Onboarding fills the context with exploratory detail you no longer need; the `CLAUDE.md` you generated carries the durable knowledge forward.

**Related:** [Cheatsheet](../cheatsheet.md) · [Best practices](../best-practices.md) · [Learning path](../learning-path.md)

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices); community practice.
