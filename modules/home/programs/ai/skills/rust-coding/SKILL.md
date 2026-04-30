---
name: rust-coding
description: "Write and review Rust with strict verification and idiomatic design. Use when: writing, linting, testing, building, reviewing, or refactoring Rust code with cargo and Clippy."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [rust, cargo, clippy]
---

# Rust Coding

Rules for Rust with strict verification, explicit safety boundaries, and idiomatic type design.

## Purpose

Use this skill to write, review, or refactor Rust. Prefer designs where the compiler, Clippy, and tests carry correctness.

## Scope

### Use this skill when

- Writing or reviewing Rust application, library, or tooling code.
- Refactoring modules where ownership, error handling, or API shape matters.
- Choosing validation commands with `cargo check`, `cargo clippy`, `cargo test`, and `cargo fmt`.
- Tightening lint posture, test placement, or unsafe boundaries.

### Do not use this skill when

- The task is mainly toolchain installation, editor configuration, or CI setup.

## Governing rule

Let the type system, compiler, lints, and tests do the work. Make invalid states hard to represent, unsafe behavior hard to introduce, and regressions easy to catch.

## Verification defaults

Finish with the broadest relevant commands, even if iteration was narrowed.

- Compile: `cargo check --workspace`, or `cargo check` for a single crate.
- Lint: `cargo clippy --workspace --all-targets --all-features -- -D warnings`, or the single-crate equivalent.
- Test: `cargo test --workspace`, or `cargo test` for a single crate.
- Format: `cargo fmt --all -- --check`, or the broadest relevant crate-level check.

## Test placement

- Place unit and behavior tests inline in the owning module with `#[cfg(test)] mod tests` by default.
- Keep service, repository, domain, and API behavior tests close to the code they verify.
- Use integration tests when behavior spans crate boundaries, public API flows, or external systems.
- Apply narrower repo-local test rules in addition to these defaults.

## Strictness defaults

Use crate-root lint attributes unless the crate documents another posture:

```rust
#![deny(clippy::all)]
#![deny(unsafe_code)]
#![warn(clippy::pedantic)]
```

For library crates, also deny production `unwrap` and `expect`:

```rust
#![cfg_attr(not(test), deny(clippy::unwrap_used, clippy::expect_used))]
```

Prefer implementation fixes over lint allows. If an allow is necessary, scope it to the smallest item, prefer item-level over module/crate-level, add a rationale, and remove stale allows when touching nearby code.

## Unsafe escape hatch

Use `#![deny(unsafe_code)]` rather than `#![forbid(unsafe_code)]` so a narrow exception is still possible when genuinely justified. Reserve `unsafe` for measured FFI, memory-mapped I/O, or performance-critical cases. Put `#[allow(unsafe_code)]` on the smallest scope and explain the invariant with a `// SAFETY:` comment.

## Error handling

- Libraries: use `thiserror` for typed error enums with meaningful module or crate variants.
- Binaries: use `eyre` or `color-eyre` for ergonomic reports with context.
- Propagate recoverable failures with `?` or explicit `match`.
- Use `Option<T>` when absence is expected and no error reason is needed.
- Keep `.unwrap()` and `.expect()` out of production paths; tests may use them.

## Type and API design

- Wrap primitives in domain-specific newtypes when values must not be interchangeable.
- Use typestate for small, well-defined lifecycles where state transitions should be compile-time checked.
- Use a builder when construction is multi-step or has more than three optional fields; otherwise prefer a plain struct or constructor.
- Match owned enums explicitly so new variants surface. Reserve `_` for `#[non_exhaustive]` external enums or intentionally grouped behavior.
- Give each module or crate semantic error types rather than string-only failures.

## Idiomatic defaults

- Prefer iterators and combinators over manual transform-and-push loops.
- Use `impl Trait` freely in argument position; use return-position `impl Trait` for free functions and inherent methods when it keeps APIs simple.
- Derive traits deliberately. `Debug` and `PartialEq` are common; derive `Clone` only when call sites need duplication.
- Prefer borrowed inputs (`&str`, `&[T]`, `&T`) unless ownership transfer clarifies the API.
- Use `&'static str` only for static data. In struct fields, prefer owned `String` unless a borrowed lifetime is intentional.
- Use `Cow<'_, str>` when borrow-or-allocate behavior is clearer than always allocating.
- Lean into newer editions and language features when the project already targets them and they improve clarity.

## Patterns to correct

- Understand the ownership boundary before adding `.clone()`.
- Replace production `.unwrap()` and `.expect()` with `?`, `match`, or typed errors.
- Use `Rc<RefCell<T>>` or `Arc<Mutex<T>>` only when shared mutable state is genuinely required.
- Split large mixed-responsibility structs into focused types.
- Accept borrowed parameters when ownership is not required; return owned values only when callers need them.
- In libraries, prefer typed error enums over `Box<dyn Error>` so callers can match variants.

## Verification checklist

- [ ] Ran compile, lint, test, and format checks broadly.
- [ ] Kept tests close to code and used integration tests only when behavior crosses boundaries.
- [ ] Preserved strict lint posture and scoped all allows with rationale.
- [ ] Kept unsafe absent or tightly justified with `// SAFETY:`.
- [ ] Used typed errors, deliberate ownership, and idiomatic interfaces instead of reflexive clones, unwraps, or stringly failures.
