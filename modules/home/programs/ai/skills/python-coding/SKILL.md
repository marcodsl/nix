---
name: python-coding
description: "Write and review Python with strict verification and idiomatic design. Use when: writing, linting, testing, formatting, type-checking, reviewing, or refactoring Python code with uv, ruff, mypy, and pytest."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [python, uv, ruff, mypy, pytest]
---

# Python Coding

Rules for writing and reviewing Python with strict verification, explicit type boundaries, and idiomatic API design.

## Purpose

Use this skill to write, review, or refactor Python code with correctness-first defaults. Prefer designs that let the type checker, linter, and tests carry as much of the correctness burden as possible.

## Scope

### Use this skill when

- Writing or reviewing Python application, library, or tooling code.
- Refactoring Python modules where typing, error handling, or API shape matters.
- Deciding how to validate Python changes with `ruff`, `mypy`, and `pytest` under `uv`.
- Tightening lint posture, type strictness, or test placement in a Python codebase.

### Do not use this skill when

- The task is mainly about installing interpreters, configuring editors, or setting up CI rather than writing or reviewing Python code.

## Governing rule

Let the type checker, linter, and tests do the work. Prefer designs that make invalid states harder to represent, implicit `Any` harder to introduce, and regressions easier to catch with broad verification.

## Verification defaults

Treat Python work as incomplete until the relevant checks pass. Default to the broadest relevant scope for the repository shape in front of you. Run all commands through `uv run` so they execute against the project's locked environment.

1. **Lint**: default to `uv run ruff check .`. During iteration you may narrow to a path or rule, but finish with a repository-wide check.
2. **Format**: default to `uv run ruff format --check .`. Local formatting during iteration is fine, but finish with a repository-wide check.
3. **Type-check**: default to `uv run mypy --strict .` for the whole project. In Astral-native workflows you may substitute `uv run ty check` once the project has adopted it; do not mix both on the same run. During iteration you may narrow to a package or module, but finish with the broadest relevant type check.
4. **Test**: default to `uv run pytest`. During debugging you may narrow to a file, node ID, or marker, but finish with the broadest relevant test run.
5. **Reproducibility**: in CI and on fresh environments, sync with `uv sync --frozen` so the lockfile is enforced. Never activate the virtualenv manually; execute project commands through `uv run`.

## Test placement and organization

- Use the `src/` layout (`src/<package>/...`) so tests run against the installed package and avoid import-path surprises.
- Keep tests in a top-level `tests/` tree that mirrors the package structure, so `src/pkg/foo/bar.py` is covered by `tests/foo/test_bar.py`.
- Put shared fixtures in `conftest.py` at the narrowest scope that works: package-local `conftest.py` for package-specific fixtures, repo-root `conftest.py` only for truly global fixtures.
- Use `@pytest.mark.parametrize` with explicit `id=` or `pytest.param(..., id=...)` values so failure output names the case, not just its index.
- Reserve integration tests for behavior that crosses module, package, or external system boundaries. Keep unit tests focused and fast.
- Configure discovery in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
addopts = ["--import-mode=importlib", "--strict-markers", "--strict-config"]
testpaths = ["tests"]
```

- Running through `uv run pytest` uses the project's virtualenv, where `uv sync` has installed the package editable, so the `src/` package is already importable from `site-packages`. Do not add `pythonpath = ["src"]` unless you are deliberately running pytest without installing the project first.
- If a repository defines narrower file-pattern or test-placement rules, apply them in addition to this skill rather than replacing the skill's general guidance.

## Strictness defaults

Use these `pyproject.toml` settings by default unless the project has a documented reason to differ. Prefer a curated ruff rule set over `select = ["ALL"]` so upgrades do not silently enable new rules.

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
extend-select = [
    "E", "F", "W",   # pycodestyle + pyflakes
    "I",             # isort
    "N",             # pep8-naming
    "UP",            # pyupgrade
    "B",             # flake8-bugbear
    "C4",            # flake8-comprehensions
    "FA",            # flake8-future-annotations
    "ISC",           # flake8-implicit-str-concat
    "ICN",           # flake8-import-conventions
    "PIE",           # flake8-pie
    "PT",            # flake8-pytest-style
    "RET",           # flake8-return
    "SIM",           # flake8-simplify
    "TID",           # flake8-tidy-imports
    "TC",            # flake8-type-checking
    "PTH",           # flake8-use-pathlib
    "RUF",           # ruff-specific rules
]

[tool.mypy]
strict = true
warn_unreachable = true
enable_error_code = ["redundant-expr", "truthy-bool", "ignore-without-code"]
```

