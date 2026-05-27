---
name: coding
description: "Per-language coding rules and project bootstrap with strict verification (lint, type-check, test) and idiomatic design. Triggers: Python (`uv`, `ruff`, `mypy`/`ty`, `pytest`, `pyproject.toml`, PEP 723, `prek`, dependabot, migration from pip/Poetry/black/mypy), Rust (`cargo`, Clippy, `Cargo.toml`), TypeScript (`tsc`, ESLint, Prettier, Vitest, Bun, `package.json`); also `.py`/`.ts`/`.tsx`/`.rs` files or 'bootstrap a project'. Skip when: the file is non-code prose."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: python, uv, ruff, ty, mypy, pytest, rust, cargo, clippy, typescript, tsc, eslint, prettier, vitest, bun, project-bootstrap
  version: 3
---

# Coding

<purpose>
Umbrella skill for per-language coding rules. Pick the branch matching the language; load multiple branches when the task crosses languages.
</purpose>

<scope>
  <use_when>
  - Writing, reviewing, or refactoring Python, Rust, or TypeScript code.
  - Bootstrapping a new project with modern tooling.
  - Migrating projects from older toolchains (pip/Poetry/black/mypy → uv/ruff).
  </use_when>

  <do_not_use_when>
  - The language is outside the supported set.
  </do_not_use_when>
</scope>

<governing_rule>
Honor the project's existing toolchain. Type-check, lint, and test before declaring a change complete. Each branch's reference lists its verification defaults.
</governing_rule>

<section name="routing">
- Python (writing, linting, testing, formatting, type-checking, reviewing, refactoring with `uv`, `ruff`, `mypy`, `pytest`) → `references/python-coding.md`
- Modern Python project setup (new projects, migration from pip/Poetry/black/mypy, `pyproject.toml`, `uv` commands, `ruff` config, `prek`, security tooling, dependabot, PEP 723 standalone scripts) → `references/modern-python.md`
- Rust (writing, linting, testing, building, reviewing, refactoring with `cargo` and Clippy) → `references/rust-coding.md`
- TypeScript (writing, linting, formatting, testing, type-checking, reviewing, refactoring with `tsc`, ESLint, Prettier, Vitest; Bun for greenfield) → `references/typescript-coding.md`
</section>

<section name="cross-language-rules">
- Use the package manager from the lockfile. Do not introduce a new toolchain without a reason.
- Frame changes as goal-driven loops: write the failing check first, then make it pass.
- Frameworks layer on top of the language branch; do not duplicate rules from a framework skill into the language reference.
</section>
