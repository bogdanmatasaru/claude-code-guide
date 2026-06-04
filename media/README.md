# Media assets

| File | Purpose |
|---|---|
| `logo.svg` | Repo logo (used in the README hero) |
| `social-preview.svg` | Source for the GitHub social-preview image (1280×640) |
| `demo.gif` | Terminal recording of `setup.sh` (used in the README) |

## Re-rendering the demo GIF

The GIF is generated from [`../scripts/demo.tape`](../scripts/demo.tape) with
[VHS](https://github.com/charmbracelet/vhs):

```bash
brew install vhs
vhs scripts/demo.tape   # writes media/demo.gif
```

## Manual steps (GitHub UI — can't be done from a commit)

These finish the "premium" presentation and must be done in the GitHub web UI:

1. **Social preview image** — convert `social-preview.svg` to PNG (e.g. open in a
   browser and screenshot, or `rsvg-convert social-preview.svg -o social-preview.png`),
   then upload it under **Settings → General → Social preview**.
2. **Enable GitHub Pages** — **Settings → Pages → Build and deployment → Source:
   GitHub Actions**. The `deploy-docs.yml` workflow then publishes the VitePress site
   to `https://bogdanmatasaru.github.io/claude-code-guide/`.
3. **Repo topics & description** — **Settings → General** (or the gear by "About").
   Suggested description and topics are in the project notes.
