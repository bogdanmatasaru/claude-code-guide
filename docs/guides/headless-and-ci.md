---
title: Headless mode & CI automation
description: Run Claude Code non-interactively with claude -p — output formats, fan-out migrations, scoped tools, and GitHub Actions.
---
# Headless mode & CI automation

Headless mode turns Claude Code into a scriptable command. `claude -p "prompt"` runs once, prints a result, and exits — perfect for pipelines, batch migrations, and GitHub Actions.

## The basics

Run a single non-interactive prompt:

```
claude -p "Summarize the changes in the last commit and flag anything risky."
```

Pick a machine-readable output format when a script consumes the result:

```
# one JSON object with the result and metadata
claude -p "..." --output-format json

# incremental JSON events as they happen
claude -p "..." --output-format stream-json
```

Use `json` when you just need the final answer and `stream-json` when you want to process events live (progress, tool calls) in a longer run.

## Fan-out migrations

The headless pattern that pays off most: generate a list of files, then loop `claude -p` over each one. This parallelizes a mechanical change across a codebase.

```bash
# 1. Generate the work list
files=$(claude -p "List every file under src/ that still imports the deprecated 'moment' library. One path per line, no prose." \
  --output-format json | jq -r '.result')

# 2. Apply the change file-by-file, scoped tightly
for f in $files; do
  claude -p "In $f, replace moment usage with date-fns. Keep behavior identical. Commit with a clear message." \
    --allowedTools "Edit,Bash(git commit:*)"
done
```

`--allowedTools` is the safety boundary. Here Claude can only edit files and run `git commit` — it can't run arbitrary shell, push, or delete. Scope the allowlist to exactly the operations the task needs.

> [!IMPORTANT]
> Test on a few files first, then run at scale. Point the loop at three files, inspect the diffs and commits, and only then unleash it on the full list. A mistake repeated across 200 files is expensive to unwind.

> [!WARNING]
> In CI and unattended loops, Claude runs without a human approving each action. Keep `--allowedTools` minimal, run in a branch or [git worktree](./parallel-work-worktrees.md), and review the resulting diff before merging.

## GitHub Actions

Anthropic ships an official action for wiring Claude into your repo:

```yaml
# .github/workflows/claude.yml
name: Claude
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]

jobs:
  claude:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

With this in place, mentioning `@claude` in a pull request or issue comment triggers Claude to act — answer a question, implement a requested change, or review the diff — and report back on the PR. Treat it as a teammate you delegate to in the open: scope the request, then review what it pushes.

> [!NOTE]
> Keep the model choice deliberate in CI. Routine, well-specified jobs run fine on Sonnet; reserve Opus for genuinely hard automated tasks, since CI volume multiplies cost quickly.

## Tips

- **Be specific.** Headless prompts get no follow-up. A vague instruction wastes a whole run and tokens; name files, interfaces, and the done condition.
- **Make work verifiable.** Have the prompt run tests or a build and fail loudly, so the pipeline catches bad output instead of merging it.
- **Capture output.** Pipe `--output-format json` into `jq` to assert on results and gate the pipeline.

## Why this works

Headless mode is the same engine as interactive Claude with the human loop removed, so the same rules apply harder: tight scope, explicit verification, and minimal tool permissions. The fan-out loop scales a single good prompt across an entire codebase.

**Related:** [Cheatsheet](../cheatsheet.md) · [Best practices](../best-practices.md) · [Learning path](../learning-path.md)

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices); community practice.
