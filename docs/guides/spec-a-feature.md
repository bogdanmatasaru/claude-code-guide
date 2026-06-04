---
title: Spec a big feature
description: For large or fuzzy features, have Claude interview you, write a spec, then implement it in a fresh session — Anthropic's recommended approach for ambitious work.
---

# Spec a big feature

For a one-line change you just describe it. For a large or fuzzy feature, the highest-leverage
move is to **separate thinking from building**: have Claude interview you, write a spec, then
implement that spec in a clean session.

> [!TIP]
> Why split it up? A long session that designs *and* builds fills its [context window](../explanation/context-window.md) with exploration before it writes a line. A fresh implementation session starts lean, with a crisp spec to follow.

## 1. Let Claude interview you

Start in [plan mode](../reference/permission-modes.md) and ask Claude to dig in *before*
proposing anything:

```text
I want to add team workspaces to the app. Interview me in detail before writing
anything — ask about the data model, permissions, edge cases, and migration. Dig into
the hard parts I might not have considered. Don't propose a design yet.
```

Good interviews surface the decisions you'd otherwise discover halfway through coding.

## 2. Have it write the spec

When the questions run dry, ask for a written spec:

```text
Now write a complete spec to SPEC.md. Name the files and interfaces involved, state
what's out of scope, and end with a step-by-step end-to-end verification.
```

A strong spec is **self-contained**: someone (or a fresh Claude session) could implement it
without re-reading this conversation. Review and edit `SPEC.md` yourself — this is the
cheapest place to catch a wrong assumption.

## 3. Implement in a fresh session

Start a **new session** (`/clear` or a new `claude`) so implementation begins with a clean
context, and point it at the spec:

```text
Implement @SPEC.md. Work through it in order. Run the verification steps at the end and
fix anything that fails before you call it done.
```

Give it a [verifiable target](../explanation/how-claude-works.md) (the spec's verification
steps, plus tests/build) so it can self-correct without you watching every edit.

> [!NOTE]
> Commit `SPEC.md` alongside the work. It documents *why* the feature looks the way it does — useful for review and for the next person.

**Related:** [Cheatsheet](../cheatsheet.md) · [Best practices](../best-practices.md) · [Learning path](../learning-path.md)

**Source:** [Claude Code best practices](https://code.claude.com/docs/en/best-practices).
