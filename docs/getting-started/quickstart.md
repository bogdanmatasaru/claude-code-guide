---
title: Quickstart (5 minutes)
description: The fastest path to a first win with Claude Code — explore a real codebase and make a safe change in plan mode.
---
# Quickstart (5 minutes)

The goal here is a quick win: in five minutes you'll have Claude explain a real codebase and propose a change you can review before anything touches disk.

> [!NOTE]
> This assumes Claude Code is installed and you're signed in. If not, do [./installation.md](./installation.md) first (about two minutes).

## 1. Open a project

Pick any repo you already have — even a small one — and start a session in it:

```bash
cd /path/to/your/project
claude
```

You'll land on the welcome screen. Claude reads files on demand, so you don't need to add anything manually.

## 2. Ask it to explain the codebase

Type a plain-English question and press Enter:

```text
what does this project do, and where is the main entry point?
```

Claude searches the files, then summarizes the project and points you at the entry point. Try a follow-up:

```text
explain the folder structure
```

**Win:** you used Claude Code as a codebase guide — no setup, no manual file selection.

## 3. Switch to plan mode

Before asking for a change, press `Shift+Tab` until the footer shows **plan mode**. In plan mode Claude investigates and proposes an approach but makes **no edits** — perfect for your first change.

> [!TIP]
> `Shift+Tab` cycles through three modes: default → acceptEdits → plan. Stop on plan for now.

## 4. Ask for a small change

Describe one concrete, low-risk change:

```text
add a one-line docstring to the main entry function explaining what it does
```

Claude reads the relevant file and presents a **plan** with the exact edit it intends to make — but nothing is written yet.

## 5. Review the diff, then approve

Read the proposed change. When it looks right, approve it (Claude will then exit plan mode and apply the edit, showing you the diff). If it's off, just type what to fix instead.

**Win:** you reviewed an AI-proposed diff before it ran — the core safety habit that makes Claude Code trustworthy on real work.

## What just happened

In five minutes you:

1. Started Claude in a real repo
2. Had it explain the codebase
3. Used **plan mode** to get a proposal without edits
4. Reviewed and approved a concrete change

That explore → plan → review loop scales from one-line docstrings to multi-file features. The only thing that changes is the size of the task.

> [!IMPORTANT]
> Run `/clear` before starting an unrelated task. It resets Claude's working memory so the next task starts clean.

Next: [./your-first-session.md](./your-first-session.md)

**Source:** https://code.claude.com/docs/en/quickstart