`strict = true` already enables `warn_return_any`, `warn_unused_ignores`, and `warn_redundant_casts`, so they do not need to be set again. Opt into individual Pylint rules from ruff's `PL*` families only when a specific rule earns its noise; avoid enabling the whole `PL` category by default. `disallow_any_explicit` is intentionally omitted: it conflicts with `pydantic.BaseModel` and several common library patterns; enable it per-module only when you are sure the project can sustain it.

When the linter or type checker flags code, prefer changing the implementation over silencing the diagnostic. Add a scoped `# noqa: RULE` or `# type: ignore[code]` only when the diagnostic is a false positive or the compliant alternative would materially worsen the code.

- Scope every `# noqa` and `# type: ignore` to the smallest possible line.
- Always name the specific rule or error code. Never use bare `# noqa` or bare `# type: ignore`.
- Place a clear rationale comment immediately above or beside every suppression, naming the false positive or the tradeoff that makes the compliant alternative materially worse.
- Remove stale suppressions when touching the surrounding code. `warn_unused_ignores` catches stale `# type: ignore` comments on the next run.

```python
# False positive: pyright/mypy cannot see the runtime guard below, which
# enforces that `payload` is non-None before this call site.
value = handler.dispatch(payload)  # type: ignore[arg-type]
```

## Error handling

- Define a package-level base exception and inherit specific errors from it so callers can catch all failures from your package with a single `except` clause.
- Catch the narrowest exception that expresses intent. Never write bare `except:`, and avoid `except Exception:` unless you are at a process boundary that must log and continue.
- Use `raise NewError(...) from err` when wrapping an exception, or `raise ... from None` when the original cause is an implementation detail the caller should not see.
- Prefer raising a typed exception over returning sentinel values like `None` or `-1` to signal failure.
- Use `T | None` (or `Optional[T]`) only when absence is an expected, non-exceptional outcome the caller is meant to handle.

```python
class StorageError(Exception):
    """Base class for storage-layer failures."""


class ObjectNotFoundError(StorageError):
    def __init__(self, key: str) -> None:
        super().__init__(f"no object stored for key {key!r}")
        self.key = key


def load(key: str) -> bytes:
    try:
        return _backend.read(key)
    except KeyError as err:
        raise ObjectNotFoundError(key) from err
```

## Type and API design

### Newtype pattern

Wrap primitives with `typing.NewType` when values should not be interchangeable at the type level. The runtime value is unchanged; the distinction is enforced by the type checker.

```python
from typing import NewType

UserId = NewType("UserId", int)
PostId = NewType("PostId", int)


def posts_for(user_id: UserId) -> list[PostId]: ...
```

### Data shapes

Pick the smallest tool that fits the boundary:

- `@dataclass(frozen=True, slots=True)` for internal value objects and records where you control the inputs. Zero dependencies, fast, and immutable by default.
- `pydantic.BaseModel` at trust boundaries: HTTP request and response bodies, configuration loaded from env or disk, and anything parsed from external JSON. Use it where runtime validation and serialization earn their cost.
- `attrs` only when you need features dataclasses lack (validators, converters, advanced `__init__` customization) and pydantic would be overkill.
- `TypedDict` for describing the shape of an existing `dict` (for example, JSON returned by a third-party client) without allocating a new class.

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class Coordinate:
    lat: float
    lon: float
```

### Enums and literals

Model finite sets of states with `enum.Enum` or `typing.Literal`, and use structural `match` statements so new variants surface as type errors at the call sites that need to handle them.

```python
from enum import Enum


