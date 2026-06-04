# CLAUDE.md — Python

Project memory for Claude Code. Keep it lean; this is loaded into every session.

## Stack
- Python 3.12+ (see `.python-version`). Dependency/venv manager: **uv**.
- Test: **pytest**. Lint + format: **ruff**. Type checking: **mypy** (strict).

## Commands
- Sync deps (creates `.venv`): `uv sync`
- Add a dependency: `uv add <pkg>` — dev only: `uv add --dev <pkg>`
- Run anything in the venv: `uv run <cmd>` (e.g. `uv run python -m app`)
- Test: `uv run pytest` — single test: `uv run pytest tests/test_x.py::test_name`
- Lint: `uv run ruff check .` — auto-fix: `uv run ruff check --fix .`
- Format: `uv run ruff format .`
- Typecheck: `uv run mypy src`

## Conventions
- Source lives in `src/<package>/`; tests in `tests/` mirroring the package layout.
- Type hints required on all public functions; mypy runs in strict mode.
- Use `pathlib.Path`, not `os.path`. Use f-strings, not `%` or `.format()`.
- Dependencies are pinned in `uv.lock` — never hand-edit it; use `uv add`/`uv lock`.

## Gotchas
- Always prefix commands with `uv run` so they use the project venv, not system Python.
- `pyproject.toml` holds ruff/mypy/pytest config; check there before changing tooling flags.
- ruff replaces both flake8 and isort — do not add those separately.
- `uv sync` is exact: it removes packages not in the lockfile. Use `uv add` to introduce new ones.

## Before finishing a change
1. `uv run ruff format .`
2. `uv run ruff check .`
3. `uv run mypy src`
4. `uv run pytest`
