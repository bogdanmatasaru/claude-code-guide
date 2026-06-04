---
name: project-onboard
description: Set up a project for smooth work with Claude Code — generate/update CLAUDE.md, propose an allowlist of permissions so it stops asking on repetitive commands, and suggest relevant MCP servers. Use when you first open a new repo with Claude Code.
---

# project-onboard

Goal: after `setup.sh` has prepared the *environment* (Ghostty + Claude Code
installed), this skill prepares the *current project* so work is smooth from the
first message.

Run the steps in order. Be concise with the user; show what you did, don't explain
the theory.

## 1. Understand the repo

- Detect the stack: look for `package.json`, `pyproject.toml`, `go.mod`,
  `Cargo.toml`, `Makefile`, `*.csproj`, etc.
- Identify the build / test / lint / run commands (from scripts, Makefile, CI).
- Note obvious conventions (formatter, folder structure, test framework).

## 2. CLAUDE.md

- If `CLAUDE.md` does **not** exist: run the equivalent of `/init` — generate a
  short one with: the key commands (build/test/lint/run), a brief structure
  overview, code conventions, and non-obvious things to know. Keep it tight (not
  an essay).
- If it **exists**: read it, propose additions only for what's missing and useful.
- Ask for confirmation before writing/committing.

## 3. Permissions (fewer prompts)

- From the commands found in step 1, propose an allowlist in `.claude/settings.json`
  for the safe & repetitive ones (e.g. `Bash(npm run test:*)`, `Bash(npm run build)`,
  `Bash(git status)`, `Bash(git diff:*)`).
- Do NOT add destructive commands (deploy, push --force, rm). Read/test/build only.
- Write to `.claude/settings.json` (project), not the global settings.

## 4. Relevant MCP servers (optional)

- If the project uses GitHub and `gh` is authenticated, suggest the GitHub MCP.
- If it's a web/UI project, mention a browser MCP for visual verification.
- Only suggest + show the command; don't install without an OK.

## 5. Final summary
Show a short list:
- what was created/changed (CLAUDE.md, settings.json),
- the detected test/build commands,
- the recommended next step (e.g. "run /code-review after your first changes").

Rules: confirm before writing to versioned files; don't touch the user's global
settings; don't invent commands — verify they exist in the repo.
