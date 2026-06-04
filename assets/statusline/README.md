# Status line

A status line at the bottom of Claude Code that shows, at a glance: the **model**,
**context usage**, your **5-hour and weekly plan limits** (with bars + time-to-reset),
the **git branch + changes**, **session time**, and **free disk**.

This is the repo's monitoring wedge made real — you always see how much of your plan
you've burned and when it resets, without running `/usage`.

```text
🤖 Opus 4.8   🧠 [███░░░░] 48%
🟢 5h [███░░░░] 32% ⟳ 3h 3m    📅 7d [███░░░░] 31% ⟳ 4d 10h
🌿 main +19 -8   ⏱ 4h 27m   💾 19.9G/48.0G
```

## Two ways to get it

### Option A — `ccstatusline` (recommended, what `setup.sh` installs)

[`ccstatusline`](https://github.com/sirmalloc/ccstatusline) is a configurable,
multi-line status line for Claude Code (the 3-line display above). `setup.sh` installs
it and writes this config for you. To do it by hand:

```bash
npm install -g ccstatusline@2
mkdir -p ~/.config/ccstatusline
cp ccstatusline-settings.json ~/.config/ccstatusline/settings.json
```

Then point Claude Code at it in `~/.claude/settings.json`:

```json
{ "statusLine": { "type": "command", "command": "ccstatusline", "padding": 0 } }
```

Tweak the widgets interactively by running `ccstatusline` in a terminal.

### Option B — self-contained `statusline.sh` (no Node, just bash + jq + git)

A single script with no dependencies beyond `jq` and `git`. Lighter, fully yours, but
a single line and fewer widgets.

```bash
cp statusline.sh ~/.claude/statusline.sh && chmod +x ~/.claude/statusline.sh
```

```json
{ "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" } }
```

## Notes

- The **5-hour / weekly** segments rely on your Claude Code version exposing
  `rate_limits` in the status payload. If yours doesn't, those segments are omitted
  (the model + context + branch still show).
- See [Monitor cost & rate limits](../../docs/environment/monitoring-cost-ratelimits.md)
  for the full picture, including `/usage` and `/context`.
