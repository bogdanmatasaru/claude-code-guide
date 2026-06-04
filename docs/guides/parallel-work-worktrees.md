---
title: Work in parallel with git worktrees
description: Run multiple isolated Claude Code sessions at once using git worktrees — no conflicts, and a clean tree during investigation.
---
# Work in parallel with git worktrees

Git worktrees give each Claude Code session its own checkout and branch. The files on disk are completely isolated, so two sessions can run at full speed with no conflicts. The under-appreciated win is protecting your working tree during read-heavy investigation.

## The recipe

1. **Start a session in its own worktree** with `claude --worktree`.
2. **Run several worktree sessions in parallel**, one task each.
3. **Use a worktree for investigation** so your main tree stays clean.

## Step 1 — One session, one worktree

Launch Claude in a fresh worktree and branch:

```
claude --worktree
# short form:
claude -w
```

This creates an isolated checkout on its own branch. Anything Claude does — edits, builds, generated files — lives in that worktree, not your primary checkout. When the work is done, you merge the branch like any other.

## Step 2 — Run tasks in parallel

The point of worktrees is true parallelism. Open multiple terminals, each with its own worktree session, each scoped to one job:

- Terminal A — `claude -w` implementing the new export endpoint.
- Terminal B — `claude -w` upgrading the test framework.
- Terminal C — `claude -w` chasing a flaky integration test.

Because the files on disk are completely isolated, there are no conflicts between sessions. Each runs its own builds and tests without stepping on the others.

> [!TIP]
> Keep each worktree to a single, unrelated task — the same discipline as `/clear` between tasks, but enforced by the filesystem. Mixing tasks in one worktree recreates the kitchen-sink-session problem.

## Step 3 — The read-heavy investigation win

The most underrated use isn't parallel writing — it's isolation during investigation. When you ask Claude to explore, trace, or experiment across the codebase, a worktree guarantees nothing it does leaks into your real working tree:

> Spin up in a worktree and investigate why the cache invalidation is racing. Read widely, run experiments, scribble throwaway scratch code if it helps — I'll throw this branch away afterward.

You get a sandbox to think in. When you're done, delete the branch and your main checkout is exactly as you left it — no stray files, no half-applied edits, no `git stash` juggling.

> [!NOTE]
> Worktrees pair naturally with [subagents](../reference/subagents.md): subagents isolate *context* within one session, while worktrees isolate *files* across sessions. Use subagents to parallelize research inside a task; use worktrees to parallelize whole tasks.

## Practical tips

- **Name branches per task** so the parallel sessions stay legible in `git worktree list`.
- **Don't share build caches** that assume a single checkout (e.g. some `node_modules` or target-dir setups) — let each worktree have its own.
- **Merge or discard promptly.** Long-lived worktrees drift; finish the task, merge, and remove the worktree.
- **Match the model to the task.** A worktree doing an architecture-heavy change may warrant Opus while a routine one runs on Sonnet — choose per session.

## Why this works

The guarantee is mechanical: separate working directories mean separate files, so concurrent sessions cannot collide. That removes the main friction of running more than one Claude at once and makes it safe to let an investigative session roam without worrying about your real tree.

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices); community practice.