class ConnectionState(Enum):
    DISCONNECTED = "disconnected"
    CONNECTING = "connecting"
    CONNECTED = "connected"


def describe(state: ConnectionState) -> str:
    match state:
        case ConnectionState.DISCONNECTED:
            return "offline"
        case ConnectionState.CONNECTING:
            return "dialing"
        case ConnectionState.CONNECTED:
            return "online"
```

### Protocols over ABCs

Use `typing.Protocol` for structural interfaces when duck typing is sufficient. Reserve `abc.ABC` for cases that need runtime `isinstance` checks or enforced base-class behavior.

```python
from typing import Protocol


class SupportsClose(Protocol):
    def close(self) -> None: ...


def shutdown(resource: SupportsClose) -> None:
    resource.close()
```

### Semantic exceptions

Give each package an exception hierarchy that names the failure mode and carries structured fields, rather than encoding meaning in a message string.

```python
class RateLimitedError(StorageError):
    def __init__(self, retry_after_s: float) -> None:
        super().__init__(f"rate limited; retry after {retry_after_s:.1f}s")
        self.retry_after_s = retry_after_s
```

## Idiomatic Python defaults

- Prefer comprehensions and generator expressions over manual `for ... append` loops when you are only transforming and filtering.
- Use `pathlib.Path` for filesystem work instead of `os.path` string manipulation.
- Use `enumerate`, `zip`, and unpacking instead of indexing into sequences by hand.
- Manage resources with `with` statements (or `contextlib.contextmanager` for custom resources) so cleanup runs on every exit path.
- Prefer `dict.get`, `dict.setdefault`, and `collections.defaultdict` over repeated `key in d` checks followed by assignment.
- Use f-strings for formatting. Reserve `%`-formatting for logging calls that benefit from lazy argument evaluation.
- Cache pure functions with `functools.cache` or `functools.lru_cache` rather than hand-rolling memo dicts.
- On Python 3.14 and newer, rely on PEP 649 and PEP 749 deferred annotation evaluation and do not add `from __future__ import annotations`; use `annotationlib.get_annotations()` when you need runtime introspection. On 3.12 and 3.13 add the future import only when it meaningfully helps (heavy forward references, keeping typing-only imports out of runtime), not reflexively.
- Keep import-time code side-effect-free. Put initialization inside functions, `main()`, or explicit constructors.
- Target a recent Python (3.12+ when the project allows) and lean into `match` statements, `type` statements for aliases, PEP 695 generics, and the built-in generic syntax (`list[int]`, `dict[str, int]`).

## Patterns to correct

- Replace bare `except:` and blanket `except Exception:` with the narrowest exception type the code actually handles.
- Replace mutable default arguments (`def f(x=[])`) with `None` plus an inside-the-body default.
- Remove `global` and module-level mutable state in favor of explicit parameters or a class that owns the state.
- Remove `Any` from public APIs. Narrow with `TypeVar`, `Protocol`, `TypedDict`, or concrete types.
- Replace stringly-typed errors and tuple-coded return values with typed exceptions or small result dataclasses.
- Drop reflexive `list(x)`, `dict(x)`, or `.copy()` calls unless a real aliasing hazard exists.
- Flatten deep inheritance hierarchies in favor of composition and small focused classes.
- Return immutable views or copies of internal collections only when aliasing would cause bugs; otherwise return the value the caller actually needs.

## Verification checklist

- [ ] Ran lint, format, type, and test checks at the broadest relevant scope through `uv run` before considering the work complete.
- [ ] Kept tests in `tests/` mirroring `src/`, with shared fixtures in the narrowest `conftest.py` that works, and reserved integration tests for behavior that crosses boundaries.
- [ ] Preserved a strict lint and type posture and scoped every `# noqa: RULE` and `# type: ignore[code]` narrowly with a rationale comment.
- [ ] Used typed exceptions with `raise ... from err`, never bare `except` or stringly typed failures.
- [ ] Used domain types (`NewType`, dataclasses, pydantic models at boundaries, `Protocol` for structural interfaces) instead of reflexive primitives, `Any`, or deep inheritance.
