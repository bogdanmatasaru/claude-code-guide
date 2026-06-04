---
title: MCP (Model Context Protocol)
description: Connect Claude Code to external tools and data with MCP — transports, claude mcp add, scopes, and how to keep it lean.
---
# MCP (Model Context Protocol)

The Model Context Protocol is an open standard for connecting Claude Code to external tools, databases, and APIs. Connect a server when you find yourself pasting data from another system — an issue tracker, a database, a monitoring dashboard — and Claude can read and act on it directly instead.

## Transports

| Transport | When to use | Notes |
| --- | --- | --- |
| **HTTP** | Remote cloud services | Recommended. Uses `streamable-http`; supports OAuth. |
| **SSE** | Legacy remote servers | Deprecated — use HTTP where available. |
| **stdio** | Local processes / custom scripts | Runs a command on your machine. |
| **WebSocket** | Servers that push events unprompted | Config-only (`type: "ws"`); no OAuth, header auth only. |

## Adding servers

All flags (`--transport`, `--header`, `--env`, `--scope`) go **before** the name; `--` separates the name from a stdio command.

```bash
# Remote HTTP server (recommended)
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# HTTP with an auth header
claude mcp add --transport http github https://api.githubcopilot.com/mcp/ \
  --header "Authorization: Bearer YOUR_GITHUB_PAT"

# Local stdio server with an env var
claude mcp add --transport stdio --env AIRTABLE_API_KEY=KEY airtable \
  -- npx -y airtable-mcp-server
```

Other commands:

```bash
claude mcp add-json weather '{"type":"http","url":"https://api.weather.com/mcp"}'
claude mcp add-from-claude-desktop   # import from Claude Desktop (macOS/WSL)
claude mcp list                      # list servers
claude mcp get github                # details for one server
claude mcp remove github             # remove a server
claude mcp serve                     # run Claude Code itself as an MCP server
```

Run `/mcp` inside a session to complete OAuth logins, check status, and clear credentials.

## Scopes

| Scope | Loads in | Shared | Stored in |
| --- | --- | --- | --- |
| **local** (default) | Current project only | No | `~/.claude.json` |
| **project** | Current project only | Yes, via version control | `.mcp.json` in project root |
| **user** | All your projects | No | `~/.claude.json` |

```bash
claude mcp add --transport http hubspot --scope user https://mcp.hubspot.com/anthropic
```

> [!IMPORTANT]
> Project-scoped servers from `.mcp.json` require your approval before they run — Claude Code prompts before first use. Review them before trusting a repo.

`.mcp.json` supports environment-variable expansion: `${VAR}` and `${VAR:-default}` in `command`, `args`, `env`, `url`, and `headers`. This lets teams share one config while keeping secrets and machine-specific paths out of version control.

```json
{
  "mcpServers": {
    "api": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": { "Authorization": "Bearer ${API_KEY}" }
    }
  }
}
```

## High-value servers

| Server | Gives Claude |
| --- | --- |
| **GitHub** | Issues, PRs, code review |
| **Playwright / Puppeteer** | Browser automation, screenshots, E2E tests |
| **Sentry** | Error and stack-trace data |
| **Postgres / databases** | Schema and query access |
| **Filesystem** | Scoped file access |

## Keep it lean

Tool search is on by default and defers tool definitions until needed, so adding servers barely touches your context window. Even so, more servers mean more tools competing for Claude's attention.

> [!WARNING]
> Too many active MCP servers degrade performance and eat context. Keep roughly **3–6 active** at a time.

A CLI tool is often more context-efficient than an MCP server. The official guidance: prefer the `gh` CLI over the GitHub MCP for token efficiency. See [cost optimization](../guides/cost-optimization.md) for the full tradeoff.

**Source:** [code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp)
