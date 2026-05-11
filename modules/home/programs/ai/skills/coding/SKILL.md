---
name: coding
description: "Per-language coding rules and project bootstrap with strict verification and idiomatic design. Triggers: Python (uv, ruff, mypy, ty, pytest, pyproject, PEP 723, prek, dependabot, project bootstrap, migration from pip/Poetry/black/mypy), Rust (cargo, Clippy), TypeScript (tsc, ESLint, Prettier, Vitest, Bun). Use when writing, linting, formatting, testing, type-checking, reviewing, or refactoring code in those languages, or when configuring a new project with modern tooling."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: python, uv, ruff, ty, mypy, pytest, rust, cargo, clippy, typescript, tsc, eslint, prettier, vitest, bun, project-bootstrap
---

# Coding

Umbrella skill for per-language coding rules. Pick the branch that matches the language; if the task crosses languages, load each one as needed. React- and Next.js-specific rules live in their own skills (`react-guidelines`, `nextjs`) and layer on top of the relevant language reference here.

## Routing

| When the task involves… | Read |
| --- | --- |
| Writing, linting, testing, formatting, type-checking, reviewing, or refactoring Python with `uv`, `ruff`, `mypy`, `pytest` | [references/python-coding.md](./references/python-coding.md) |
| Bootstrapping a new Python project, migrating from `pip`/Poetry/`black`/`mypy`, configuring `pyproject.toml`, `uv` commands, `ruff` config, `prek`, security tooling, dependabot, PEP 723 standalone scripts | [references/modern-python.md](./references/modern-python.md) |
| Writing, linting, testing, building, reviewing, or refactoring Rust with `cargo` and Clippy | [references/rust-coding.md](./references/rust-coding.md) |
| Writing, linting, formatting, testing, type-checking, reviewing, or refactoring TypeScript with `tsc`, ESLint, Prettier, Vitest (and Bun for greenfield) | [references/typescript-coding.md](./references/typescript-coding.md) |

## Cross-language rules

- Use the project manager from the lockfile. Honor the existing toolchain choice; don't introduce a new one without a reason.
- Type-check, lint, and test before declaring a change complete. Each branch lists the verification defaults for its language.
- Frame changes as goal-driven loops: write the failing check first, then make it pass.
- Frameworks layer on top of the language branch — do not duplicate rules from the framework skill into the language reference.
