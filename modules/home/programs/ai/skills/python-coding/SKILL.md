---
name: python-coding
description: "Write and review Python with strict verification and idiomatic design. Use when: writing, linting, testing, formatting, type-checking, reviewing, or refactoring Python code with uv, ruff, mypy, and pytest."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: python, uv, ruff, mypy, pytest
---

# Python Coding

Rules for Python with strict verification, explicit type boundaries, and idiomatic API design.

## Purpose

Use this skill to write, review, or refactor Python. Prefer designs where the type checker, linter, and tests carry correctness and public APIs do not leak implicit `Any`.

## Scope

### Use this skill when

- Writing or reviewing Python application, library, or tooling code.
- Refactoring modules where typing, error handling, or API shape matters.
- Choosing validation commands with `uv`, `ruff`, `mypy`, and `pytest`.
- Tightening lint posture, type strictness, or test placement.

### Do not use this skill when

- The task is mainly interpreter installation, editor configuration, or CI setup.

## Governing rule

Let the type checker, linter, and tests do the work. Make invalid states hard to represent, implicit `Any` hard to introduce, and regressions easy to catch.

## Verification defaults

Run project commands through `uv run`; never manually activate the virtualenv.

- Lint: `uv run ruff check .`; narrow during iteration, finish repository-wide.
- Format: `uv run ruff format --check .`; format locally as needed, verify broadly.
- Type-check: `uv run mypy --strict .`. If the project has adopted Astral-native `ty`, use `uv run ty check` instead; do not mix both in the same run.
- Test: `uv run pytest`; narrow by file, node ID, or marker while debugging, finish broad.
- CI/fresh env: `uv sync --frozen` so the lockfile is enforced.

## Test placement

- Use `src/` layout so tests run against the installed package.
- Keep tests in top-level `tests/` mirroring package structure, for example `src/pkg/foo.py` -> `tests/test_foo.py` or repo convention.
- Put fixtures in the narrowest useful `conftest.py`; root fixtures only for truly global behavior.
- Use `pytest.mark.parametrize` with explicit `id=` values.
- Reserve integration tests for module, package, or external-system boundaries; keep unit tests focused and fast.
- Configure pytest in `pyproject.toml` with `--import-mode=importlib`, `--strict-markers`, `--strict-config`, and explicit `testpaths`.
- Do not add `pythonpath = ["src"]` when `uv sync` installs the package editable.

## Strictness defaults

Use documented alternatives only when the repo has a reason.

- Ruff: target recent Python (`py312` or project baseline), line length 88, and a curated ruleset: `E`, `F`, `W`, `I`, `N`, `UP`, `B`, `C4`, `FA`, `ISC`, `ICN`, `PIE`, `PT`, `RET`, `SIM`, `TID`, `TC`, `PTH`, `RUF`.
- Mypy: `strict = true`, `warn_unreachable = true`, and useful extra codes such as `redundant-expr`, `truthy-bool`, and `ignore-without-code`.
- Avoid `select = ["ALL"]`; upgrades should not silently enable noisy new rules.
- Avoid default `disallow_any_explicit`; it conflicts with common Pydantic and library patterns. Enable per-module only when sustainable.

Prefer implementation fixes over suppressions. If a suppression is necessary, scope it to one line, name the rule or code (`# noqa: RULE`, `# type: ignore[code]`), add a rationale, and remove stale suppressions when touching nearby code.

## Error handling

- Define a package-level base exception and inherit specific errors from it.
- Catch the narrowest exception that expresses intent. Avoid bare `except:` and use `except Exception:` only at process boundaries that must log and continue.
- Wrap with `raise NewError(...) from err`; use `from None` only when the cause is an implementation detail.
- Prefer typed exceptions over sentinel values such as `None` or `-1` for failures.
- Use `T | None` only when absence is expected and callers should handle it.

## Type and API design

- Use `typing.NewType` for domain IDs or primitives that must not be interchangeable.
- Use `@dataclass(frozen=True, slots=True)` for internal value objects you control.
- Use `pydantic.BaseModel` at trust boundaries: HTTP bodies, config/env, external JSON, serialization.
- Use `attrs` only when dataclasses lack needed validators/converters and Pydantic is too heavy.
- Use `TypedDict` to describe existing dict-shaped data without allocating classes.
- Model finite states with `Enum` or `Literal`; use `match` so new variants surface in handlers.
- Prefer `Protocol` for structural interfaces; reserve `ABC` for runtime checks or enforced base behavior.
- Give exceptions structured fields, not only message strings.

## Idiomatic defaults

- Prefer comprehensions and generators over manual append loops when transforming/filtering.
- Use `pathlib.Path` instead of `os.path` string manipulation.
- Use `enumerate`, `zip`, and unpacking instead of manual indexing.
- Manage resources with `with` or `contextlib` so cleanup always runs.
- Prefer `dict.get`, `setdefault`, and `collections.defaultdict` over repeated membership checks.
- Use f-strings; keep `%` formatting for lazy logging arguments.
- Cache pure functions with `functools.cache` or `lru_cache`, not ad-hoc dicts.
- On Python 3.14+, rely on deferred annotations and avoid reflexive future imports; on 3.12/3.13 add the future import only when it helps.
- Keep import-time code side-effect free; initialize inside functions, `main()`, or constructors.
- Target recent Python when allowed and use `match`, `type` aliases, PEP 695 generics, and built-in generics.

## Patterns to correct

- Replace bare or blanket exception handlers with narrow catches.
- Replace mutable defaults with `None` plus inside-the-body defaults.
- Replace global mutable state with explicit parameters or owning classes.
- Remove `Any` from public APIs using `TypeVar`, `Protocol`, `TypedDict`, or concrete types.
- Replace stringly errors and tuple-coded returns with typed exceptions or result dataclasses.
- Drop reflexive copies unless aliasing is a real hazard.
- Flatten deep inheritance into composition and focused classes.
- Return immutable views/copies of internal collections only when aliasing would cause bugs.

## Verification checklist

- [ ] Ran lint, format, type, and tests broadly through `uv run`.
- [ ] Kept tests and fixtures according to repo conventions, with explicit parametrized case IDs.
- [ ] Preserved strict Ruff/Mypy posture and scoped suppressions with rationale.
- [ ] Used typed exceptions, `raise ... from err`, and narrow catches.
- [ ] Used domain types, dataclasses, Pydantic at boundaries, `Protocol`, and concrete public API types.
