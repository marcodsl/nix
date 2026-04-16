---
name: rust-coding
description: "Write and review Rust with strict verification and idiomatic design. Use when: writing, linting, testing, building, reviewing, or refactoring Rust code with cargo and Clippy."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [rust, cargo, clippy]
---

# Rust Coding

Rules for writing and reviewing Rust with strict verification, explicit safety boundaries, and idiomatic type design.

## Purpose

Use this skill to write, review, or refactor Rust code with correctness-first defaults. Prefer designs that let the compiler, Clippy, and tests carry as much of the correctness burden as possible.

## Scope

### Use this skill when

- Writing or reviewing Rust application, library, or tooling code.
- Refactoring Rust modules where ownership, error handling, or API shape matters.
- Deciding how to validate Rust changes with `cargo check`, `cargo clippy`, `cargo test`, and `cargo fmt`.
- Tightening lint posture, test placement, or unsafe usage boundaries in a Rust codebase.

### Do not use this skill when

- The task is mainly about installing toolchains, configuring editors, or setting up CI rather than writing or reviewing Rust code.
- The repository intentionally follows a documented Rust style that conflicts with these defaults and the task is not to change that policy.
- The work is not meaningfully about Rust code structure, behavior, or validation.

## Governing rule

Let the type system, compiler, lints, and tests do the work. Prefer designs that make invalid states harder to represent, unsafe behavior harder to introduce, and regressions easier to catch with broad verification.

## Verification defaults

Treat Rust work as incomplete until the relevant checks pass. Default to the broadest relevant scope for the repository shape in front of you.

1. **Compile**: In workspaces, default to `cargo check --workspace`. In single-crate repositories, default to `cargo check`. During iteration you may narrow to a package, target, or focused build, but finish with the broadest relevant compile check.
2. **Lint**: In workspaces, default to `cargo clippy --workspace --all-targets --all-features -- -D warnings`. In single-crate repositories, use the equivalent broad crate-level command with `--all-targets --all-features -- -D warnings`.
3. **Test**: In workspaces, default to `cargo test --workspace`. In single-crate repositories, default to `cargo test`. During debugging you may narrow to a package or focused test, but finish with the broadest relevant test run.
4. **Format**: In workspaces, default to `cargo fmt --all -- --check`. Otherwise use the broadest relevant `cargo fmt` check for the crate or repository. Local file formatting during iteration is fine, but finish with a broad format check.

## Test placement and organization

- Place unit and behavior tests inline in the owning module with `#[cfg(test)] mod tests` by default.
- Keep service, repository, domain, and API behavior tests close to the code they verify.
- Use integration tests when the behavior spans crate boundaries, public API flows, or external system boundaries.
- If a repository defines narrower file-pattern or test-placement rules, apply them in addition to this skill rather than replacing the skill's general guidance.

## Strictness defaults

Use these crate-root attributes by default unless the crate has a documented reason to differ:

```rust
#![deny(clippy::all)]
#![deny(unsafe_code)]
#![warn(clippy::pedantic)]
```

For library crates, also deny `unwrap` and `expect` outside tests:

```rust
#![cfg_attr(not(test), deny(clippy::unwrap_used, clippy::expect_used))]
```

When Clippy flags code, prefer changing the implementation over silencing the lint. Add a scoped `#[allow(clippy::...)]` only when the lint is a false positive or the compliant alternative would materially worsen the code.

- Scope every `#[allow(clippy::...)]` to the smallest possible item.
- Prefer item-level `#[allow(...)]` over module-wide or crate-wide allows.
- Place a clear rationale comment immediately above every `#[allow(clippy::...)]`, naming the false positive or the tradeoff that makes the compliant alternative materially worse.
- Remove stale `#[allow(clippy::...)]` attributes when touching existing Rust code.

```rust
// False positive: this public API mirrors a wire protocol shape, so wrapping
// these fields in an ad-hoc struct would make call sites less clear.
#[allow(clippy::too_many_arguments)]
fn build_message(
    version: u8,
    kind: u8,
    flags: u16,
    correlation_id: u64,
    payload_len: usize,
    checksum: u32,
    is_retry: bool,
) {
    let _ = (
        version,
        kind,
        flags,
        correlation_id,
        payload_len,
        checksum,
        is_retry,
    );
}
```

### Unsafe escape hatch

