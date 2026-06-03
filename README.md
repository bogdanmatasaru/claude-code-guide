# Claude Code — Ghid complet

Ghid de referință (în română) pentru **Claude Code** în terminal: comenzi, taste, moduri de permisiuni, memorie & `CLAUDE.md`, hooks, optimizare cost/limite, status line cu monitorizare rate-limit (5h + săptămânal), și top tools de productivitate cu star-count verificat.

## Conținut

| Fișier | Descriere |
|---|---|
| [`claude-code-ghid.html`](claude-code-ghid.html) | Sursa — ghidul complet, formatat (deschide în browser) |
| [`claude-code-ghid.pdf`](claude-code-ghid.pdf) | Versiunea PDF (12 pagini, generată din HTML) |

## Structură (26 secțiuni, 6 părți)

- **I · Zilnic** — esențialul, prefixe (`/ @ ! #`), taste, moduri de permisiuni, sesiune & context
- **II · Lucrul cu codul** — când începi o sesiune, top use cases, git & calitate, prompting, greșeli de evitat
- **III · Control** — model/efort/thinking, optimizare cost & limite
- **IV · Personalizare** — memorie & `CLAUDE.md`, config, `settings.json`, hooks
- **V · Avansat dar util** — lucru în paralel, funcții avansate, CLI, top tools, **monitorizare consum & productivitate**
- **VI · Mediu & referință** — terminale, setup Ghostty, depanare, glosar, flux de lucru

## Regenerare PDF din HTML

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="claude-code-ghid.pdf" \
  "file://$(pwd)/claude-code-ghid.html"
```

---

*Stars verificate prin GitHub API (iun. 2026). Sursă de informație personală — actualizat pe măsură ce ecosistemul evoluează.*
