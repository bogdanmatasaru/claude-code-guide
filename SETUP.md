# Onboarding — Claude Code + Ghostty pe un calculator nou

Ghid pas-cu-pas ca să ai, de la zero, un mediu complet de lucru cu **Claude Code în
terminal (Ghostty)** pe un Mac nou. De la beginner la "gata de lucru" în ~10 minute
(plus timpul de descărcare).

> TL;DR: `git clone … && cd claude-code-guide && ./setup.sh` → deschizi Ghostty →
> `claude` → login. Gata.

---

## 1. Ce instalează și configurează

`setup.sh` face totul, în ordine, **idempotent** (poți re-rula oricând fără să strici nimic):

| Pas | Ce instalează / scrie | De ce |
|---|---|---|
| Xcode CLT | `git`, compilatoare | necesare pentru brew & dezvoltare |
| Homebrew | package manager macOS | de aici vine restul |
| Ghostty | terminalul recomandat | Shift+Enter nativ, notificări, GPU rapid |
| JetBrains Mono | font | lizibilitate în cod |
| Node.js | runtime | Claude Code + multe proiecte |
| gh | GitHub CLI | PR-uri, MCP github |
| Claude Code | CLI-ul `claude` | scopul întregului setup |
| `~/.config/ghostty/config` | temă Catppuccin auto dark/light | terminal frumos, zero-config |
| `~/.claude/settings.json` | permisiuni de bază | mai puține prompturi |
| `~/.claude/CLAUDE.md` | preferințe globale | comportament consistent |
| `~/.zshrc` | PATH (brew + `~/.local/bin`) + alias-uri (`cc`, `ccc`, `ccp`) | merge în orice terminal nou |

Ce **nu** atinge: dacă `~/.claude/settings.json` sau `~/.claude/CLAUDE.md` există deja,
nu le suprascrie (config-ul tău e sacru). Orice alt fișier suprascris primește backup
`*.bak.<timestamp>`.

---

## 2. Instalare (pas cu pas)

### Pasul 0 — deschide Terminalul implicit
Pe un Mac nou n-ai încă Ghostty. Folosește **Terminal.app** (Cmd+Space → "Terminal")
doar pentru prima rulare.

### Pasul 1 — ia repo-ul
Dacă ai deja `git` (de obicei da, prin macOS):
```bash
git clone https://github.com/bogdanmatasaru/claude-code-guide.git
cd claude-code-guide
```
Dacă `git` lipsește, macOS îți va propune să instaleze Command Line Tools — acceptă,
apoi reia comanda.

### Pasul 2 — rulează bootstrap-ul
```bash
./setup.sh
```
Vrei să vezi întâi ce face, fără să schimbe nimic?
```bash
./setup.sh --dry-run
```

### Pasul 3 — deschide Ghostty și loghează-te
1. Cmd+Space → **Ghostty** (deschide o fereastră **nouă**, ca să prindă PATH-ul nou).
2. Scrie `claude` și autentifică-te (se deschide browserul).
3. Verifică: `claude doctor`.

### Pasul 4 — pregătește un proiect
În folderul oricărui proiect:
```bash
claude
```
apoi în Claude rulează `/init` (generează `CLAUDE.md`) sau skill-ul **`/project-onboard`**
din acest repo (configurează `CLAUDE.md` + permisiuni + sugestii MCP).

---

## 3. Flag-uri utile

| Comandă | Efect |
|---|---|
| `./setup.sh` | instalare completă |
| `./setup.sh --dry-run` | arată ce ar face, **fără** să schimbe nimic |
| `./setup.sh --check` | doar validează un mediu existent (nu instalează) |
| `./setup.sh --no-shell` | nu adăuga linii (PATH/alias-uri) în `~/.zshrc` |
| `./setup.sh --help` | ajutor |

`--check` e util oricând vrei să confirmi că mediul e întreg:
```
> Validare mediu
  OK Homebrew (brew)
  OK Node.js (node)
  OK Claude Code (claude)
  OK Ghostty (cask)
  ...
MEDIU VALID — totul e la locul lui.
```

---

## 4. Verificare & teste (pentru cei care vor certitudine)

`setup.sh` are o suită de teste care **simulează un Mac nou** (HOME izolat + comenzi
mock), fără să atingă sistemul real:
```bash
./test/run-tests.sh
```
Verifică sintaxă, `shellcheck`, scrierea config-urilor, JSON valid, persistarea PATH,
idempotența (rulare ×2 fără backup-uri) și modurile `--dry-run` / `--check`.

---

## 5. Depanare

| Simptom | Soluție |
|---|---|
| `claude: command not found` după instalare | Deschide o fereastră **nouă** de terminal (PATH-ul nou e în `~/.zshrc`). Sau: `source ~/.zshrc`. |
| `brew: command not found` | La fel — fereastră nouă, sau `eval "$(/opt/homebrew/bin/brew shellenv)"`. |
| Dialogul Xcode CLT s-a închis | Re-rulează `./setup.sh` (e idempotent). |
| Shift+Enter nu merge în alt terminal | În VSCode/Cursor rulează `/terminal-setup` o dată. Pe Ghostty merge nativ. |
| Vreau să verific tot | `./setup.sh --check` apoi `claude doctor`. |
| Ceva pare stricat în Claude | `/doctor` (apasă `f` = auto-fix). |

Mai multe în ghidul de referință: [`claude-code-ghid.html`](claude-code-ghid.html) /
[`.pdf`](claude-code-ghid.pdf), secțiunile **24 (Ghostty)** și **25 (Depanare)**.

---

## 6. Ce urmează după setup

- Citește ghidul complet (HTML/PDF) — comenzi, taste, moduri de permisiuni, hooks.
- Personalizează `~/.config/ghostty/config` (teme: `ghostty +list-themes`).
- Per-proiect: `/init` sau `/project-onboard`, apoi commite `CLAUDE.md`.
