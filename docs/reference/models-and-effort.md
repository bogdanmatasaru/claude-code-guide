---
title: Models, effort & thinking
description: Model aliases, plan defaults, /model and /effort, extended thinking and ultrathink, opusplan, and picking a model by task.
---
# Models, effort & thinking

Claude Code lets you choose the model, how hard it reasons (effort), and whether it thinks step by step before answering. This page covers the controls and how to pick sensibly.

## Model aliases

| Alias | Resolves to |
| --- | --- |
| `default` | Your plan's default model |
| `best` | The strongest available (= `opus`) |
| `opus` | Opus — on the Anthropic API, Opus 4.8 (`claude-opus-4-8`) |
| `sonnet` | Sonnet — on the Anthropic API, Sonnet 4.6 |
| `haiku` | Fastest, lightest model |
| `sonnet[1m]` / `opus[1m]` | 1M-token context variants |
| `opusplan` | Opus while planning, then Sonnet to execute |

> [!NOTE]
> Model IDs depend on the provider. On Bedrock or Vertex, an alias may resolve to a 4.5/4.6 build. State the provider when quoting exact IDs.

## Defaults by plan

| Plan | Default model |
| --- | --- |
| Max / Team Premium / Enterprise | Opus 4.8 |
| Pro / Team Standard | Sonnet 4.6 |

## Switching models

Use `/model` to open the picker (it saves your default since v2.1.153), or `Option/Alt+P` to switch quickly. At launch, pass `--model <alias>`. Environment variables also apply: `ANTHROPIC_MODEL` sets the main model and `CLAUDE_CODE_SUBAGENT_MODEL` sets the model for subagents.

## Effort

Effort controls how much reasoning the model spends per turn.

| Level | Use for |
| --- | --- |
| `low` | Quick, mechanical edits |
| `medium` | Everyday tasks |
| `high` | Default on Opus 4.8 / Sonnet 4.6 |
| `xhigh` | Hard problems worth more compute |
| `max` | Maximum reasoning |

Set it with `/effort`, the `--effort` flag, or the `effortLevel` setting.

## Thinking

Extended thinking lets the model reason before responding. Toggle it with `Option/Alt+T`. For a one-off deep pass, include the keyword `ultrathink` in your prompt — it requests the deepest reasoning for that single message.

## opusplan

`opusplan` is a hybrid: Claude uses **Opus** while in plan mode to design a solution, then switches to **Sonnet** to execute it. This gives you strong planning without paying Opus rates for every implementation step.

## Picking a model by task

| Task | Suggestion |
| --- | --- |
| Quick fixes, formatting, simple edits | `sonnet` or `haiku` |
| Everyday feature work | `sonnet` |
| Hard architecture, tricky debugging, planning | `opus` / `best` |
| Plan thoroughly, then implement cheaply | `opusplan` |
| Very large codebase context | `opus[1m]` / `sonnet[1m]` |

> [!TIP]
> For balancing capability against spend, see [cost optimization](../guides/cost-optimization.md).

**Source:** [Model configuration](https://code.claude.com/docs/en/model-config)
