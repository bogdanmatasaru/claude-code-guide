# Claude Code — Ghid complet

Ghid de referință (în română) pentru **Claude Code** în terminal: comenzi, taste, moduri de permisiuni, memorie & `CLAUDE.md`, hooks, optimizare cost/limite, status line cu monitorizare rate-limit (5h + săptămânal), și top tools de productivitate cu star-count verificat.

## Setup pe un calculator nou (1 comandă)

Pe un Mac nou, fără nimic instalat:

```bash
git clone https://github.com/bogdanmatasaru/claude-code-guide.git
cd claude-code-guide
./setup.sh
```

> Ghid de onboarding pas-cu-pas (beginner-friendly): **[`SETUP.md`](SETUP.md)**.

Scriptul e **idempotent** (re-rulabil) și instalează în ordine: Xcode CLT → Homebrew →
**Ghostty** → JetBrains Mono → Node.js → gh → **Claude Code** → scrie config Ghostty
(`~/.config/ghostty/config`) + config Claude (`~/.claude/`) + persistă PATH în `~/.zshrc`.
La final rulează auto o **validare**.

Flag-uri:

| Flag | Efect |
|---|---|
| (niciunul) | Instalare completă, interactiv |
| `--dry-run` | Arată ce ar face, fără să schimbe nimic |
| `--check` | Doar validează un mediu existent (nu instalează) |
| `--no-shell` | Nu adăuga alias-uri / linii PATH în shell rc |

După rulare: deschizi Ghostty → `claude` → login. Apoi, în orice proiect, skill-ul
**`/project-onboard`** (`.claude/skills/`) configurează `CLAUDE.md` + permisiuni.

### Validare / teste

`setup.sh` are o suită de teste care simulează un Mac nou (HOME izolat + comenzi mock),
fără să atingă sistemul tău. Rulează:

```bash
./test/run-tests.sh
```

Verifică: sintaxă, `shellcheck`, scrierea config-urilor, JSON valid, persistarea PATH,
idempotența (rulare ×2 fără backup-uri), toleranța la eșec de rețea la `brew install`,
`--help` curat și modurile `--dry-run` / `--check`. **32 de aserții** (31 fără
`shellcheck` instalat), toate trec.

## Conținut

| Fișier | Descriere |
|---|---|
| [`SETUP.md`](SETUP.md) | **Onboarding** pas-cu-pas pentru calculator nou (start aici) |
| [`setup.sh`](setup.sh) | **Bootstrap** mediu pe calculator nou (Ghostty + Claude Code + config) |
| [`test/run-tests.sh`](test/run-tests.sh) | Suită de teste izolată pentru `setup.sh` (mock, fără efecte reale) |
| [`.claude/skills/project-onboard`](.claude/skills/project-onboard/SKILL.md) | Skill: configurează un proiect (CLAUDE.md, permisiuni, MCP) |
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
