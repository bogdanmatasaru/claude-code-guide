# Contributing

Thanks for helping make this the best Claude Code reference on the internet. This
guide stays valuable only if it stays **accurate** and **current** — and that's a
team sport. Contributions of every size are welcome.

## What we're looking for

- **Corrections** — anything inaccurate or out of date (Claude Code moves fast).
- **New tips & recipes** — a workflow, optimization, or use case that earned its keep.
- **Assets** — a `CLAUDE.md` template, slash command, hook, skill, or settings example.
- **Clarity** — making a confusing section easier for a first-timer.

## How the repo is organized (so PRs stay small)

Everything is **modular — one file per topic** — so you can edit a small file
without merge conflicts:

| Path | What lives here |
|---|---|
| `docs/getting-started/` | Tutorials (learn Claude Code from zero) |
| `docs/guides/` | How-to recipes (task-oriented) |
| `docs/reference/` | One file per feature (cli, hooks, mcp, skills, …) |
| `docs/explanation/` | Mental models (the "why") |
| `docs/environment/` | Terminal/Ghostty + the `setup.sh` bootstrap |
| `assets/` | Copy-paste templates: `claude-md/`, `commands/`, `hooks/`, `skills/`, `settings/` |

The Markdown in `docs/` is the **single source of truth** — the VitePress site is
generated from those same files, so you only ever edit one copy.

## Ground rules

1. **Cite official docs.** When you state a fact about Claude Code, link the relevant
   page on <https://code.claude.com/docs>. If sources disagree, say so.
2. **Note version caveats.** Features change between releases — mention the minimum
   version when it matters (e.g. "v2.1.83+").
3. **English, friendly, concise.** Write for a developer using Claude Code for the
   first time. Lead with the simple case; defer the advanced bits.
4. **No destructive defaults.** Permission allowlists and hooks in `assets/` must
   never auto-approve dangerous actions (deploy, `push --force`, `rm`).
5. **Keep it copy-paste-ready.** Code blocks should run as-is.

## Submitting a change

```bash
# 1. Fork & branch
git checkout -b fix/hooks-event-names

# 2. Make your edit (one topic per PR keeps review fast)

# 3. Check it locally (optional but appreciated)
npm install
npm run docs:build        # VitePress builds + checks internal links
npm run lint:md           # markdownlint

# 4. Open a PR with a clear title and a one-line "why"
```

CI runs markdownlint + a link check on every PR. Green CI + a citation = fast merge.

## Good first issues

New here? These are friendly entry points (look for the `good first issue` label):

- Add a `CLAUDE.md` template for a stack we don't cover yet (Rust, Go, Django, …).
- Add a useful hook example to `assets/hooks/`.
- Translate one reference page's examples to another framework.
- Fix a broken link or a typo.
- Add a real-world workflow you use to `docs/best-practices.md`.

## A note for maintainers (growth & freshness)

A reference repo lives or dies by **freshness**. Keep the "last updated" badge
current, update content on each Claude Code release, and respond to PRs quickly —
prompt responses are themselves a trust signal. When promoting the repo, post a
plain link (not "Show HN") in the 12–17 UTC window, share in r/ClaudeCode and the
Anthropic Discord, and ask a third party (not yourself) to submit it to
`awesome-claude-code`.

By contributing, you agree your work is licensed under the repo's [MIT License](LICENSE).
