---
title: Run against a non-Anthropic endpoint
description: Point Claude Code at another provider with ANTHROPIC_BASE_URL — what to set, what silently stops working, and how to keep your status line honest.
verified:
  claudeCode: '2.1.226'
  date: '2026-08-09'
---
# Run against a non-Anthropic endpoint

Claude Code is a client, and the model it talks to is decided by one setting. Point that setting at a different company's server and the same terminal, the same skills, the same hooks and commands all keep working — with a different model answering.

People do this for one reason: **a second flat-rate subscription absorbs the work, and your Claude limits never notice.** Per-token billing on this kind of volume adds up fast — the point of a second subscription is that it doesn't.

Before you set it up, know the shape of the trade: you keep the terminal, the skills, the hooks and the commands, and you give up a specific list of features — web search, the usage and cost readouts, and a few things that go quiet without an error. Auto-compaction still runs, but it fires against the window Claude Code *assumes* for your model ID — 200,000 tokens for one it doesn't recognise — so you set the two context variables below to make it fire against your provider's real ceiling.

One caveat the setup forces: it runs in a second config directory, which starts empty. Your skills, plugins, MCP servers and `CLAUDE.md` keep working in principle, but they are not copied across — you put them in the new directory yourself. The [full list is below](#what-stops-working), and it is the section worth reading before you rely on this.

> [!WARNING]
> **Everything the session reads is sent to your provider's servers, not Anthropic's** — the files it opens, the diffs it reviews, the commands it runs. Check your employer's policy and the provider's data-retention and training terms before pointing this at work code. The `chmod 600` below stops other users on this machine reading your key; it is not encryption, and it does nothing for your source code. For the Kimi example, the processor is Moonshot AI.

> [!IMPORTANT]
> **Last verified against Claude Code 2.1.226 on 2026-08-09.** This is behaviour outside Anthropic's supported envelope; it changes between releases without notice. Claims marked *Observed* are measurements from that build, not documented guarantees.

## From zero to working

The shell commands below are written for macOS with zsh, which is what this repo's `setup.sh` assumes. Claude Code itself installs on macOS, Linux and Windows ([Installation](../getting-started/installation.md)) — the settings file and the variables are platform-independent, the shell commands are not, and the notes say where.

If you just want it running, these six steps are the whole path. Each one links to the detail below.

1. **Get a paid account with a provider that exposes an Anthropic-compatible API**, and create a key. "Anthropic-compatible" is how providers advertise it; if one has no Claude Code setup page of its own, assume it won't work. The [worked example](#worked-example-kimi-code) uses [Kimi Code](https://www.kimi.com/code/console), where keys come from the Console.

   Budget for this before you start. Kimi Code is a benefit inside a paid Kimi membership rather than a separate product — it shares that membership's quota — and the tier decides which models you may call and how much context each gets ([tier table below](#worked-example-kimi-code)). It is not on the free tier.

   The tier also sets your quota, and quota is the part that bites: it refreshes every 7 days without rollover, there is a rolling 5-hour window on top, and the CLI, the IDE extension and third-party tools all draw on the same pool. Past that, "Extra Usage" bills by actual usage rather than flat rate — leave it off, or set a monthly cap, if you want this to stay a fixed cost.

   Prices and plan names are on the [Kimi membership page](https://www.kimi.com/membership/pricing). This guide does not reproduce them: they move faster than the rest of this page, and at the time of writing that page carries a banner saying Kimi and Kimi Code benefits are about to be separated. Note the plan names there do not match the tier table below — that table comes from Kimi's Kimi Code documentation.

2. **Make a second config directory**, so none of this touches your normal Claude setup — see [Keep it beside your Claude setup](#keep-it-beside-your-claude-setup-not-on-top-of-it):

   ```bash
   mkdir -p ~/.claude-alt
   ```

3. **Create `~/.claude-alt/settings.json`** and paste in the [example block](#worked-example-kimi-code):

   ```bash
   nano ~/.claude-alt/settings.json
   ```

   Paste the block, then fill in three things: your key, **all six model IDs** for your plan, and the two context numbers — [the tier table](#worked-example-kimi-code) tells you which. **If you have not run this repo's `setup.sh`, delete the `statusLine` block first** — it points at a script you do not have.

   Save and quit (in `nano`: Ctrl+O, Enter, Ctrl+X), then lock the file down and check it parses:

   ```bash
   chmod 600 ~/.claude-alt/settings.json
   python3 -m json.tool ~/.claude-alt/settings.json > /dev/null && echo "settings.json OK"
   ```

   The `chmod` matters because the file holds a key in plaintext. The parse check matters because Claude Code ignores an unreadable settings file **silently** — you would launch against Anthropic and not be told.

4. **Add an alias, to your shell startup file** so it survives new terminals:

   ```bash
   echo "alias alt='CLAUDE_CONFIG_DIR=~/.claude-alt claude'" >> ~/.zshrc
   source ~/.zshrc
   ```

   On **bash**: `~/.bashrc` on Linux, but on macOS bash starts as a login shell, so use `~/.bash_profile`. On **fish**, use `$HOME` rather than `~` — fish only expands a tilde at the start of a word, so `~/.claude-alt` would stay literal:

   ```fish
   alias --save alt 'CLAUDE_CONFIG_DIR=$HOME/.claude-alt claude'
   ```

   On **Windows PowerShell** there is no alias that carries arguments; add a function to your profile instead:

   ```powershell
   function alt { $env:CLAUDE_CONFIG_DIR="$HOME\.claude-alt"; claude @args }
   ```

5. **`cd` into a project directory, then run `alt`.** A fresh config directory means a first-run wizard: theme, then a folder-trust prompt — answer yes, and this is why you `cd`-ed first, so you are not trusting your whole home directory — then a prompt asking whether to use the custom API key: **approve that one** ([what to do if you decline](#the-minimal-contract)). On macOS you will also see a startup warning that authentication may not work as expected. It is expected and harmless ([why](#keep-it-beside-your-claude-setup-not-on-top-of-it)). Then check it took effect:

   - `/status` should show an `Anthropic base URL` line with your provider's URL. That line is the check — it appears only when a base URL is set.
   - **Do not judge it by asking the model who it is.** Kimi documents that "even if the model name still appears as a Claude model, the actual calls are still made to the Kimi Code API", so a Claude-sounding answer is expected and proves nothing either way.

6. **Read [what stops working](#what-stops-working)** before you rely on it. This is the step people skip.

To stop using it, just run `claude` instead of `alt`. To remove it entirely, delete the alias line from `~/.zshrc` and `rm -rf ~/.claude-alt` — that also deletes the alt session history, which is separate from your normal one. Note that if you additionally ran this repo's `setup.sh` for the status line, it may have modified `~/.claude/settings.json` — it does so only when adding a `statusLine` key or upgrading a bare `ccstatusline` call, and in that case it first copies the old file to `settings.json.bak.<epoch>`. If yours already routed through the launcher, or carried a custom `statusLine` it chose to leave alone, nothing was changed and there is no backup.

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
> Put these in a settings file `env` block, not shell exports. A settings-file value **wins over the shell** ([precedence](https://code.claude.com/docs/en/env-vars)), and a background session "doesn't inherit gateway endpoint variables such as `ANTHROPIC_BASE_URL` … from the shell that started the supervisor" ([agent view](https://code.claude.com/docs/en/agent-view)) — so shell-only config can leave background work running against your Claude subscription. Anthropic's documented fix is a **project-level** `.claude/settings.json` `env` block — and if you do that, use `.claude/settings.local.json`, which is gitignored, not `.claude/settings.json`, which is committed; a key in a tracked settings file ends up in your repo history. A separate config directory is not ignored by background work — the same page says that with `CLAUDE_CONFIG_DIR` set, "the supervisor uses that directory instead of `~/.claude` and runs as a separate instance with its own sessions", and applies each session's directory, settings and credentials to its worker. What it does not spell out is whether a user-level `env` block there has the same precedence as a project one, so check `/status` inside a background session before trusting it. Note also that `ANTHROPIC_DEFAULT_*_MODEL` aliases *are* read from the dispatching shell while `ANTHROPIC_BASE_URL` is not — export the aliases without the base URL and a background worker sends your provider's model IDs to Anthropic.

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

On Linux and Windows this also separates credentials, so the alt directory has no saved `/login` and no auth conflict. **On macOS it does not:** credentials live in the system Keychain rather than under `CLAUDE_CONFIG_DIR` ([authentication](https://code.claude.com/docs/en/authentication)), so your Claude login stays visible to the alt session and Claude Code may warn at startup that auth may not work as expected. The warning is harmless once you have approved the custom key — `/status` is what tells you which credential is actually in use.

## Worked example: Kimi Code

[Kimi Code](https://www.kimi.com/code/docs/en/third-party-tools/claude-code.html) publishes its own Claude Code setup instructions, so its configuration is documented rather than reverse-engineered — which is why it's the example here. This guide is not affiliated with, and does not endorse, Moonshot AI.

Its Anthropic-compatible base is `https://api.kimi.com/coding/`, and keys come from the Kimi Code Console, reached through a Kimi membership with Kimi Code benefits active.

Membership tier decides which models you may call and the context each one gets:

| Plan | Models available | Context limit |
| --- | --- | --- |
| Andante | `kimi-for-coding` | 262144 |
| Moderato | `k3`, `k3-256k`, `kimi-for-coding` | 262144 for all three |
| Allegretto and above | the above plus `kimi-for-coding-highspeed` | 1048576 for `k3`; 262144 for the rest |

Note that `k3` is available on Moderato but capped at 262144 there — the 1M window is an Allegretto-and-above benefit, not a property of the model. *Observed on 2.1.226:* calling a model your plan doesn't include returns a `401` naming the tier you'd need.

Below is the **Moderato** configuration. To adapt it:

- **Andante**: replace all six `k3-256k` values with `kimi-for-coding`; the context numbers stay at `262144`.
- **Moderato**: use it as-is.
- **Allegretto and above**: use `k3[1m]` for all six, and set both context numbers to `1048576`, as Kimi's own published configuration does. *Observed on 2.1.226: the `[1m]` suffix wins over `CLAUDE_CODE_MAX_CONTEXT_TOKENS`, so the window is 1,000,000 whether or not you also set the variable — the `1048576` you type is not the number you get.* `CLAUDE_CODE_AUTO_COMPACT_WINDOW` is separately documented as capped at `1000000` ([env vars](https://code.claude.com/docs/en/env-vars)), so it clamps to the same figure. Set both anyway, as Kimi does: they are what takes effect if you ever drop the suffix.

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

The `statusLine` line needs [this repo's](https://github.com/bogdanmatasaru/claude-code-guide) `setup.sh` to have been run once — it installs `ccstatusline` and the launcher into `~/.config/ccstatusline/`, which sits outside any config directory and is shared by both. If you have not run it, delete that block; everything else works without it.

The two context values must match the limit for **your** plan and model. Kimi sets both in its own published configuration; without them Claude Code assumes a window that doesn't match the model (see [Context window](#context-window)). On the 1M configuration Kimi sets them to `1048576` — note that `CLAUDE_CODE_AUTO_COMPACT_WINDOW` is capped at `1000000` ([env vars](https://code.claude.com/docs/en/env-vars)), so that is the effective threshold there. Setting it also changes what your status line means: `used_percentage` still measures against the model's full window, so the context bar no longer tells you when compaction will fire.

`CLAUDE_CODE_EFFORT_LEVEL` is `high` because K3 answers better with more reasoning; it also spends more of your quota per turn, so drop it to `medium` if you are optimising for throughput ([models & effort](../reference/models-and-effort.md)).

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

Account detection can't fix this, because you can hold a Max seat and still run a session against another endpoint. So [`profile-switch.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/assets/statusline/profile-switch.sh) decides on the provider first, reading `ANTHROPIC_BASE_URL` (and the `CLAUDE_CODE_USE_*` variables that Bedrock, Vertex and Foundry set) on every render, and selects a profile with no usage widgets at all.

*Observed on 2.1.226: Claude Code passes the settings-file `env` block into the status-line subprocess, so a base URL set in `settings.json` — never exported to the shell — is visible to the launcher. That is undocumented, and the whole mechanism rests on it.* **Confirm it once:** with the alt session running, the usage line should show no percentages at all. If it shows a 5h or 7d bar, those numbers are your Anthropic account, not your provider's — and `./setup.sh --check` will not catch it, because it only inspects the command string. If that profile is missing it prints a hint rather than falling back.

That launcher and its profiles come from this repo's `setup.sh` — clone [claude-code-guide](https://github.com/bogdanmatasaru/claude-code-guide) and run `./setup.sh` from the clone root. It is written for macOS, and it is a full bootstrap rather than a status-line installer: Xcode Command Line Tools, Homebrew, Ghostty, a font, Node, `gh`, `jq` and `ccstatusline`, plus PATH and alias lines appended to `~/.zshrc` — [the full list](../environment/bootstrap-setup.md). Try `--dry-run` first, or `--no-shell` to leave your rc file alone. If you only want the status line, the [status-line assets](https://github.com/bogdanmatasaru/claude-code-guide/tree/main/assets/statusline) has a copy-five-files alternative. It also repoints a `statusLine` that calls `ccstatusline` directly.

One caveat if you followed the two-directory arrangement above: **`setup.sh` and `--check` only ever read `~/.claude/settings.json`.** They install the launcher and its profiles, which is what the alt directory needs, but they will not wire it into `~/.claude-alt/settings.json` and `--check` will not notice if it is missing there — that block is yours to add. `./setup.sh --check` reports whether your **main** `settings.json` routes through the launcher — worth running, because a status line that never invokes the launcher is the one case where none of this protects you.

For real quota on another provider, use that provider's own console or CLI.

## Troubleshooting

| Symptom | Cause |
| --- | --- |
| `/status` shows no `Anthropic base URL` line at all | The settings file wasn't read — usually invalid JSON, which Claude Code ignores silently. Run `python3 -m json.tool ~/.claude-alt/settings.json` for the line and column of the error, and confirm the file is `settings.json` inside the directory `CLAUDE_CONFIG_DIR` points at |
| Main chat works, subagents die instantly | Tier aliases not repointed — something asked for `sonnet` or `haiku` and it was sent literally |
| `401` naming a plan or tier | Your subscription doesn't include that model, or you used a key from the provider's other platform |
| Model ID "does not exist" | A Claude Code-only spelling sent to the raw API, or a model version name instead of an ID |
| `ANTHROPIC_API_KEY` set but ignored, no prompt | You declined it once; re-enable with **Use custom API key** in `/config` |
| Context bar shows `/200k` on a large-context model | Unrecognised model ID; see [Context window](#context-window) |
| Startup warns that auth may not work | A saved `/login` and a custom credential are both present. On macOS a separate `CLAUDE_CONFIG_DIR` does not clear this — confirm with `/status` which credential is active, or `/logout` |
| WebSearch produces nothing useful | It can't work here; deny it and add an MCP search server |
| Status line shows usage that looks like your Claude plan | The launcher isn't wired in, or the wrong profile is active — run `./setup.sh --check` |

Verify the endpoint took effect with `/status`, which shows an `Anthropic base URL` line only when one is set.

## Related

- [Models, effort & thinking](../reference/models-and-effort.md) — aliases and effort levels
- [settings.json](../reference/settings.md) — where the `env` block goes
- [Monitor cost & limits](../environment/monitoring-cost-ratelimits.md) — the Anthropic-side tooling this page replaces

---

*Not affiliated with, endorsed by, or sponsored by Anthropic or Moonshot AI. "Claude" and "Claude Code" are trademarks of Anthropic, PBC; "Kimi" and "Kimi Code" are trademarks of Moonshot AI. Other product names are the property of their respective owners, and are used for identification only. This configuration is not supported by Anthropic, and nothing here modifies your agreement with any provider.*
