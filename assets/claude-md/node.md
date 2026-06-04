# CLAUDE.md — Node / TypeScript

Project memory for Claude Code. Keep it lean; this is loaded into every session.

## Stack
- Node 20+ (see `.nvmrc`), TypeScript (strict), package manager: **npm**.
- Test runner: **Vitest**. Lint/format: **ESLint** + **Prettier**.

## Commands
- Install: `npm ci` (use `ci`, not `install`, for reproducible installs).
- Dev server: `npm run dev`
- Build: `npm run build` (emits to `dist/`, runs `tsc -p tsconfig.build.json`)
- Test: `npm test` — single file: `npx vitest run path/to/file.test.ts`
- Lint: `npm run lint` — auto-fix: `npm run lint -- --fix`
- Format: `npm run format` (Prettier writes in place)
- Typecheck only: `npm run typecheck` (`tsc --noEmit`)

## Conventions
- ES modules only (`"type": "module"`); use `import`, never `require`.
- Path alias `@/*` maps to `src/*` (see `tsconfig.json` `paths`).
- Public API is re-exported from `src/index.ts`; import from there, not deep paths.
- Tests live next to source as `*.test.ts`.
- Prefer named exports; avoid `default` exports except for framework entrypoints.

## Gotchas
- `tsconfig.json` is for the editor/typecheck; the build uses `tsconfig.build.json`
  (which excludes tests). Editing only `tsconfig.json` won't change build output.
- With ESM + Node, relative imports need explicit `.js` extensions in emitted code;
  TS source uses `.js` extension too (e.g. `import { x } from './util.js'`).
- `npm run dev` uses `tsx` watch — it does **not** typecheck. Run `npm run typecheck`
  before assuming the build passes.
- Do not commit `dist/` or `.env`. Secrets load from `.env` (gitignored).

## Before finishing a change
1. `npm run typecheck`
2. `npm test`
3. `npm run lint`