Use `#![deny(unsafe_code)]` instead of `#![forbid(unsafe_code)]` so a narrowly scoped exception remains possible when it is genuinely justified.

Reserve `unsafe` for cases like FFI boundaries, memory-mapped I/O, or performance-critical code that has already been measured. Put `#[allow(unsafe_code)]` on the smallest possible scope and explain the invariant with a `// SAFETY:` comment.

```rust
#[allow(unsafe_code)]
// SAFETY: `ptr` is guaranteed non-null and aligned by the allocator contract above.
unsafe { *ptr }
```

## Error handling

- **Libraries**: use `thiserror` for typed error enums with meaningful variants per module or crate.
- **Binaries**: use `eyre` or `color-eyre` for ergonomic reporting with context.
- Use `?` propagation or explicit `match` for recoverable failures.
- Use `Option<T>` when absence is expected and callers do not need an error reason.
- Keep `.unwrap()` and `.expect()` out of production paths. Tests may use them.

## Type and API design

### Newtype pattern

Wrap primitives in domain-specific structs when the values should not be interchangeable.

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct UserId(u64);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct PostId(u64);
```

### Typestate pattern

Model state transitions in the type system when an API has a small, well-defined lifecycle.

```rust
struct Disconnected;
struct Connected;

struct Connection<State> {
    state: State,
}

impl Connection<Disconnected> {
    fn connect(self) -> Result<Connection<Connected>, ConnectError> {
        todo!()
    }
}
```

### Builder pattern

Use a builder when construction is multi-step or when a type has more than three optional fields. Prefer a plain struct or constructor when the shape is small and obvious.

```rust
let config = ClientConfig::builder()
    .host("scanner.internal")
    .port(443)
    .timeout_ms(5_000)
    .build()?;
```

### Exhaustive matching

Match owned enums explicitly so the compiler surfaces newly added variants. Reserve `_` catch-alls for `#[non_exhaustive]` external enums or for cases where you intentionally group several variants with the same behavior.

### Semantic error types

Give each module or crate an error type that names the failure mode instead of storing only strings.

```rust
#[derive(Debug, thiserror::Error)]
enum ConnectError {
    #[error("socket connection timed out")]
    TimedOut,
    #[error("server refused the connection")]
    Refused,
}
```

## Idiomatic Rust defaults

- Prefer iterators and combinators (`.map()`, `.filter()`, `.collect()`) over manual loops that only transform and push values.
- Use `impl Trait` freely in argument position. Use return-position `impl Trait` for free functions and inherent methods; trait methods may need associated types or trait objects instead.
- Derive traits deliberately. `Debug` and `PartialEq` are common defaults; derive `Clone` only when call sites genuinely need duplication.
- Prefer borrowed inputs (`&str`, `&[T]`, `&T`) unless ownership transfer makes the API clearer.
- Use `&'static str` for truly static data. In struct fields, prefer owned `String` unless a borrowed lifetime is intentional and worth the extra complexity.
- Use `Cow<'_, str>` when a function sometimes borrows and sometimes allocates, and that tradeoff is clearer than always allocating.
- When the project already targets a newer Rust edition such as 2024, lean into edition-specific idioms and newer language features when they make the code clearer.

## Patterns to correct

- Understand the ownership boundary before adding `.clone()`. Clone when that tradeoff is intentional, not as a reflex.
- Replace production-path `.unwrap()` and `.expect()` with `?`, `match`, or a typed error.
- Reach for `Rc<RefCell<T>>` or `Arc<Mutex<T>>` only when shared mutable state is genuinely required and simpler ownership patterns do not fit.
- Split large mixed-responsibility structs into smaller focused types.
- Accept borrowed parameters when ownership is not required; return owned values only when callers need ownership.
- In libraries, prefer typed error enums over `Box<dyn Error>` so callers can match on variants.

## Verification checklist

- [ ] Ran compile, lint, test, and format checks at the broadest relevant scope before considering the work complete.
- [ ] Kept tests close to the code by default and used broader integration tests only when the behavior crosses module or crate boundaries.
- [ ] Preserved a strict lint posture and scoped every `#[allow(clippy::...)]` narrowly with a rationale.
- [ ] Kept unsafe code absent or tightly justified with the smallest possible scope and a `// SAFETY:` explanation.
- [ ] Used typed errors, deliberate ownership, and idiomatic interfaces instead of reflexive clones, unwraps, or stringly typed failures.
