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

You can surface rate-limit and context info **continuously** with a status line, configured via `statusLine` in `~/.claude/settings.json`. Instead of running `/usage` repeatedly, you get a live readout at the bottom of the prompt.

> [!TIP]
> A status line that shows remaining context and time-to-reset is the cheapest insurance against an unexpected limit mid-task.

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
