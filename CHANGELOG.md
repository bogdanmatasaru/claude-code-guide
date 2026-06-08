# Changelog

All notable changes to this guide are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and the project content tracks
Claude Code releases.

## [Unreleased]

### Added
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
- One-command `setup.sh` bootstrap (Ghostty + Claude Code) with a 32-assertion test
  suite, plus cost / rate-limit monitoring guidance.
- Trust scaffolding: LICENSE, CONTRIBUTING, Code of Conduct, issue/PR templates, CI.
- **Account-aware status line.** A launcher (`assets/statusline/profile-switch.sh`)
  auto-selects a `ccstatusline` profile by the account's `subscriptionType`: an
  **enterprise/team** profile (5h reset timer + monthly credit) and a **consumer**
  profile (5h/7d usage bars). `setup.sh` installs both profiles + the launcher, wires
  `statusLine` to it, and upgrades older installs that still point at plain
  `ccstatusline`. `--check` reports the detected account and validates the profiles.

### Fixed
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
