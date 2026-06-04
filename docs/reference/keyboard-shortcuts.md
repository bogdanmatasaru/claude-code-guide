---
title: Keyboard shortcuts
description: Control, editing, and macOS Option-key shortcuts for Claude Code's interactive mode, plus multiline input.
---
# Keyboard shortcuts

Claude Code's interactive REPL is driven by keyboard shortcuts. This page groups the most useful ones and covers how to enter multiline input.

## Control

| Shortcut | Action |
| --- | --- |
| `Ctrl+C` | Interrupt the current action / clear the input line |
| `Ctrl+D` | Exit Claude Code |
| `Esc` | Interrupt the current turn |
| `Esc` `Esc` | Open the rewind menu (when the input is empty) |
| `Ctrl+O` | Open the transcript viewer |
| `Ctrl+R` | Reverse-search command history |
| `Ctrl+B` | Background the running task |
| `Ctrl+T` | Show the task list |
| `Shift+Tab` | Cycle permission mode (see [permission modes](./permission-modes.md)) |

## Editing

Move and delete fast — no arrow-keying character by character:

| Shortcut | Action |
| --- | --- |
| `Ctrl+A` / `Ctrl+E` | Jump to the start / end of the line |
| `Option/Alt+←` / `→` | Jump backward / forward one word |
| `Ctrl+W` | Delete the previous word |
| `Ctrl+U` | Delete from the cursor to the start of the line |
| `Ctrl+K` | Delete from the cursor to the end of the line |
| `Ctrl+G` | Edit the current prompt or plan in `$EDITOR` |

Vim-style editing is available via `/config` → **Editor mode**.

> [!TIP]
> Changed your mind about a long prompt? Press `Ctrl+C` **once** to wipe the whole input instantly — no backspacing letter by letter (a second press exits Claude Code). A terminal's `Cmd+A` selects the scrollback for copying, not the prompt text, so use these kill-line shortcuts to clear it.

## macOS Option keys

| Shortcut | Action |
| --- | --- |
| `Option/Alt+P` | Switch model |
| `Option/Alt+T` | Toggle extended thinking |
| `Option/Alt+O` | Toggle fast mode |

## Multiline input

To submit a message that spans multiple lines, use one of:

| Method | Notes |
| --- | --- |
| `\` then `Enter` | Backslash-continuation; works in any terminal |
| `Ctrl+J` | Insert a newline without submitting |
| `Shift+Enter` | Native in Ghostty and iTerm2 |
| `/terminal-setup` | Run once to enable `Shift+Enter` in VS Code |

> [!TIP]
> Run `/terminal-setup` after installing to configure your terminal for the best key handling, including `Shift+Enter` for newlines.

> [!NOTE]
> `Esc Esc` only opens the rewind menu when the input line is empty; otherwise `Esc` interrupts the current turn.

**Source:** [Interactive mode](https://code.claude.com/docs/en/interactive-mode)
