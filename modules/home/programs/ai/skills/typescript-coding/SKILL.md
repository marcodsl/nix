---
name: typescript-coding
description: "Write and review TypeScript with strict verification and idiomatic design. Use when: writing, linting, formatting, testing, type-checking, reviewing, or refactoring TypeScript code with tsc, ESLint, Prettier, and Vitest."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [typescript, tsc, eslint, prettier, vitest, bun]
---

# TypeScript Coding

Rules for TypeScript with strict verification, boundary validation, and idiomatic type design.

## Purpose

Use this skill to write, review, or refactor TypeScript. Prefer designs where `tsc`, ESLint, Prettier, and tests carry correctness, and where untyped values cannot leak into public APIs.

## Scope

### Use this skill when

- Writing or reviewing TypeScript application, library, or tooling code.
- Refactoring modules where typing, error handling, or API shape matters.
- Choosing validation commands with `tsc`, ESLint, Prettier, and Vitest.
- Tightening lint posture, type strictness, or test placement.

### Do not use this skill when

- The task is mainly toolchain, editor, or CI setup.
- React or Next.js framework rules are central. Use `react-guidelines` or `nextjs-guidelines` and apply this underneath.

## Governing rule

Let the type checker, linter, and tests do the work. Make invalid states hard to represent, `any` hard to introduce, and regressions easy to catch.

## Verification defaults

- Use the existing package manager from the lockfile. For greenfield, prefer Bun: `bun install`, `bun run <script>`, `bunx`. Never mix managers.
- Type-check: `bun run tsc --noEmit`, or `bun run tsc -b` with project references. Finish broad even if iteration was narrowed.
- Lint: `bun run eslint .` with ESLint v9 flat config; finish repository-wide.
- Format: `bun run prettier --check .`; format locally as needed, verify broadly.
- Test: `bun run vitest run`; narrow during debugging, finish broad. Use `--coverage` in CI.
- CI install: `bun install --frozen-lockfile` or the current manager's frozen equivalent.

## Test placement

- Co-locate unit tests by default: `foo.ts` plus `foo.test.ts`.
- Keep cross-module, package, or external-system integration tests under `tests/` or `e2e/`.
- Put shared fixtures in `tests/support/` or a `test-utils/` package.
- Configure Vitest discovery explicitly in `vitest.config.ts` with include/exclude patterns, environment, and coverage thresholds.
- Use `describe.each` and `it.each` with explicit labels. Keep unit tests focused and fast.
- Apply narrower repo-local placement rules in addition to these defaults.

## Strictness defaults

Use strict project settings unless the repo documents a different posture:

- `target: "ES2023"`, `module: "ESNext"`, `moduleResolution: "bundler"`.
- `strict: true`, plus `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noImplicitOverride`, `noFallthroughCasesInSwitch`, `noImplicitReturns`.
- `verbatimModuleSyntax`, `isolatedModules`, `resolveJsonModule`, `esModuleInterop`, `forceConsistentCasingInFileNames`, and usually `skipLibCheck`.
- ESLint v9 flat config with `@eslint/js`, `typescript-eslint` strict type-checked and stylistic configs, `parserOptions.projectService: true`, and Prettier last.

Prefer implementation fixes over suppressions. If a suppression is justified:

- Scope it to one line.
- Name the specific TS code or ESLint rule.
- Prefer `@ts-expect-error[code]` over `@ts-ignore`.
- Put a rationale immediately above it.

## Error handling

- Throw `Error` instances or named subclasses, never strings or plain objects.
- Give each package a small base error class and inherit specific errors from it.
- Preserve causes with `throw new StorageError("failed to load user", { cause: err })`; do not concatenate messages by hand.
- Use `Result<T, E>` unions only for expected, non-exceptional failures every caller must handle.
- Validate external input at trust boundaries with Zod, valibot, or an equivalent schema. Pass parsed types inward.
- Catch `unknown` and narrow with `instanceof` or a schema before use.

## Type and API design

- Brand primitive domain IDs when they should not be interchangeable.
- Model finite states with discriminated unions and exhaustive `switch` checks using a `never` assignment or exhaustive dispatch table.
- Prefer `type` aliases for object shapes, unions, intersections, and mapped types. Reserve `interface` for declaration merging or public library extension.
- Use `readonly` fields and `ReadonlyArray<T>` by default; drop immutability only when mutation is the API.
- Accept `unknown` at external boundaries and narrow before use. Do not expose `any` in public APIs.
- Use `import type` for type-only imports under `verbatimModuleSyntax`.
- Prefer `as const` tuples plus derived unions over `enum`, unless third-party interop needs a real enum.
- Use `satisfies` to validate values without widening, and template literal types when public API shape depends on literal input.

## Idiomatic defaults

- Target modern ECMAScript and use platform features (`??`, `?.`, `Object.hasOwn`, `.at`, `structuredClone`) instead of reimplementing them.
- Use `const` by default, `let` only for reassignment, never `var`.
- Prefer array methods and iterators for transformations; keep explicit loops when they read clearer.
- Use `Map` and `Set` for non-string keys or insertion order; use plain objects for fixed-shape records.
- Prefer `async`/`await`; use `Promise.all`, `allSettled`, or `any` for concurrency.
- Keep import-time code side-effect free; initialize inside functions, constructors, or `main()`.
- Use recent TypeScript features when they make intent clearer (`NoInfer`, `using`, `const` type parameters) instead of local reinventions.

## Patterns to correct

- Replace public `any` with `unknown` plus schema narrowing, generics, or concrete types.
- Replace `value!` with narrowing, runtime checks, or an invariant helper.
- Replace reflexive `as SomeType` with schema parsing or verified type guards.
- Replace hand-rolled trust-boundary predicates with a schema library.
- Replace `enum` with `as const` unions unless interop requires it.
- Replace TypeScript `namespace` blocks with ES modules.
- Replace bare `@ts-ignore` or bare disables with typed fixes or scoped suppressions.
- Replace string-concatenated errors with cause chains and typed error subclasses.
- Avoid reflexive copies and deep class hierarchies; use composition and focused types.

## Verification checklist

- [ ] Ran type-check, lint, format, and tests broadly through the project manager.
- [ ] Placed tests according to repo rules and configured Vitest discovery explicitly.
- [ ] Preserved strict TS and type-aware ESLint posture.
- [ ] Scoped all suppressions with codes/rules and rationale.
- [ ] Used typed errors, boundary schemas, domain types, readonly shapes, `unknown` at boundaries, and `import type` where appropriate.
