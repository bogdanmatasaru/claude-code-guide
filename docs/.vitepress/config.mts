import { withMermaid } from 'vitepress-plugin-mermaid'

// Single source of truth: VitePress renders the same Markdown files in docs/ that
// GitHub renders. base must match the GitHub Pages project path.
export default withMermaid({
  title: 'Claude Code Guide',
  description:
    'The complete Claude Code guide, cheatsheet & best practices — commands, hooks, MCP, subagents, skills, and a one-command terminal + Ghostty setup.',
  lang: 'en-US',
  base: '/claude-code-guide/',
  cleanUrls: true,
  lastUpdated: true,
  ignoreDeadLinks: false,

  head: [
    ['meta', { name: 'theme-color', content: '#8b5cf6' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'Claude Code Guide' }],
    [
      'meta',
      {
        property: 'og:description',
        content:
          'Claude Code guide, cheatsheet & best practices — beginner to expert.'
      }
    ]
  ],

  themeConfig: {
    nav: [
      { text: 'Learning path', link: '/learning-path' },
      { text: 'Cheatsheet', link: '/cheatsheet' },
      { text: 'Best practices', link: '/best-practices' },
      {
        text: 'Reference',
        items: [
          { text: 'CLI', link: '/reference/cli' },
          { text: 'Slash commands', link: '/reference/slash-commands' },
          { text: 'Hooks', link: '/reference/hooks' },
          { text: 'MCP', link: '/reference/mcp' },
          { text: 'Skills', link: '/reference/skills' },
          { text: 'Subagents', link: '/reference/subagents' }
        ]
      }
    ],

    sidebar: [
      {
        text: 'Getting started',
        collapsed: false,
        items: [
          { text: 'Installation', link: '/getting-started/installation' },
          { text: 'Quickstart', link: '/getting-started/quickstart' },
          { text: 'Your first session', link: '/getting-started/your-first-session' }
        ]
      },
      {
        text: 'Guides',
        collapsed: false,
        items: [
          { text: 'Onboard a codebase', link: '/guides/onboard-a-codebase' },
          { text: 'Fix a bug', link: '/guides/fix-a-bug' },
          { text: 'Spec a big feature', link: '/guides/spec-a-feature' },
          { text: 'Refactor safely', link: '/guides/refactor-safely' },
          { text: 'Parallel work (worktrees)', link: '/guides/parallel-work-worktrees' },
          { text: 'Headless & CI', link: '/guides/headless-and-ci' },
          { text: 'Optimize cost & context', link: '/guides/cost-optimization' }
        ]
      },
      {
        text: 'Reference',
        collapsed: false,
        items: [
          { text: 'CLI', link: '/reference/cli' },
          { text: 'Slash commands', link: '/reference/slash-commands' },
          { text: 'Keyboard shortcuts', link: '/reference/keyboard-shortcuts' },
          { text: 'Permission modes', link: '/reference/permission-modes' },
          { text: 'settings.json', link: '/reference/settings' },
          { text: 'CLAUDE.md & memory', link: '/reference/claude-md' },
          { text: 'Hooks', link: '/reference/hooks' },
          { text: 'MCP', link: '/reference/mcp' },
          { text: 'Skills', link: '/reference/skills' },
          { text: 'Subagents', link: '/reference/subagents' },
          { text: 'Models, effort & thinking', link: '/reference/models-and-effort' },
          { text: 'Output styles', link: '/reference/output-styles' },
          { text: 'Plugins', link: '/reference/plugins' }
        ]
      },
      {
        text: 'Explanation',
        collapsed: false,
        items: [
          { text: 'How Claude Code works', link: '/explanation/how-claude-works' },
          { text: 'The context window', link: '/explanation/context-window' },
          { text: 'When to use what', link: '/explanation/when-to-use-what' }
        ]
      },
      {
        text: 'Environment',
        collapsed: false,
        items: [
          { text: 'Terminal & Ghostty', link: '/environment/terminal-and-ghostty' },
          { text: 'One-command setup', link: '/environment/bootstrap-setup' },
          { text: 'Monitor cost & limits', link: '/environment/monitoring-cost-ratelimits' }
        ]
      },
      {
        text: 'More',
        collapsed: false,
        items: [
          { text: 'Best practices', link: '/best-practices' },
          { text: 'Learning path', link: '/learning-path' },
          { text: 'Cheatsheet', link: '/cheatsheet' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/bogdanmatasaru/claude-code-guide' }
    ],

    search: { provider: 'local' },

    editLink: {
      pattern:
        'https://github.com/bogdanmatasaru/claude-code-guide/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Community guide — not affiliated with Anthropic.'
    }
  }
})
