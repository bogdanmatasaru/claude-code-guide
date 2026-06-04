---
name: commit
description: Stage changes and create a Conventional Commit from the diff. Use when the user wants to commit the current work. Does not push.
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git diff:*), Bash(git commit:*), Bash(git log:*)
---

# Commit

Create a single, well-formed Conventional Commit for the current changes. **Never push.**

## Steps

1. Inspect state — run these to understand what's changing:
   - `git status`
   - `git diff` (unstaged) and `git diff --staged`
   - `git log --oneline -10` to match the repo's existing message style.
2. Stage the relevant files with `git add` (use specific paths; do **not** blindly
   `git add -A` if there are unrelated changes — ask the user which to include).
3. Write a Conventional Commit message:
   - Format: `type(scope): summary` — type ∈ `feat|fix|docs|refactor|test|chore|perf|build|ci`.
   - Summary in the imperative mood, ≤ 72 chars, no trailing period.
   - Add a body only if the *why* isn't obvious from the summary.
4. Commit with `git commit`. Prefer multiple `-m` flags over embedded newlines.

## Rules

- One logical change per commit. If the diff covers unrelated concerns, suggest splitting.
- Do **not** run `git push`, `git commit --amend` on pushed commits, or `--no-verify`
  (let pre-commit hooks run).
- If nothing is staged and nothing is stageable, say so instead of creating an empty commit.
- Do not add the Co-Authored-By trailer manually; the `includeCoAuthoredBy` setting handles it.
