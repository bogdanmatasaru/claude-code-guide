# CLAUDE.md — JS Monorepo (pnpm + Turborepo)

Project memory for Claude Code. Keep it lean; this is loaded into every session.

## Layout

- `apps/*` — deployable applications (e.g. `apps/web`, `apps/api`).
- `packages/*` — shared libraries (e.g. `packages/ui`, `packages/config`, `packages/db`).
- Package manager: **pnpm** workspaces. Task runner: **Turborepo** (`turbo.json`).
- Each package has its own `package.json` and is referenced via the `workspace:*` protocol.

## Commands (run from repo root)

- Install: `pnpm install`
- Build everything (respects the dependency graph): `pnpm turbo build`
- Test / lint everything: `pnpm turbo test` · `pnpm turbo lint`
- Dev (all apps in parallel): `pnpm turbo dev`

## Targeting one package

- Filter by name: `pnpm --filter @acme/web dev`
- Build a package + its deps: `pnpm turbo build --filter @acme/web...`
- Only things changed vs main: `pnpm turbo build --filter='...[origin/main]'`
- Run a one-off in a package: `pnpm --filter @acme/db exec prisma generate`

## Conventions

- Shared config (eslint, tsconfig, prettier) lives in `packages/config` and is extended,
  not copied. Internal packages are imported by name (`@acme/ui`), never relative paths.
- Add a dependency to a specific package: `pnpm --filter @acme/web add <pkg>`.
- Internal deps use `"@acme/ui": "workspace:*"` in `package.json`.

## Gotchas

- Turbo caches task outputs. After changing build config, run `pnpm turbo build --force`
  to bypass the cache and confirm a real build.
- Outputs a task produces must be declared in `turbo.json` `outputs`, or caching breaks.
- Always install/run from the repo root; running `pnpm install` inside a package is wrong.
- A failing downstream build is often a stale upstream package — rebuild deps first.

## Before finishing a change

- `pnpm turbo lint test build --filter='...[origin/main]'` (only what you touched).
