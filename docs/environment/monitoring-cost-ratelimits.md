---
title: Monitor cost & rate limits
description: Use /usage, /context, and a status line to track token spend, plan windows, and rate limits — and what to do when you hit one.
---
# Monitor cost & rate limits

Claude Code gives you built-in visibility into how much you're using and how close you are to a limit. Knowing where to look turns a surprise lockout into a quick adjustment.

## `/usage` — your plan windows

Run `/usage` to see your session token use plus **plan usage bars**:

- A **5-hour window** (the rolling session limit).
- A **weekly window**.

`/usage` also **attributes** usage to what's consuming it — skills, subagents, and MCP servers — so you can see what's expensive. Press **`d`** and **`w`** to switch between the 5-hour and weekly views.

When you're near a limit, `/usage` shows the **time until your window resets**, which is the number you actually plan around.

## `/context` — context-window usage

Run `/context` to see how full the current conversation's **context window** is. A bloated context slows responses and costs more tokens per turn. When it's getting full, run **`/clear`** to start fresh and free it up.

## `/cost` and the billing caveat

`/cost` prints dollar figures for the session.

> [!WARNING]
> On **Max** and **Team** plans, the dollar figures from `/cost` **do not reflect actual billing** — those plans are subscription-based, not pay-per-token. Don't treat `/cost` as your bill. **Watch the usage bars in `/usage` instead** — they're what govern access.

## A live status line

Instead of running `/usage` repeatedly, keep a **status line** pinned to the bottom of the prompt that always shows your model, context usage, your 5-hour and weekly limits (with bars and time-to-reset), the git branch, session time, and free disk:

```text
🤖 Opus 4.8   🧠 [███░░░░] 48%
🟢 5h [███░░░░] 32% ⟳ 3h 3m    📅 7d [███░░░░] 31% ⟳ 4d 10h
🌿 main +19 -8   ⏱ 4h 27m   💾 19.9G/48.0G
```

The [one-command setup](./bootstrap-setup.md) installs this for you — via [ccstatusline](https://github.com/sirmalloc/ccstatusline) — and wires it into `~/.claude/settings.json`. To set it up by hand, or to use the no-Node `statusline.sh` alternative (just bash + jq + git), see the [status-line assets](https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets/statusline).

> [!TIP]
> A status line that shows remaining context and time-to-reset is the cheapest insurance against an unexpected limit mid-task. It's the whole point of this guide's setup — you never have to wonder how much plan you've got left.

## What to do when you hit a limit

When you're throttled, you have several quick levers:

| Lever | Action |
| --- | --- |
| **See the reset** | `/usage` shows the time until your window resets. |
| **Switch model** | Drop to **Sonnet** or **Haiku** for cheaper, faster turns. |
| **Lower effort** | Reduce reasoning depth with `/effort`. |
| **Free context** | Run `/clear` to drop accumulated context. |

The fastest recovery is usually a combination: `/clear` to reset context, then switch to a lighter model for routine work and save the heavy model for the hard parts.

> [!NOTE]
> Hitting limits often means the wrong model is doing routine work, or context is bloated. Both are fixable habits, not hard walls.

## Go deeper

For strategies that keep you under the limits in the first place — model selection, scoping prompts, and context hygiene — see [Cost optimization](../guides/cost-optimization.md).

## Related

- [One-command setup](./bootstrap-setup.md) writes the `~/.claude/settings.json` you'll extend with a `statusLine`.
- [Terminal & Ghostty setup](./terminal-and-ghostty.md) for the environment around all this.
