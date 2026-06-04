---
title: Optimize cost & context
description: Cut Claude Code spend without cutting quality — model selection, /clear vs /compact, lean CLAUDE.md, specific prompts, and thinking-token tuning.
---
# Optimize cost & context

Most cost overruns come from two habits: using a bigger model than the task needs, and letting context bloat. Fix both and you cut spend without touching quality. Run `/usage` anytime to see where you stand against your limits.

## Match the model to the task

- **Sonnet** handles roughly 80% of work — features, edits, the everyday loop. Keep it as your default.
- **Opus** for hard multi-file changes, architecture decisions, and tricky bugs that need deep reasoning. Reach for it deliberately, not by default.
- **Haiku** for trivial, mechanical work where a smaller model is plenty.

Picking Sonnet over Opus for routine work is the single biggest lever. See [Models and effort](../reference/models-and-effort.md).

## Manage context: /clear vs /compact

Context is cost — every token in the window is re-sent on each turn.

- **`/clear` between unrelated tasks.** A kitchen-sink session that mixes a bug fix, a refactor, and a doc edit drags all of it into every prompt. Clear and start clean.
- **`/compact` mid-task** to summarize a long thread while keeping the thread going.

> [!IMPORTANT]
> The cache nuance: `/compact` is cheap only inside the prompt-cache window (about 5 minutes since the last activity). After that the cache has expired, so compacting re-reads the whole conversation — and `/clear` is the cheaper choice. Rule of thumb: compact while you're actively working, clear when you're switching tasks or coming back cold.

## Keep CLAUDE.md lean

A bloated `CLAUDE.md` is loaded into every session and, worse, causes Claude to ignore your instructions when it's overstuffed. Keep only the few facts that change behavior — build/test commands, where core logic lives, hard conventions. Cut anything Claude can rediscover on its own.

## Be specific

Vague prompts are expensive: Claude searches, guesses, and backtracks, and a single fuzzy request can burn 50k+ extra tokens. Name the files, the interfaces, and the done condition up front. Specificity is cheaper than iteration.

> [!TIP]
> Correcting Claude more than twice on the same task is a cost signal, not just a quality one — the context is now cluttered with wrong turns. `/clear` and rewrite the prompt instead of pushing through.

## Delegate research to subagents

Investigation generates a lot of tokens — file reads, search results, dead ends. Push that work into [subagents](../reference/subagents.md): each runs in its own context window and returns only a summary, so your main thread stays small and cheap. See [The context window](../explanation/context-window.md) for why this matters.

## Tune thinking tokens

You can cap extended-thinking budget with the `MAX_THINKING_TOKENS` environment variable. Lowering it on tasks that don't need deep reasoning reduces spend.

> [!NOTE]
> Community-reported savings from thinking-token tuning land around 30–40%. Treat that as a guideline to test on your own workload, not a guarantee — measure with `/usage` before and after. Don't starve genuinely hard tasks of thinking budget just to save tokens.

## A quick checklist

1. Default to Sonnet; escalate to Opus only for hard problems.
2. `/clear` between unrelated tasks; `/compact` only inside the cache window.
3. Trim `CLAUDE.md` to the load-bearing facts.
4. Write specific prompts with named files and a done condition.
5. Delegate research to subagents.
6. Test `MAX_THINKING_TOKENS` tuning on routine work.
7. Check `/usage` to see usage against your limits.

## Why this works

Cost in Claude Code tracks tokens, and tokens track model size and context length. Right-sizing the model and keeping the window tight attack both directly. Anthropic's guidance — be specific, keep `CLAUDE.md` lean, clear between tasks — is as much a cost strategy as a quality one.

**Related:** [Cheatsheet](../cheatsheet.md) · [Best practices](../best-practices.md) · [Learning path](../learning-path.md)

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices); community-reported figures noted as such.
