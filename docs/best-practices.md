---
title: Best practices
description: The highest-leverage habits for working with Claude Code, distilled from Anthropic's official guidance and the community.
---

# Best practices

This is the authority layer: a curated set of habits that separate fluent Claude Code use from fighting the tool. Each tip is a one-line rule and the reason it matters. Guidance is **Official (Anthropic)** unless explicitly labeled **Community**.

> [!TIP]
> If you remember one thing: **context is your fundamental constraint.** Almost every practice below is really about keeping the context window clean, relevant, and verifiable.

## Workflow

1. **Follow explore → plan → code → commit.** Let Claude read the relevant code before it writes any, plan the change, implement, then commit. Skipping the explore step is the most common cause of confidently wrong edits.
2. **Don't over-plan.** If the diff is one sentence to describe, skip the plan and just ask. Planning a trivial change wastes tokens and your attention.
3. **Always give Claude a verifiable check.** Tests, a build, or a screenshot to compare against is "the difference between a session you watch and one you walk away from." Without a check, the model has no signal that it succeeded.
4. **For big features, interview-me-then-spec, then implement in a FRESH session.** Have Claude interview you to produce a spec, then start a clean session to build it. The planning conversation is clutter the implementation doesn't need.
5. **Iterate visually.** Paste a screenshot, let Claude compare its result to the target, and fix the differences. The visual loop closes much faster than describing UI in prose.

> [!TIP]
> **If you can't verify it, don't ship it.** Unverifiable output is the single highest-risk anti-pattern — see [Anti-patterns](#anti-patterns).

## Context and cost

1. **`/clear` between unrelated tasks; `/compact` mid-task.** `/clear` wipes context for a clean start; `/compact` summarizes so you keep the thread while shedding weight.
2. **Community: prefer `/clear` unless the cache is warm.** `/compact` is only cheap inside the ~5-minute prompt-cache warm window; outside it, `/clear` is the cheaper reset.
3. **Keep CLAUDE.md lean.** A "bloated CLAUDE.md causes Claude to ignore your instructions." Litmus test for every line: *would removing this cause a mistake?* If not, cut it.
4. **Be specific.** Vague prompts cost 50k+ extra tokens as Claude explores to fill the gaps you left. Precision is cheaper than re-rolling.
5. **Match the model to the job.** *(Community framing)* Sonnet handles ~80% of work; reach for Opus on hard architecture or tricky bugs, Haiku for trivial tasks. See [Cost optimization](./guides/cost-optimization.md).
6. **Community: tune `MAX_THINKING_TOKENS`.** Tuning thinking budget can cut cost ~30–40% on some workloads. This is single-source — test it on your own tasks before trusting it.
7. **Move occasional workflows into skills.** Knowledge you need sometimes shouldn't tax every session's context. Skills load on demand; CLAUDE.md loads always.

See [The context window](./explanation/context-window.md) for the model behind all of this.

## Subagents

1. **Reach for subagents early — context is the constraint.** "Since context is your fundamental constraint, subagents are one of the most powerful tools." They do work in an isolated window and return only a summary, keeping your main thread clean.
2. **Use them for many-file reads and isolated focus.** A subagent can read twenty files and hand back three sentences, so the bulk never touches your context.
3. **Run adversarial review in a fresh context.** A reviewer that sees only the diff catches issues the author's polluted context misses.
4. **But don't chase every finding.** Acting on every nit is its own anti-pattern — over-engineering. Triage, then fix what matters.

See [Subagents](./reference/subagents.md).

## Skills and hooks

1. **Skills for "sometimes-relevant" knowledge.** When something matters occasionally, a skill keeps it out of CLAUDE.md and out of every session until it's actually needed.
2. **Hooks for what must happen every time, with zero exceptions.** Hooks are deterministic where skills are probabilistic — if a step can't be optional, it can't be a skill.
3. **Community: `PreToolUse` exit-2 is a hard guarantee.** A non-zero exit blocks the tool call outright, giving you an enforced gate (e.g. "never write to this path") rather than a polite request.

See [CLAUDE.md](./reference/claude-md.md) for what belongs there versus in a skill.

## MCP

1. **Community: keep ~3–6 MCP servers.** Each server's tool definitions consume context on every turn; too many quietly starve the work you actually care about.
2. **Prefer the `gh` CLI over the GitHub MCP.** *(Official-leaning)* The CLI is more token-efficient than the MCP server's tool surface for the same GitHub operations.

## Anti-patterns

1. **The kitchen-sink session.** Many unrelated tasks in one thread bury the signal. Fix: `/clear` between them.
2. **Correcting more than twice.** If you've corrected Claude 2+ times, the context is cluttered, not the model confused. Fix: `/clear` and write a better prompt — "a clean session with a better prompt almost always outperforms a long session with accumulated corrections."
3. **The over-specified CLAUDE.md.** Every speculative rule is a tax on every session and dilutes the rules that matter.
4. **Shipping unverifiable work.** "If you can't verify it, don't ship it." No test, build, or visual check means no evidence it works.
5. **The unscoped infinite "investigate."** Open-ended exploration eats context without bound. Fix: scope it tightly or delegate it to a subagent.

## A note on rigidity

> [!NOTE]
> These are starting points, not set in stone. "Sometimes you should let context accumulate because you're deep in one complex problem." The rules optimize for the common case; you are allowed to break them deliberately when you know why.

---

**Sources:**

- [Claude Code best practices — Anthropic (official)](https://code.claude.com/docs/en/best-practices)
- [Claude Code: Best practices for agentic coding — Anthropic Engineering blog](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Awesome Claude Code (community)](https://github.com/hesreallyhim/awesome-claude-code)
