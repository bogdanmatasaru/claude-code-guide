---
title: Run against a non-Anthropic endpoint
description: Point Claude Code at another provider with ANTHROPIC_BASE_URL — what to set, what silently stops working, and how to keep your status line honest.
verified:
  claudeCode: '2.1.226'
  date: '2026-08-09'
---
# Run against a non-Anthropic endpoint

Claude Code speaks the Anthropic Messages protocol. Any endpoint that speaks it back can serve the client, so setting `ANTHROPIC_BASE_URL` redirects the whole session to another provider — same TUI, same tools, same `CLAUDE.md`, a different model behind it, and a meaningful list of features that stop working.

This page is the honest version of that setup.

> [!IMPORTANT]
> **Last verified against Claude Code 2.1.226 on 2026-08-09.** This is behaviour outside Anthropic's supported envelope; it changes between releases without notice. Claims marked *Observed* are measurements from that build, not documented guarantees.

## Know what you're opting out of

Anthropic is explicit about where support ends:

> Anthropic doesn't endorse, maintain, or audit third-party gateway products, and doesn't support routing Claude Code to non-Claude models through any gateway.
>
> — [LLM gateway](https://code.claude.com/docs/en/llm-gateway)

Anthropic documents the mechanics of redirecting the client, and this page uses them. It doesn't support the result: a bug you hit in this configuration is not Anthropic's to fix. Your use is still governed by Anthropic's terms and your provider's — read both. Some provider subscriptions are sold for interactive use only, which makes [Headless & CI](./headless-and-ci.md) the wrong page to follow on those plans.

## The minimal contract

Four things must line up, or the session fails in ways that look like something else:

| Variable | Why it matters |
| --- | --- |
| `ANTHROPIC_BASE_URL` | The endpoint. Claude Code appends the API path itself — give it the base, not `/v1/messages`. Copy your provider's documented form exactly, trailing slash included or excluded as they write it; normalisation isn't specified anywhere. |
| `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` | The credential. `ANTHROPIC_AUTH_TOKEN` becomes an `Authorization: Bearer` header and takes precedence; `ANTHROPIC_API_KEY` becomes `X-Api-Key`. See [authentication precedence](https://code.claude.com/docs/en/authentication). |
| `ANTHROPIC_MODEL` | Your provider's model ID. Claude Code **passes any string through without checking it** on a custom base URL ([model config](https://code.claude.com/docs/en/model-config)). |
| `ANTHROPIC_DEFAULT_OPUS_MODEL`, `..._SONNET_MODEL`, `..._HAIKU_MODEL`, `..._FABLE_MODEL`, `CLAUDE_CODE_SUBAGENT_MODEL` | The tier aliases. Miss these and anything that asks for `sonnet` or `haiku` sends that literal string to a provider that has no such model. |

That last row is a common cause of "the main chat works but subagents die instantly".

> [!NOTE]
> `ANTHROPIC_AUTH_TOKEN` takes effect immediately. `ANTHROPIC_API_KEY` does not: in an interactive session Claude Code prompts you once to approve or decline it, and remembers your answer ([authentication](https://code.claude.com/docs/en/authentication)). Approve it on first launch. A key you declined once is ignored silently and never re-prompts — re-enable it with **Use custom API key** in `/config`. In `-p` mode the key is always used, with no prompt.

> [!WARNING]
> Put these in a settings file `env` block, not shell exports. A settings-file value **wins over the shell** ([precedence](https://code.claude.com/docs/en/env-vars)), and a background session "doesn't inherit gateway endpoint variables such as `ANTHROPIC_BASE_URL` … from the shell that started the supervisor" ([agent view](https://code.claude.com/docs/en/agent-view)) — so shell-only config can leave background work running against your Claude subscription.

## Keep it beside your Claude setup, not on top of it

The cleanest arrangement is a second config directory, so your normal Claude sessions stay untouched:

```bash
mkdir -p ~/.claude-alt
# write the settings below into ~/.claude-alt/settings.json
alias alt='CLAUDE_CONFIG_DIR=~/.claude-alt claude'
```

Then `claude` is Claude and `alt` is the other provider — separate history, separate settings, no file editing to switch. `CLAUDE_CONFIG_DIR` is a [documented variable](https://code.claude.com/docs/en/env-vars), and the docs use this same alias pattern.

> [!IMPORTANT]
> `CLAUDE_CONFIG_DIR` **replaces** `~/.claude`; it does not merge with it. *Observed on 2.1.226:* a settings file in the alt directory is the only one read, so it needs its own `statusLine`, and your skills, plugins and MCP servers are not there unless you put them there. Expect a first-run wizard and a folder-trust prompt the first time.

This also sidesteps the auth conflict: with a saved `/login` and a custom credential both present, Claude Code warns at startup that auth may not work as expected.

## Worked example: Kimi Code

[Kimi Code](https://www.kimi.com/code/docs/en/third-party-tools/claude-code.html) publishes its own Claude Code setup instructions, so its configuration is documented rather than reverse-engineered — which is why it's the example here. This guide is not affiliated with, and does not endorse, Moonshot AI.

Its Anthropic-compatible base is `https://api.kimi.com/coding/`, and keys come from the Kimi Code Console, reached through a Kimi membership with Kimi Code benefits active.

Membership tier decides which models you may call and the context each one gets:

| Plan | Models available | Context limit |
| --- | --- | --- |
| Andante | `kimi-for-coding` | 262144 |
| Moderato | `k3`, `k3-256k`, `kimi-for-coding` | 262144 for all three |
| Allegretto and above | the above plus `kimi-for-coding-highspeed` | 1048576 for `k3`; 262144 for the rest |

Note that `k3` is available on Moderato but capped at 262144 there — the 1M window is an Allegretto-and-above benefit, not a property of the model. Calling a model your plan doesn't include returns a `401` naming the tier you'd need.

Below is the **Moderato** configuration. Change the model ID and both context numbers together to match your own row.

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.kimi.com/coding/",
    "ANTHROPIC_API_KEY": "your-kimi-code-key",

    "ANTHROPIC_MODEL": "k3-256k",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "k3-256k",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "k3-256k",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "k3-256k",
    "ANTHROPIC_DEFAULT_FABLE_MODEL": "k3-256k",
    "CLAUDE_CODE_SUBAGENT_MODEL": "k3-256k",

    "CLAUDE_CODE_EFFORT_LEVEL": "high",
    "CLAUDE_CODE_MAX_CONTEXT_TOKENS": "262144",
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW": "262144"
  },
  "permissions": { "deny": ["WebSearch"] },
  "statusLine": {
    "type": "command",
    "command": "sh $HOME/.config/ccstatusline/profile-switch.sh",
    "padding": 0
  }
}
```

The two context values must match the limit for **your** plan and model. Kimi sets both in its own published configuration; without them Claude Code assumes a window that doesn't match the model (see [Context window](#context-window)). On the 1M configuration Kimi sets them to `1048576` — note that `CLAUDE_CODE_AUTO_COMPACT_WINDOW` is capped at `1000000` ([env vars](https://code.claude.com/docs/en/env-vars)), so that is the effective threshold there.

`WebSearch` is denied because it runs on Anthropic's own backend and cannot work here; denying it stops the agent burning turns on a tool that never answers. **Leave `WebFetch` enabled** — it runs locally, works on any provider, and Anthropic names it as the substitute where server-side search is unavailable ([feature availability](https://code.claude.com/docs/en/feature-availability)). For real search, add an MCP server that exposes a search tool.

Two provider quirks worth knowing. The `[1m]` suffix on `k3` is a **Claude Code-only spelling** — Kimi documents that API requests and other tools take plain `k3`. And disabling thinking routes K3 requests to an older model, so leave it on.

> [!WARNING]
> Kimi's setup page opens with a Node script it labels "Run Script to Skip Login". This guide does not recommend running it and does not reproduce it. It sets undocumented internal flags in `~/.claude.json` to bypass Claude Code's login flow, and it **deletes eleven model keys from the `env` block of your existing `~/.claude/settings.json`** — including the ones this page tells you to set. The separate `CLAUDE_CONFIG_DIR` above exists so you never need it.

## What stops working

Each row is a behaviour change you will not be warned about. Where a documented workaround exists, it's named.

| Feature | On a custom endpoint | Source |
| --- | --- | --- |
| `/usage` plan bars | The plan breakdown is a subscription feature, so it has nothing to show | [Costs](https://code.claude.com/docs/en/costs) |
| Status line `rate_limits` | Absent — it "appears only for Claude.ai subscribers (Pro/Max) after the first API response in the session" | [Status line](https://code.claude.com/docs/en/statusline) |
| WebSearch | Runs against Anthropic's backend, which "is not configurable"; add an MCP search server instead | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| Remote Control | Disabled when the base URL isn't `api.anthropic.com` (2.1.196+) | [Env vars](https://code.claude.com/docs/en/env-vars) |
| MCP tool search | Off by default, so every tool definition loads upfront and inflates context. `ENABLE_TOOL_SEARCH=true` re-enables it *if* your provider forwards `tool_reference` blocks | [Env vars](https://code.claude.com/docs/en/env-vars) |
| Token counting | Falls back to a local estimate when the provider has no counting endpoint | [Gateway protocol](https://code.claude.com/docs/en/llm-gateway-protocol) |
| `/model` picker | Built-in aliases only by default. `ANTHROPIC_CUSTOM_MODEL_OPTION` adds one entry; `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` queries the endpoint's `/v1/models`, but keeps only IDs containing `claude` or `anthropic` | [Model config](https://code.claude.com/docs/en/model-config), [Gateway protocol](https://code.claude.com/docs/en/llm-gateway-protocol) |
| Cost figures | Computed locally from token counts at Anthropic list rates, so the number is not your provider's price | [Costs](https://code.claude.com/docs/en/costs) |
| Prompt caching | Depends on the provider; if it rejects a cache breakpoint, that block stays uncached for the rest of the conversation | [Prompt caching](https://code.claude.com/docs/en/prompt-caching) |
| Ultrareview, routines, Slack | Require a claude.ai account (Desktop is a partial exception — a gateway can be configured in the app) | [Feature availability](https://code.claude.com/docs/en/feature-availability) |

What keeps working is most of the client: subagents, hooks, slash commands, skills, plugins, `CLAUDE.md`, and MCP servers are provider-independent ([feature availability](https://code.claude.com/docs/en/feature-availability) — note that page's own caveat, that availability behind a gateway "matches the underlying provider the gateway forwards to").

### Context window

Claude Code sizes the context window from the model ID, and falls back to a default for an ID it doesn't recognise rather than asking your provider. *Observed on 2.1.226: an unrecognised ID reports a 200,000-token window; Anthropic does not document that figure.* Two levers change it:

- `CLAUDE_CODE_MAX_CONTEXT_TOKENS`, which "is applied directly for model names Claude Code does not recognize as a Claude model" as of v2.1.193 ([env vars](https://code.claude.com/docs/en/env-vars)). This is the documented lever. On a model Claude Code *does* recognise, the same entry notes it "only takes effect when `DISABLE_COMPACT` is also set".
- Appending `[1m]` to the model ID, where your provider documents that spelling. *Observed on 2.1.226: `k3[1m]` yields exactly 1,000,000 tokens and overrides the variable above.*

Set whichever your provider documents — Kimi's published 1M configuration sets both. Pair either with `CLAUDE_CODE_AUTO_COMPACT_WINDOW` so compaction fires against the real ceiling.

> [!NOTE]
> A large window is what the **client assumes**, not what the provider honours — on a gateway, Claude Code "can't verify 1M support" ([model config](https://code.claude.com/docs/en/model-config)). If the provider rejects an over-long request in wording that doesn't match Anthropic's, the automatic compact-and-retry won't fire and you'll need `/compact` by hand. To prevent that, set `CLAUDE_CODE_AUTO_COMPACT_WINDOW` to the provider's real limit and `CLAUDE_CODE_MAX_OUTPUT_TOKENS` below its output cap — Claude Code otherwise defaults output to 32,000 for an unrecognised ID ([connect to a gateway](https://code.claude.com/docs/en/llm-gateway-connect), [env vars](https://code.claude.com/docs/en/env-vars)).

## Keep the status line honest

This is the part that can actively mislead you, so the setup handles it.

When `rate_limits` is missing from the payload, [ccstatusline](https://github.com/sirmalloc/ccstatusline)'s usage widgets do not blank out. *Observed:* they fall back to Anthropic's usage API using the token in your keychain, so a session pointed elsewhere renders **your Anthropic quota** next to the other provider's model name — plausible, confident, and about a different account than the one answering.

Account detection can't fix this, because you can hold a Max seat and still run a session against another endpoint. So [`profile-switch.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/assets/statusline/profile-switch.sh) decides on the provider first, reading `ANTHROPIC_BASE_URL` (and the `CLAUDE_CODE_USE_*` variables that Bedrock, Vertex and Foundry set) on every render, and selects a profile with no usage widgets at all. If that profile is missing it prints a hint rather than falling back.

`./setup.sh` installs it and, on re-run, repoints a `statusLine` that calls `ccstatusline` directly. `./setup.sh --check` reports whether your `settings.json` actually routes through it — worth running, because a status line that never invokes the launcher is the one case where none of this protects you.

For real quota on another provider, use that provider's own console or CLI.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| Main chat works, subagents die instantly | Tier aliases not repointed — something asked for `sonnet` or `haiku` and it was sent literally |
| `401` naming a plan or tier | Your subscription doesn't include that model, or you used a key from the provider's other platform |
| Model ID "does not exist" | A Claude Code-only spelling sent to the raw API, or a model version name instead of an ID |
| `ANTHROPIC_API_KEY` set but ignored, no prompt | You declined it once; re-enable with **Use custom API key** in `/config` |
| Context bar shows `/200k` on a large-context model | Unrecognised model ID; see [Context window](#context-window) |
| Startup warns that auth may not work | A saved `/login` and a custom credential are both present — use a separate `CLAUDE_CONFIG_DIR`, or `/logout` |
| WebSearch produces nothing useful | It can't work here; deny it and add an MCP search server |
| Status line shows usage that looks like your Claude plan | The launcher isn't wired in, or the wrong profile is active — run `./setup.sh --check` |

Verify the endpoint took effect with `/status`, which shows an `Anthropic base URL` line only when one is set.

## Related

- [Models, effort & thinking](../reference/models-and-effort.md) — aliases and effort levels
- [settings.json](../reference/settings.md) — where the `env` block goes
- [Monitor cost & limits](../environment/monitoring-cost-ratelimits.md) — the Anthropic-side tooling this page replaces

---

*Not affiliated with, endorsed by, or sponsored by Anthropic or Moonshot AI. "Claude" and "Claude Code" are trademarks of Anthropic, PBC; "Kimi" and "Kimi Code" are trademarks of Moonshot AI. Other product names are the property of their respective owners, and are used for identification only. This configuration is not supported by Anthropic, and nothing here modifies your agreement with any provider.*
