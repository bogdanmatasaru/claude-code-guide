---
title: Output styles
description: Built-in and custom output styles in Claude Code, how to set them via /config, and the v2.1.91 command removal.
---
# Output styles

Output styles change *how* Claude responds, not *what* it knows. They modify the system prompt to set role, tone, and output format. Reach for one when you keep re-prompting for the same voice every turn.

## Built-in styles

| Style | Behavior |
| --- | --- |
| **Default** | The standard software-engineering system prompt. |
| **Proactive** | Executes immediately, makes reasonable assumptions, prefers action over planning. Permission prompts still apply. |
| **Explanatory** | Adds educational "Insights" while completing tasks, explaining implementation choices. |
| **Learning** | Collaborative, learn-by-doing mode; inserts `TODO(human)` markers for you to implement. |

> [!NOTE]
> Explanatory and Learning produce longer responses by design, which increases output tokens.

## Setting a style

Run `/config` and select **Output style** to pick from a menu. Your choice saves as `outputStyle` in `.claude/settings.local.json`:

```json
{
  "outputStyle": "Explanatory"
}
```

You can also edit the `outputStyle` field directly in any [settings.json](./settings.md) layer. Output style is read once at session start, so changes take effect after `/clear` or a new session.

> [!IMPORTANT]
> The standalone `/output-style` command was deprecated in v2.1.73 and **removed in v2.1.91**. Use `/config` or edit the `outputStyle` setting instead.

## Custom styles

A custom style is a Markdown file — frontmatter plus the instructions to append to the system prompt. The filename becomes the style name unless you set `name` in frontmatter. Save it at one of:

- **User:** `~/.claude/output-styles/`
- **Project:** `.claude/output-styles/`
- **Managed policy:** `.claude/output-styles/` inside the managed settings directory

```markdown
---
name: Diagrams first
description: Lead every explanation with a diagram
keep-coding-instructions: true
---

When explaining code or architecture, start with a Mermaid diagram, then explain in prose.
```

Set `keep-coding-instructions: true` to retain Claude Code's built-in software-engineering behavior while changing how it communicates. Omit it (the default is `false`) when Claude isn't doing software engineering at all — for example, a writing assistant.

> [!NOTE]
> Frontmatter fields may evolve. Verify the current set (`name`, `description`, `keep-coding-instructions`, and others) in the official docs.

## When to use what

Output styles modify the system prompt and apply to *every* response. For project conventions and codebase context, use [CLAUDE.md](./claude-md.md) instead. For a one-off addition, use `--append-system-prompt`.

**Source:** [code.claude.com/docs/en/output-styles](https://code.claude.com/docs/en/output-styles)
