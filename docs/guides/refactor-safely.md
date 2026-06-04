---
title: Refactor safely
description: Refactor with Claude Code without breaking things — tests as a safety net, plan mode, narrow scope, and a reviewed diff.
---
# Refactor safely

Refactoring is where Claude Code is both powerful and dangerous: it can touch many files fast. The safety comes from a test safety net, a tight scope, and reviewing the diff — not from trust.

## The recipe

1. **Establish a safety net** — confirm tests pass before you start.
2. **Scope the change narrowly.** One refactor, clearly bounded.
3. **Plan before editing** with plan mode.
4. **Use subagents to investigate** the blast radius first.
5. **Apply, then review the diff** — run `/code-review`.

## Step 1 — Confirm the safety net

A refactor preserves behavior, so behavior must be observable:

> Run the test suite and show me it's green before we change anything. If coverage is thin around the code I'm about to refactor, list the gaps so I can decide whether to add tests first.

> [!IMPORTANT]
> If the area has no tests, add them *before* refactoring. Tests are the safety net that lets you walk away from the session instead of babysitting it. Without them, a behavior-preserving refactor is unverifiable.

## Step 2 — Scope it narrowly

Vague scope produces sprawling diffs. Bound the change explicitly:

> Refactor `PaymentProcessor` to extract the retry logic into a separate `RetryPolicy` class. Only touch `src/billing/`. Do not change public APIs, rename other things, or reformat unrelated code. Behavior must stay identical — the existing tests must still pass.

State what's out of scope as clearly as what's in.

## Step 3 — Plan before editing

Press `Shift+Tab` to enter plan mode and ask for the approach in writing:

> In plan mode: outline how you'd extract `RetryPolicy` — which methods move, what the new interface looks like, and which call sites change. Don't edit yet.

Read the plan, push back, then let it implement.

> [!TIP]
> Don't over-plan. If you could describe the diff in one sentence — "rename `getUser` to `fetchUser` everywhere" — skip the plan and just do it.

## Step 4 — Investigate the blast radius with subagents

Before changing a widely-used symbol, find every caller:

> Use a subagent to find all call sites of `PaymentProcessor.retry` and how each one depends on its current behavior. Report back before changing anything.

Delegating this keeps your main context focused on the change itself rather than a wall of search results.

## Step 5 — Apply, then review the diff

After the edits land:

> Run the full test suite and the build. Then show me the complete diff, grouped by file, and call out anything that changes observable behavior.

Then run a structured review:

```
/code-review
```

`/code-review` examines the working diff for correctness bugs and cleanup opportunities. Read it critically — you own the merge, not Claude.

## Anti-patterns to avoid

- **Refactoring without tests.** You have no way to know behavior was preserved.
- **Letting scope creep.** "While you're in there, also…" turns a reviewable diff into an unreviewable one. Keep unrelated changes in separate sessions and `/clear` between them.
- **Correcting more than twice.** If Claude drifts off-target two corrections in a row, the context is cluttered. `/clear`, tighten the prompt, and restart rather than fighting it.
- **Shipping an unreviewed diff.** A green suite is necessary, not sufficient — read the change.

## Why this works

Anthropic's best practices for refactoring: scope narrowly, lean on tests as the safety net, investigate before changing, and review the result. Plan mode enforces the read-before-write order; subagents keep investigation out of your main thread; the diff review is the final gate.

**Related:** [Cheatsheet](../cheatsheet.md) · [Best practices](../best-practices.md) · [Learning path](../learning-path.md)

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices); community practice.
