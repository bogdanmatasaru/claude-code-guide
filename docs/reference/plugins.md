---
title: Plugins & marketplaces
description: Bundle skills, agents, hooks, and MCP servers into installable plugins, and share them through marketplaces.
---
# Plugins & marketplaces

A plugin packages skills, agents, hooks, and MCP servers into one installable, versioned directory. Use plugins to share functionality with your team or community, reuse it across projects, and ship updates — where standalone `.claude/` config is best for personal, single-project tweaks.

## What a plugin bundles

A plugin is a directory with a `.claude-plugin/plugin.json` manifest plus component folders at the **root** (not inside `.claude-plugin/`).

```text
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/         # <name>/SKILL.md — invoked as /my-plugin:<name>
├── agents/         # custom subagent definitions
├── hooks/
│   └── hooks.json  # event handlers
├── commands/       # legacy flat-file commands (use skills/ for new plugins)
└── .mcp.json       # bundled MCP servers, started when enabled
```

> [!WARNING]
> Only `plugin.json` belongs inside `.claude-plugin/`. Putting `skills/`, `agents/`, or `hooks/` there is the most common mistake — they must sit at the plugin root.

Plugin skills are always namespaced as `/plugin-name:skill-name` to prevent conflicts between plugins.

## plugin.json

```json
{
  "name": "my-plugin",
  "description": "Shown in the plugin manager when browsing.",
  "version": "1.0.0",
  "author": { "name": "Your Name" }
}
```

| Field | Required | Purpose |
| --- | --- | --- |
| `name` | Yes | Unique identifier and skill namespace. |
| `description` | Yes | Shown when browsing or installing. |
| `version` | No | Bump to release an update. Omit and git distribution uses the commit SHA. |
| `author` | No | Attribution. |

## Install and marketplace commands

```bash
/plugin marketplace add anthropics/claude-plugins-community  # add a marketplace
/plugin install mcp-server-dev@claude-plugins-official        # install name@marketplace
/reload-plugins                                               # pick up changes in-session
```

## Official vs community marketplaces

| Marketplace | How to access | What it holds |
| --- | --- | --- |
| **`claude-plugins-official`** | Built in — available automatically | Curated plugins maintained by Anthropic |
| **`claude-community`** | `/plugin marketplace add anthropics/claude-plugins-community` | Reviewed third-party submissions, installed as `@claude-community` |

> [!NOTE]
> The official marketplace is curated at Anthropic's discretion; there's no application form. Community submissions go through review at [claude.ai/settings/plugins/submit](https://claude.ai/settings/plugins/submit).

## Building one (brief)

1. Scaffold: `claude plugin init my-tool`, or create `my-plugin/.claude-plugin/plugin.json` by hand.
2. Add components at the root: a [skill](./skills.md) in `skills/<name>/SKILL.md`, a [subagent](./subagents.md) in `agents/`, hooks in `hooks/hooks.json`, [MCP servers](./mcp.md) in `.mcp.json`.
3. Test locally without installing:

   ```bash
   claude --plugin-dir ./my-plugin        # load a local directory (or a .zip)
   claude --plugin-url https://host/p.zip # load a hosted archive for one session
   ```

   Run `/reload-plugins` after edits. Verify skills with `/plugin-name:skill`, agents in `/agents`.
4. Validate before publishing:

   ```bash
   claude plugin validate
   ```

Use `${CLAUDE_PLUGIN_ROOT}` to reference bundled files in MCP and hook configs so paths resolve regardless of where the plugin is installed.

**Source:** [code.claude.com/docs/en/plugins](https://code.claude.com/docs/en/plugins)
