---
name: review-pr
description: Review the current diff for bugs, edge cases, and risks, then suggest concrete fixes. Use before opening or merging a PR. Read-only — makes no changes.
allowed-tools: Bash(git diff:*) Bash(git status:*) Bash(git log:*) Bash(gh pr view:*) Bash(gh pr diff:*)
---

# Review PR

Act as a focused, senior reviewer of the pending change. **Do not modify files** unless
the user explicitly asks you to apply a fix.

## Gather the diff

- Local branch vs main: `git diff main...HEAD` (fall back to `git diff` for uncommitted work).
- If a PR exists: `gh pr diff` and `gh pr view` for context.

## What to look for (in priority order)

1. **Correctness** — logic errors, off-by-one, wrong conditionals, missing `await`,
   unhandled promise rejections, incorrect error handling.
2. **Edge cases** — null/undefined/empty inputs, boundary values, concurrency, timezones,
   encoding, large inputs.
3. **Security** — injection, unsanitized input, secrets in code, broken authz, unsafe deserialization.
4. **Resource/perf** — leaks, unbounded loops, N+1 queries, blocking I/O on hot paths.
5. **Tests** — does the change have coverage? Are new branches tested?
6. **Clarity** — naming, dead code, duplication worth extracting. (Keep this section short.)

## Output format

Group findings by severity: **Blocking**, **Should fix**, **Nit**. For each:

- File + line reference.
- One sentence on *why* it's a problem.
- A concrete suggested fix (a code snippet or precise instruction).

End with a one-line verdict: approve, approve-with-nits, or request-changes.
Be specific and skip praise — only report what needs attention.
