---
title: Fix a bug from a stack trace
description: Turn an error and stack trace into a root-cause fix — locate, reproduce with a failing test, fix, and verify.
---
# Fix a bug from a stack trace

A stack trace is the best prompt you have. Paste it, point Claude at the likely area, and insist on a failing test before any fix — so you fix the root cause instead of suppressing the symptom.

## The recipe

1. **Paste the raw error and stack trace.** Don't summarize it.
2. **Point at the suspected area** so Claude doesn't search blindly.
3. **Demand a failing test that reproduces the bug** first.
4. **Fix the root cause**, not the symptom.
5. **Verify** the new test passes and nothing else broke.

## Step 1 — Paste and aim

Give Claude the exact output plus a hint about where to look:

> Here's a production error:
>
> ```
> TypeError: Cannot read properties of null (reading 'expiresAt')
>     at refreshSession (src/auth/token.ts:88)
>     at handleRequest (src/server/middleware.ts:42)
> ```
>
> Check `src/auth/`, especially the token-refresh path. Find the root cause. Don't fix anything yet — explain what's going wrong and why.

Aiming Claude at `src/auth/` saves tokens and avoids a scattershot search. A vague prompt can cost 50k+ extra tokens chasing the wrong files.

## Step 2 — Reproduce with a failing test

This is the step that separates a real fix from a guess:

> Write a failing test that reproduces this bug. Run it and show me it fails for the same reason as the stack trace. Don't change the source yet.

A failing test is your verifiable check — the difference between a session you watch and one you walk away from. If Claude can't make the test fail the same way, it hasn't understood the bug yet.

## Step 3 — Fix the root cause

> Now fix the root cause so the test passes. Don't catch-and-ignore the null, and don't loosen the type — explain why the value is null in the first place and fix that.

> [!WARNING]
> Watch for symptom suppression: wrapping the call in a try/catch, adding an `if (x == null) return`, or widening a type to `any`. If the fix doesn't explain *why* the bad value occurred, push back:
>
> > That hides the symptom. Why is `session` null when `refreshSession` runs? Fix the source of the null, not the read.

## Step 4 — Verify

> Run the full test suite and the build. Confirm the new test passes and nothing regressed. Show me the diff.

Review the diff yourself. A passing suite plus a clean, minimal diff is your signal the fix is real.

## When the bug is intermittent or deep

For a tricky, multi-file, or heisenbug-grade issue, escalate the model and let Claude investigate before touching code:

> This bug is intermittent. Use subagents to investigate the concurrency around session refresh before proposing a fix. I want a theory backed by code, then a failing test, then the fix.

Opus earns its cost on hard, cross-file bugs; Sonnet is fine for the common case.

> [!TIP]
> Enter plan mode (`Shift+Tab`) for the investigation phase so Claude reads and reasons without editing. Switch out of it only when you're ready to apply the fix. For the underlying loop, see [How Claude Code works](../explanation/how-claude-works.md).

## Why this works

Anthropic's best practices frame debugging as: reproduce, write a test that captures the failure, fix, verify. The failing test is the anchor — it forces Claude to demonstrate understanding before changing anything and gives you an objective pass/fail at the end.

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices); community practice.
