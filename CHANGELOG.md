# Changelog

All notable changes to this guide are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and the project content tracks
Claude Code releases.

## [Unreleased]

### Added
- **`setup.sh` can configure a second provider**, as an opt-in question at the end
  of the run: base URL, key, model ID, context size, then it writes
  `~/.claude-alt/settings.json` (mode `600`, key never echoed) and an alias. It is
  offered only at an interactive terminal — the script ships via `curl | bash`, so
  it reads `/dev/tty` rather than stdin and additionally requires stdout to be a
  terminal — which keeps it out of the way under `--dry-run`, redirected output and
  most CI. It cannot distinguish a person from automation that allocates a pty, so
  `--no-ask` exists as the actual guarantee. Answering requires typing `yes`; every
  input is validated against an allowlist and the file is written through a JSON
  encoder, so a pasted base URL or model ID cannot inject a `hooks` block; symlinks
  are refused; and an existing config is never touched.
- **Non-Anthropic endpoints guide** — how to point Claude Code at another provider
  with `ANTHROPIC_BASE_URL`, which features stop working (cited), and the tier-alias
  variables that most setups miss. Worked example: Kimi Code.
- **Third status-line profile** for sessions on a custom `ANTHROPIC_BASE_URL`, with no
  usage widgets at all. Without `rate_limits` in the payload, `ccstatusline`'s usage
  widgets fall back to Anthropic's usage API and render *your Anthropic quota* beside
  another provider's model. `profile-switch.sh` now decides on the provider before the
  account, and fails closed when the profile is missing.
- `verified:` frontmatter stamps with a CI check (`npm run lint:stamps`) that warns at
  30 days and fails at 90, so pages documenting fast-moving behaviour get re-read or
  deleted rather than quietly going stale.
- Full English rewrite as a Markdown-native, beginner→expert reference.
- Diátaxis structure: `getting-started/` (tutorials), `guides/` (how-to),
  `reference/` (one file per feature), `explanation/` (mental models),
  `environment/` (terminal + bootstrap).
- Copy-paste **asset library**: `CLAUDE.md` templates, slash commands, hooks,
  settings examples, and shareable skills.
- **Learning path** with a diagnostic that routes you to the right starting point.
- **Cheatsheet** — a single-page, Cmd-F-friendly reference.
- **VitePress** documentation site generated from the same Markdown, with Mermaid
  diagrams and full-text search.
- One-command `setup.sh` bootstrap (Ghostty + Claude Code) with a 93-assertion test
  suite, plus cost / rate-limit monitoring guidance.
- Trust scaffolding: LICENSE, CONTRIBUTING, Code of Conduct, issue/PR templates, CI.
- **Account-aware status line.** A launcher (`assets/statusline/profile-switch.sh`)
  auto-selects a `ccstatusline` profile by the account's `subscriptionType`: an
  **enterprise/team** profile (5h reset timer + monthly credit) and a **consumer**
  profile (5h/7d usage bars). `setup.sh` installs both profiles + the launcher, wires
  `statusLine` to it, and upgrades older installs that still point at plain
  `ccstatusline`. `--check` reports the detected account and validates the profiles.

### Fixed
- **Bedrock / Vertex / Foundry sessions showed the Anthropic quota.** Those backends
  set no `ANTHROPIC_BASE_URL`, so a base-URL-only provider check waved them through to
  the consumer profile. The launcher now also gates on `CLAUDE_CODE_USE_*`.
- **`setup.sh` left most existing installs on the leaking wiring.** It only repointed a
  `statusLine` whose command was the exact string `ccstatusline`, so
  `/opt/homebrew/bin/ccstatusline` and `npx -y ccstatusline@latest` — the forms the
  tool's own README and Claude Code's `/statusline` setup produce — were classified as
  custom and left alone. Classification is now by substance.
- `--check` now inspects `statusLine.command` itself, and fails when it calls
  `ccstatusline` without going through the launcher. It also validates the
  custom-endpoint profile's JSON and asserts it carries no usage widget.
- CI now shellchecks every shipped script, including `assets/statusline/*.sh`, which
  nothing linted before.
- `setup.sh` backs up a locally-modified `profile-switch.sh` before refreshing it,
  instead of overwriting edits silently.
- **Enterprise/Team status line showing `[Timeout]`.** Those seats return `null`
  `five_hour` / `seven_day` rate-limit buckets, so `ccstatusline`'s usage widgets
  rendered `[Timeout]`. The enterprise profile uses widgets that have real data, and
  the launcher injects a synthetic `rate_limits.five_hour.resets_at` (from
  `ccstatusline`'s block-cache) so the 5h timer and monthly credit both render stably
  instead of poisoning the shared usage fetch.

### Changed
- Translated the entire guide and the `setup.sh` bootstrap to professional English.

### Removed
- The legacy Romanian `claude-code-ghid.html` / `.pdf` (content extracted into the
  new English docs).

[Unreleased]: https://github.com/bogdanmatasaru/claude-code-guide
