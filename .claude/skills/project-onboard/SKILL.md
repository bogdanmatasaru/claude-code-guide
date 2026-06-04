---
name: project-onboard
description: Configurează un proiect pentru lucru smooth cu Claude Code — generează/actualizează CLAUDE.md, propune permisiuni allowlist ca să nu mai întrebe la comenzile repetitive, și sugerează MCP-uri relevante. Folosește când intri prima dată într-un repo nou cu Claude Code.
---

# project-onboard

Scop: după ce `setup.sh` a pregătit *mediul* (Ghostty + Claude Code instalate), acest
skill pregătește *proiectul curent* ca lucrul să fie smooth de la primul mesaj.

Rulează pașii în ordine. Fii concis cu user-ul; arată ce ai făcut, nu explica teoria.

## 1. Înțelege repo-ul
- Detectează stack-ul: caută `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`,
  `Makefile`, `*.csproj`, etc.
- Identifică comenzile de build / test / lint / run (din scripts, Makefile, CI).
- Notează convenții evidente (formatter, structură foldere, framework de test).

## 2. CLAUDE.md
- Dacă `CLAUDE.md` **nu** există: rulează echivalentul `/init` — generează unul scurt cu:
  comenzile cheie (build/test/lint/run), structura pe scurt, convenții de cod, lucruri
  ne-evidente de știut. Ține-l strâns (nu un eseu).
- Dacă **există**: citește-l, propune adăugiri doar pentru ce lipsește și e util.
- Cere confirmare înainte de a scrie/comite.

## 3. Permisiuni (mai puține prompturi)
- Din comenzile de la pasul 1, propune un allowlist în `.claude/settings.json` pentru
  cele sigure & repetitive (ex. `Bash(npm run test:*)`, `Bash(npm run build)`,
  `Bash(git status)`, `Bash(git diff:*)`).
- NU adăuga comenzi distructive (deploy, push --force, rm). Doar read/test/build.
- Scrie în `.claude/settings.json` (proiect), nu în settings global.

## 4. MCP-uri relevante (opțional)
- Dacă proiectul folosește GitHub și `gh` e autentificat, sugerează MCP github.
- Dacă e web/UI, menționează MCP de browser pentru verificare vizuală.
- Doar sugerează + arată comanda; nu instala fără ok.

## 5. Rezumat final
Afișează o listă scurtă:
- ce s-a creat/modificat (CLAUDE.md, settings.json),
- comenzile de test/build detectate,
- următorul pas recomandat (ex. „rulează /code-review după primele modificări").

Reguli: confirmă înainte de scrieri în fișiere versionate; nu atinge settings global
al user-ului; nu inventa comenzi — verifică-le că există în repo.
