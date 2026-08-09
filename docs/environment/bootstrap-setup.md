---
title: One-command setup (setup.sh)
description: Bootstrap a complete Claude Code + Ghostty environment on a fresh Mac with one idempotent, network-tolerant script.
---
# One-command setup (setup.sh)

[`../../setup.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/setup.sh) takes a clean Mac to a working Claude Code environment in one command — terminal, runtime, CLI, fonts, and configs — and it's safe to re-run.

## What it does

The script runs everything from zero, in order:

1. **Xcode Command Line Tools** — installs git and compilers, then waits (up to ~30 min) for Apple's installer to finish. This is the one step that aborts the whole run if it fails.
2. **Homebrew** — installs it if missing and persists `brew shellenv` to your `~/.zshrc`.
3. **Ghostty** — `brew install --cask ghostty`, the recommended terminal. An existing hand-installed `Ghostty.app` is adopted into Homebrew where possible, and replaced with `--force` only if that fails.
4. **JetBrains Mono** — `brew install --cask font-jetbrains-mono`.
5. **Node.js** — the runtime for Claude Code and many projects.
6. **GitHub CLI (`gh`)** — for pull requests and the GitHub MCP.
7. **jq** — used by the example hooks and the status line.
8. **Claude Code** — via the official native installer (`curl -fsSL https://claude.ai/install.sh | bash`), with an npm fallback. Persists `~/.local/bin` on your PATH.
9. **Ghostty config** — writes `~/.config/ghostty/config` (Catppuccin auto dark/light, JetBrains Mono).
10. **Global Claude config** — writes `~/.claude/settings.json` and `~/.claude/CLAUDE.md`, but only if they don't already exist.
11. **Status line** — installs [ccstatusline](https://github.com/sirmalloc/ccstatusline) globally with `npm install -g ccstatusline@2` and writes its config (model · context · 5h/weekly limits · branch · session · disk), plus a no-Node `statusline.sh` alternative. The settings.json points at it.
12. **Shell aliases** — adds `cc`, `ccc`, `ccp` to `~/.zshrc`.
13. **A second provider** — *asks* whether you want one, and does nothing unless you say yes. See [below](#the-second-provider-question).
14. **Validation** — runs `validate()` to report what's in place and what's missing.

## Flags

| Flag | Effect |
| --- | --- |
| `--dry-run` | Show what it would do, change nothing. |
| `--check` | Only validate an existing environment (no install). Exits non-zero if anything is missing — useful in CI. |
| `--no-ask` | Skip the optional second-provider question entirely. |
| `--no-shell` | Don't touch your shell rc (no PATH lines, no aliases). |
| `--help` / `-h` | Print usage and exit. |

## Step-by-step on a fresh Mac

The fastest path — **one command**, nothing installed first (not even git; the script
pulls everything in):

```bash
curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash
```

[`install.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/install.sh)
downloads this repo (via a tarball, so git isn't required yet) and runs `setup.sh` for
you. Flags pass straight through, e.g. preview without changing anything:

```bash
curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash -s -- --dry-run
```

> [!TIP]
> Piping a script to `bash` runs code from the internet. You can read
> [`install.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/install.sh)
> and [`setup.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/setup.sh)
> first, or use `--dry-run` to see every action before anything is written.

Prefer to clone and run it yourself? Same result:

```bash
git clone https://github.com/bogdanmatasaru/claude-code-guide.git
cd claude-code-guide
./setup.sh
```

Then:

1. Open **Ghostty** (Cmd+Space → Ghostty). Open a **new** window so the updated `~/.zshrc` is sourced.
2. Type `claude` and authenticate (log in via the browser).
3. Enter a project and run `/init` (or the `/project-onboard` skill) to generate a `CLAUDE.md` and propose permissions.

> [!TIP]
> Want to see exactly what will happen before committing? Run `./setup.sh --dry-run` first — it prints every action and writes nothing. The one thing it cannot show in full is the optional second-provider step — it reports only that the step would be offered; what that step writes is documented [below](#the-second-provider-question).

## The second-provider question

At the end of the run the script asks:

> [!WARNING]
> Everything a session on another provider reads is sent to **that provider's** servers, not Anthropic's — the files it opens, the diffs it reviews, the commands it runs. Check your employer's policy and the provider's data-retention terms before pointing this at work code.

```text
> Second provider (optional)

  Claude Code can also run against a non-Anthropic endpoint, in a separate
  config directory, so your Claude setup stays exactly as it is.
  You will need an API key from that provider. Docs: docs/guides/non-anthropic-endpoints.md
  Set one up now? [y/N]
```

Answer `n`, press Enter, or wait 60 seconds and nothing happens. `--no-ask` skips the question entirely.

Answer `y` and it asks **five** things: base URL, API key, model ID, context window, and a name for the alias. Three of them come with defaults, shown in brackets, and those defaults describe **Kimi Code on the Moderato tier** (`https://api.kimi.com/coding/`, `k3-256k`, `262144`) — pressing Enter accepts them, so type your own values if you use a different provider or tier. Those follow-up prompts wait up to two minutes each; nothing is written until all five answers are in, and any invalid answer aborts the step having written nothing.

**It writes more than your five answers**, and tells you so afterwards: your model ID goes into all six tier variables, so subagents don't die asking for a model your provider has never heard of; `WebSearch` is denied, because it runs on Anthropic's backend and cannot work elsewhere; and `CLAUDE_CODE_EFFORT_LEVEL` is set to `high`, which answers better and **spends more of your provider quota per turn**. Edit `~/.claude-alt/settings.json` afterwards if you want different choices.

**What that gets you.** Two commands instead of one. `claude` is Claude, exactly as before. The alias — `alt` by default — is the same client against a different provider, with its own history and its own settings.

That second directory **starts empty**: your skills, plugins, MCP servers and `CLAUDE.md` are not copied into it. Everything still works there, but you have to put them in yourself.

The status line picks a provider-aware profile with no usage widgets. **Confirm that once:** in an `alt` session the usage line should show no percentages at all. If it shows a 5h or 7d bar, those numbers are your Anthropic account rather than your provider's — and `./setup.sh --check` will not catch it, because it only ever inspects `~/.claude`.

**What you need before saying yes.** An account with a provider that speaks the Anthropic protocol, an API key from it, and the model ID and context size for your plan. [Run against a non-Anthropic endpoint](../guides/non-anthropic-endpoints.md) covers all three, and — more importantly — what stops working once you do this. The script cannot tell you that; several Claude Code features go quiet on another provider without an error.

**Why it is a question and not a flag.** This step writes an inference endpoint and a credential. This script is distributed by `curl … | bash`, and a bootstrap that silently redirected someone's model traffic would be a way to turn one bad commit into everyone's problem. So it is offered only when a human is at a terminal, the default answer is no, and it never touches an existing `~/.claude-alt/settings.json`.

It reads `/dev/tty` rather than standard input, which is what makes it work at all when the script itself arrives over a pipe, and it is skipped whenever output is redirected — a log file, a pipe, a `nohup`, most CI runners. It also gives up after 60 seconds without an answer.

That covers the ordinary cases, and it is worth being precise about the limit: **nothing based on file descriptors can tell a person from automation that deliberately allocates a terminal.** A wrapper built on `script(1)` looks exactly like a human to any such test. If you are scripting an install and want a guarantee rather than a heuristic, pass `--no-ask`.

**Where the key goes.** `~/.claude-alt/settings.json`, in **plaintext**, mode `600`. That stops other accounts on the machine reading it; it is not encryption, and unlike your Claude login it is not in the macOS Keychain — anything running as you can read it. If the script creates `~/.claude-alt` it is mode `700`; if you made that directory earlier by hand it keeps whatever permissions it had, so check with `ls -ld ~/.claude-alt`. The key is never echoed as you type it and never reaches your shell history.

Re-running `setup.sh` will not overwrite it — so to change the key, model or context afterwards, edit the file directly. To undo the whole thing: `rm -rf ~/.claude-alt` and delete the `alias alt=…` line from `~/.zshrc`; that also removes the alt session history, which is separate from your Claude one.

**Prefer not to type a key into a script you piped from the internet?** Answer `n`. The [manual six-step path](../guides/non-anthropic-endpoints.md#from-zero-to-working) produces the same file and explains each value as you set it.

### After you answer yes

The script has done its part; the provider side and the first launch are still yours:

1. Open a **new** terminal, so the alias exists.
2. `cd` into a project first, then run `alt` — the first launch asks whether you trust the folder, and you do not want to trust your whole home directory.
3. Work through the first-run wizard (theme, folder trust), then **approve the "use custom API key" prompt**. Decline it once and the key is ignored silently, and permanently, until you re-enable it under `/config`.
4. On macOS you will also see a startup warning that authentication may not work. It is expected: credentials live in the Keychain, which a separate config directory does not separate.
5. Run `/status`. An `Anthropic base URL` line with your provider's URL is the proof it took effect.
6. Read [what stops working](../guides/non-anthropic-endpoints.md#what-stops-working) — around ten Claude Code features degrade on another provider, most of them without an error.

## What it writes

| Path | Contents |
| --- | --- |
| `~/.config/ghostty/config` | Ghostty theme, font, padding, cursor settings. |
| `~/.claude/settings.json` | Created if absent. If it exists it is **not** replaced, but a `statusLine` key is inserted — or a bare `ccstatusline` call upgraded to the launcher — after backing the file up to `settings.json.bak.<epoch>`. A `statusLine` you wrote yourself is left alone. |
| `~/.claude/CLAUDE.md` | Global preferences (only if absent). |
| `~/.config/ccstatusline/settings.json` | Status-line layout (only if absent). |
| `~/.config/ccstatusline/settings.consumer.json` | Layout for Pro/Max accounts (only if absent). |
| `~/.config/ccstatusline/settings.enterprise.json` | Layout for Enterprise/Team accounts (only if absent). |
| `~/.config/ccstatusline/settings.custom-endpoint.json` | Layout for sessions on another provider — no usage widgets (only if absent). |
| `~/.config/ccstatusline/profile-switch.sh` | The launcher that picks between them. **Refreshed on every run**, so fixes propagate; a diverging copy is backed up to `profile-switch.sh.bak` first. |
| `~/.claude-alt/settings.json` | Only if you answered yes to the second-provider question. Mode `600` — it holds an API key. |
| `~/.claude/statusline.sh` | No-Node status-line alternative (only if absent). |
| `~/.zshrc` | `brew shellenv`, `~/.local/bin` on PATH, the `cc` / `ccc` / `ccp` aliases — and the second-provider alias if you asked for one. |
| `~/claude-code-guide/` | Only when installed via the `curl … \| bash` one-liner: `install.sh` downloads the repo there. Set `CLAUDE_GUIDE_DIR` to put it elsewhere. |

The aliases: `cc` = `claude`, `ccc` = `claude --continue` (resume the last session), `ccp` = `claude --permission-mode plan`.

## Idempotency & network tolerance

The script is **safe to re-run**. It backs up a file only when its contents would actually change, skips anything already installed, and adds each `~/.zshrc` line exactly once (marker-checked).

It also **does not abort on a failed install**. If a `brew install` fails (e.g. no network), it warns and keeps going. Because the script is idempotent, you just re-run it later to finish only what's left.

> [!NOTE]
> The script deliberately avoids `set -e`. One failing step must not kill the whole bootstrap — `validate()` at the end reports precisely what's still missing.

## Validate anytime

```bash
./setup.sh --check    # validate the environment (non-zero exit if broken)
claude doctor         # check the Claude Code install itself
```

`--check` confirms `brew`, `node`, `claude`, Ghostty and its config, that `~/.claude/settings.json` is valid JSON, that the status-line profiles are present and parse, that the custom-endpoint profile carries no usage widget, and whether `settings.json` routes the status line through the launcher. It reports your detected account type too. It does **not** look at `~/.claude-alt` — nothing validates the second provider for you.

## The test suite

The script ships with a **test suite (93 checks)** that runs `setup.sh` in a temporary `HOME` with mocked commands — no changes to your real system:

```bash
./test/run-tests.sh
```

See [`../../test/run-tests.sh`](https://github.com/bogdanmatasaru/claude-code-guide/blob/main/test/run-tests.sh). It covers syntax and shellcheck, a full fresh-Mac run, config writes and valid JSON, PATH persistence, idempotency (a second run makes zero `.bak` files), `--check` on both healthy and broken environments, clean `--help` output, network-failure tolerance, and that `--dry-run` writes nothing.

## Updating

The script is also your **update command**. Re-run the one-liner anytime — it pulls the latest version of this repo and re-applies everything idempotently:

```bash
curl -fsSL https://raw.githubusercontent.com/bogdanmatasaru/claude-code-guide/main/install.sh | bash
```

Cloned it instead? `cd claude-code-guide && git pull && ./setup.sh`.

Updating is safe because the script is idempotent: it skips what's already installed, backs up a file only when its contents change, and merges in new pieces — for example, it adds the `statusLine` to an existing `~/.claude/settings.json` if a newer version introduced one. Your own customizations (an existing `statusLine`, settings, or configs) are left untouched.

## Next steps

- Tune your terminal further in [Terminal & Ghostty setup](./terminal-and-ghostty.md).
- Keep an eye on spend with [Monitor cost & rate limits](./monitoring-cost-ratelimits.md).
