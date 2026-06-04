---
title: CLI reference
description: The claude command — interactive and headless modes, sessions, the most useful flags, output formats, and claude doctor.
---
# CLI reference

The `claude` command is the entry point for Claude Code in your terminal. This page covers how to launch it, run one-off queries, manage sessions, and the flags you'll reach for most.

## Launching Claude

```bash
claude                      # start an interactive session
claude "fix the build"      # start interactive with an initial prompt
claude -p "fix the build"   # headless: print the result and exit
cat error.log | claude -p "explain this"   # pipe input on stdin
```

Interactive mode keeps a REPL open so you can chat, approve tools, and iterate. Headless mode (`-p` / `--print`) runs the query, prints the result, and exits — ideal for scripts, CI, and git hooks.

## Sessions

Each conversation is a resumable session scoped to the directory you started it in.

| Flag | What it does |
| --- | --- |
| `-c`, `--continue` | Resume the most recent session in this directory |
| `-r`, `--resume <id\|name>` | Resume a specific session by ID or name |
| `--fork-session` | Resume but branch into a new session, leaving the original intact |
| `--session-id <uuid>` | Start (or attach to) a session with a fixed ID |
| `-n`, `--name <name>` | Name the session for easy `--resume` later |
| `--from-pr <n>` | Start a session seeded from a pull request |

## Most useful flags

| Flag | Purpose |
| --- | --- |
| `--model <alias>` | Pick the model (see [models & effort](./models-and-effort.md)) |
| `--effort <level>` | Reasoning effort: `low`…`max` |
| `--permission-mode <mode>` | Start in a [permission mode](./permission-modes.md) |
| `--allowedTools` / `--disallowedTools` | Pre-approve or block specific tools |
| `--add-dir <path>` | Grant access to an extra directory |
| `--agents '<json>'` | Define subagents inline as JSON |
| `--mcp-config <file>` | Load MCP servers from a config file |
| `--append-system-prompt[-file]` | Append to the system prompt |
| `--max-turns <n>` | Cap agentic turns (headless safety) |
| `--max-budget-usd <n>` | Stop once spend hits a dollar limit |
| `--worktree` / `-w` | Run in a fresh git worktree |
| `--bg` | Launch as a background agent |
| `--bare` | Fast, minimal startup |
| `--dangerously-skip-permissions` | Skip all permission checks (see [permission modes](./permission-modes.md)) |

## Output formats

For `-p`, choose how results are emitted with `--output-format`:

| Value | Use case |
| --- | --- |
| `text` | Plain text (default) |
| `json` | Single structured JSON object — parse in scripts |
| `stream-json` | Newline-delimited JSON events, streamed live |

```bash
claude -p "list TODOs" --output-format json | jq .result
```

## Diagnostics

```bash
claude doctor     # check install health, auth, and config
claude --version  # print the installed version
```

> [!TIP]
> `claude --help` lists common flags but is **not** exhaustive. Consult the official [CLI reference](https://code.claude.com/docs/en/cli-reference) for the full set.

> [!NOTE]
> Sessions are directory-scoped. `--continue` only finds sessions started in your current working directory.

**Source:** [CLI reference](https://code.claude.com/docs/en/cli-reference)
