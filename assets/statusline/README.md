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
it, ships **two profiles**, and wires a tiny launcher that auto-selects the right one
by your account type (see [Account-aware profiles](#account-aware-profiles-enterprise--team)).
To do it by hand:

```bash
npm install -g ccstatusline@2
mkdir -p ~/.config/ccstatusline
cp ccstatusline-settings.json            ~/.config/ccstatusline/settings.json
cp ccstatusline-settings.json            ~/.config/ccstatusline/settings.consumer.json
cp ccstatusline-settings.enterprise.json ~/.config/ccstatusline/settings.enterprise.json
cp profile-switch.sh                     ~/.config/ccstatusline/profile-switch.sh
chmod +x ~/.config/ccstatusline/profile-switch.sh
```

Then point Claude Code at the launcher in `~/.claude/settings.json`:

```json
{ "statusLine": { "type": "command", "command": "sh $HOME/.config/ccstatusline/profile-switch.sh", "padding": 0 } }
```

(Prefer the plain line with no account switching? Point `command` at `ccstatusline`
instead — it uses `settings.json` directly.)

Tweak the widgets interactively by running `ccstatusline` in a terminal.

### Account-aware profiles (enterprise / team)

`ccstatusline`'s **5h / weekly usage** widgets read the `five_hour` / `seven_day`
rate-limit buckets from Anthropic's usage API. **Enterprise/Team** seats return those
buckets as `null`, so those widgets show **`[Timeout]`** (a back-off label — not a real
network timeout; the API answers `200` in <0.5s). Enterprise plans expose a monthly
pay-as-you-go bucket (`extra_usage`) instead.

So `profile-switch.sh` reads only your account's `subscriptionType` (never the token)
and picks:

| Account | Profile | Line 2 shows |
| --- | --- | --- |
| **enterprise / team** | `settings.enterprise.json` | `🟢 5h ⟳ <reset>    💳 credit <$ left>` |
| Pro / Max / other | `settings.consumer.json` | `🟢 5h <usage%> ⟳ <reset>   📅 7d <usage%> ⟳ <reset>` |

**The enterprise shim.** `ccstatusline` fetches usage once per render and shares it
across all usage widgets, UNIONing their required fields. `reset-timer` needs
`sessionResetAt`, and Claude Code's payload carries no `rate_limits`, so on enterprise
that field is unsatisfiable and the shared object errors out — which would make
`extra-usage-remaining` show `[Timeout]` too. The launcher injects a synthetic
`rate_limits.five_hour.resets_at` (the 5h block reset, read from `ccstatusline`'s own
block-cache) so the field is satisfied locally and both the timer **and** the credit
render. Detection is cached for 5 min; `rm ~/.config/ccstatusline/.active-profile` forces
a re-check after switching accounts.

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

- The **consumer** profile's 5h / weekly **usage %** comes from the usage API; on
  enterprise/team those buckets are null (handled by the enterprise profile above).
  The **5h reset timer** is computed locally and always works.
- The **credit** widget is API-backed, so it may briefly show `[Rate limited]` /
  `[API Error]` after rapid repeated renders — cosmetic, it self-heals on the next good
  fetch (cached 180s) and never affects actual Claude usage.
- Check what's active any time: `./setup.sh --check` reports the detected account and
  validates both profiles.
- See [Monitor cost & rate limits](../../docs/environment/monitoring-cost-ratelimits.md)
  for the full picture, including `/usage` and `/context`.
