---
name: typescript-coding
description: "Write and review TypeScript with strict verification and idiomatic design. Use when: writing, linting, formatting, testing, type-checking, reviewing, or refactoring TypeScript code with tsc, ESLint, Prettier, and Vitest."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [typescript, tsc, eslint, prettier, vitest, bun]
---

# TypeScript Coding

Rules for writing and reviewing TypeScript with strict verification, explicit boundary validation, and idiomatic type design.

## Purpose

Use this skill to write, review, or refactor TypeScript code with correctness-first defaults. Prefer designs that let the type checker, linter, and tests carry as much of the correctness burden as possible, and keep untyped values out of public APIs.

## Scope

### Use this skill when

- Writing or reviewing TypeScript application, library, or tooling code.
- Refactoring TypeScript modules where typing, error handling, or API shape matters.
- Deciding how to validate TypeScript changes with `tsc`, ESLint, Prettier, and Vitest.
- Tightening lint posture, type strictness, or test placement in a TypeScript codebase.

### Do not use this skill when

- The task is mainly about installing toolchains, configuring editors, or setting up CI rather than writing or reviewing TypeScript code.
- The work is in a React component tree or Next.js App Router surface that needs framework-specific guidance. Prefer `react-guidelines` or `nextjs-guidelines` and apply this skill underneath them.

## Governing rule

Let the type checker, linter, and tests do the work. Prefer designs that make invalid states harder to represent, `any` harder to introduce, and regressions easier to catch with broad verification.

## Verification defaults

Treat TypeScript work as incomplete until the relevant checks pass. Default to the broadest relevant scope for the repository shape in front of you. Run every tool through the project's package manager so commands resolve against the locked environment.

Prefer Bun for greenfield projects: `bun install` for setup, `bun run <script>` for scripts, `bunx` for one-off binaries. On brownfield projects, detect the lockfile and use the project's existing manager instead (`pnpm-lock.yaml` -> `pnpm`, `package-lock.json` -> `npm`, `yarn.lock` -> `yarn`). Never mix managers in the same repository.

1. **Type-check**: default to `bun run tsc --noEmit` for a single-project repo, or `bun run tsc -b` when the repo uses TypeScript project references. During iteration you may narrow to a file or `--project` path, but finish with the broadest relevant check.
2. **Lint**: default to `bun run eslint .` with the ESLint v9 flat config at the repo root. During iteration you may narrow to a path or rule, but finish with a repository-wide check.
3. **Format**: default to `bun run prettier --check .`. Local formatting during iteration is fine, but finish with a repository-wide check.
4. **Test**: default to `bun run vitest run`. Prefer Vitest over `bun test` when the project uses React or any browser-leaning runtime, because the jsdom + Testing Library ecosystem is stronger there. During debugging you may narrow to a file, test id, or `-t` pattern, but finish with the broadest relevant run. Add `--coverage` in CI.
5. **Reproducibility**: in CI, use `bun install --frozen-lockfile` (or the project manager's equivalent: `pnpm install --frozen-lockfile`, `npm ci`, `yarn install --immutable`) so the lockfile is enforced.

## Test placement and organization

- Co-locate unit tests next to the source as `foo.ts` + `foo.test.ts` by default. Keep integration tests that cross module or package boundaries under a top-level `tests/` or `e2e/` tree.
- Put shared fixtures and helpers in `tests/support/` or a `test-utils/` package, not behind unlabeled side-effect imports in tests themselves.
- Configure discovery in `vitest.config.ts` rather than relying on defaults, so included and excluded patterns are explicit:

```ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    environment: "node",
    coverage: { reporter: ["text", "lcov"], thresholds: { lines: 80 } },
  },
});
```

- Use `describe.each` / `it.each` with explicit case labels so failure output names the case, not its index.
- Reserve integration tests for behavior that crosses module, package, or external system boundaries. Keep unit tests focused and fast.
- If a repository defines narrower file-pattern or test-placement rules, apply them in addition to this skill rather than replacing the skill's general guidance.

## Strictness defaults

Use these settings by default unless the project has a documented reason to differ.

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2023",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitReturns": true,
    "verbatimModuleSyntax": true,
    "isolatedModules": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

`strict: true` already enables `noImplicitAny`, `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `alwaysStrict`, `useUnknownInCatchVariables`, and `noImplicitThis`, so they do not need to be set again. Add `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` on top because they catch common runtime bugs that bare `strict` misses. Use `verbatimModuleSyntax` with `isolatedModules` so `import type` stays erased and bundlers (esbuild, swc, Turbopack) stay happy.

### ESLint v9 flat config

```ts
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  prettier,
);
```

Use `projectService: true` rather than `project: './tsconfig.json'` for faster type-aware linting. Keep Prettier last so it disables rules that conflict with formatting. Reach for `eslint-plugin-unicorn` or `eslint-plugin-import` only when the project already accepts their opinionated rules.

When the linter or type checker flags code, prefer changing the implementation over silencing the diagnostic. Add a scoped suppression only when the diagnostic is a false positive or the compliant alternative would materially worsen the code.

- Scope every `// @ts-expect-error[code]` and `// eslint-disable-next-line rule-name` to a single line.
- Always name the specific error code or rule. Never use bare `// @ts-ignore` or bare `// eslint-disable-next-line`.
- Prefer `// @ts-expect-error[code]` over `// @ts-ignore` so the suppression fails loudly once the underlying issue is fixed.
- Place a rationale comment immediately above every suppression, naming the false positive or the tradeoff that makes the compliant alternative materially worse.

```ts
// False positive: the generic parser cannot see the schema narrowing performed
// by zod on the line above, which guarantees `payload` is `Payload`.
// @ts-expect-error[2345]
handler.dispatch(payload);
```

## Error handling

- Throw instances of `Error` or a named subclass, never strings or plain objects.
- Give each package a small base `Error` subclass and inherit specific errors from it so callers can catch all failures from your package with a single `instanceof` check.
- Wrap underlying failures with the built-in cause chain: `throw new StorageError('failed to load user', { cause: err })`. Do not concatenate error messages by hand.
- Reserve `Result<T, E>` discriminated unions for expected, non-exceptional failures that every caller must handle locally. Keep thrown exceptions for unexpected or programmer errors.
- Validate external input at the trust boundary (HTTP handlers, CLI entrypoints, env loading, IPC) with a schema library such as Zod or valibot, and pass the parsed type inward. Never funnel untrusted data as `any`.
- Catch the narrowest type that expresses intent. With `useUnknownInCatchVariables` on (default under `strict`), narrow with `instanceof` or a schema before using the caught value.

```ts
export class StorageError extends Error {
  override readonly name = "StorageError";
}

export class ObjectNotFoundError extends StorageError {
  constructor(readonly key: string) {
    super(`no object stored for key ${JSON.stringify(key)}`);
    this.name = "ObjectNotFoundError";
  }
}

export async function load(key: string): Promise<Uint8Array> {
  try {
    return await backend.read(key);
  } catch (err) {
    if (err instanceof NotFound) throw new ObjectNotFoundError(key);
    throw new StorageError(`failed to load ${key}`, { cause: err });
  }
}
```

## Type and API design

### Branded newtypes

Wrap primitives with a brand when values should not be interchangeable at the type level. The runtime value is unchanged; the distinction is enforced by the type checker.

```ts
declare const brand: unique symbol;
export type Brand<T, B> = T & { readonly [brand]: B };

export type UserId = Brand<string, "UserId">;
export type PostId = Brand<string, "PostId">;

export function asUserId(raw: string): UserId {
  return raw as UserId;
}

export function postsFor(_user: UserId): ReadonlyArray<PostId> {
  return [];
}
```

### Discriminated unions for state

Model finite sets of states with string-literal discriminators, and narrow with `switch` so new variants surface as type errors.

```ts
export type Connection = { state: "disconnected" } | { state: "connecting"; attempt: number } | { state: "connected"; socket: WebSocket };

export function describe(c: Connection): string {
  switch (c.state) {
    case "disconnected":
      return "offline";
    case "connecting":
      return `dialing (attempt ${c.attempt})`;
    case "connected":
      return "online";
    default: {
      const _exhaustive: never = c;
      return _exhaustive;
    }
  }
}
```

### `type` vs `interface`

Prefer `type` aliases for object shapes, unions, intersections, and mapped types. Reserve `interface` for declaration merging and for the public surface of a library where consumers benefit from nominal extension. Do not mix the two conventions in the same module.

### `readonly` by default

Default to immutable shapes: `readonly` on object fields, `ReadonlyArray<T>` in function parameters, `Readonly<T>` on public return types that callers should not mutate. Drop the modifier only when mutation is the point of the API.

### `unknown` at boundaries

Accept `unknown` from external sources and narrow it with a schema (`z.parse`) or type guard before use. Do not accept `any` in public APIs. Reserve `any` for escape hatches with a single-line suppression and a rationale.

### `import type` for type-only imports

Use `import type { Foo } from './foo'` so the import is erased at compile time, bundle size stays predictable, and `verbatimModuleSyntax` stays happy. Use value imports only for values.

### `as const` unions over enums

Prefer `as const` tuples plus a derived union type over `enum`, unless interop with a third-party API demands a real enum:

```ts
export const LOG_LEVELS = ["debug", "info", "warn", "error"] as const;
export type LogLevel = (typeof LOG_LEVELS)[number];
```

### Exhaustive matching

Use a `_exhaustive: never` assignment in `default:` branches so adding a new variant surfaces as a type error at every call site that needs to handle it. Alternatively, use `satisfies Record<Variant, Handler>` to force a dispatch table to stay exhaustive.

## Idiomatic TypeScript defaults

- Target a modern ECMAScript baseline (ES2022 or later). Lean into `??`, `?.`, logical assignment, `Object.hasOwn`, `Array.prototype.at`, and `structuredClone` instead of reimplementing them.
- Use `const` by default; use `let` only when reassignment is needed; never use `var`.
- Prefer array methods (`map`, `filter`, `flatMap`, `reduce`) and iterators over manual `for` loops when you are only transforming and filtering, but keep an explicit loop when it reads clearer.
- Reach for `Map` and `Set` when keys are not strings or insertion order matters. Use plain objects for fixed-shape records.
- Use the `satisfies` operator to validate a value against a type without widening:

```ts
const routes = {
  home: "/",
  about: "/about",
} satisfies Record<string, `/${string}`>;
```

- Use template literal types to sharpen public APIs when the return shape depends on the input literal (for example, typed URL builders or event name maps).
- Prefer `async`/`await` over manual `.then()` chains, and handle concurrency with `Promise.all`, `Promise.allSettled`, or `Promise.any` rather than ad-hoc counters.
- Keep import-time code side-effect free. Put initialization inside exported functions, a `main()` entrypoint, or explicit constructors.
- When the project targets a recent TypeScript release, lean into new features that make intent clearer (e.g. `NoInfer<T>`, the `using` declaration, `const` type parameters) rather than reimplementing them.

## Patterns to correct

- Replace `any` in public APIs with `unknown` plus a narrowing schema, a `TypeVar`, or a concrete type.
- Replace non-null assertions (`value!`) with narrowing, a runtime check, or an `invariant(value, 'reason')` helper.
- Replace reflexive type assertions (`value as SomeType`) with a schema parse at the boundary or a user-defined type guard that the compiler can verify.
- Replace hand-rolled `is T` predicates at trust boundaries with a schema library so validation and the type flow from the same source.
- Replace `enum` with `as const` unions unless interop (declaration files, third-party enums) forces the real enum.
- Replace TypeScript `namespace` blocks with ES modules.
- Replace `// @ts-ignore` with either a typed fix or a scoped `// @ts-expect-error[code]: rationale` so the suppression fails loudly when the underlying issue is fixed.
- Replace string-concatenated error messages with the native `cause` chain and typed error subclasses.
- Replace reflexive `Array.from(x)`, `[...x]`, or `Object.assign({}, x)` calls with the original reference unless a real aliasing hazard exists.
- Flatten deep class hierarchies in favor of composition, small focused types, and plain functions.

## Verification checklist

- [ ] Ran type-check, lint, format, and test checks at the broadest relevant scope through the project's package manager before considering the work complete.
- [ ] Co-located unit tests next to source, kept integration tests in `tests/` or `e2e/`, and configured Vitest discovery explicitly.
- [ ] Preserved a strict `tsconfig.json` (including `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes`) and an ESLint v9 flat config with type-aware rules enabled.
- [ ] Scoped every `// @ts-expect-error[code]` and `// eslint-disable-next-line rule-name` narrowly with a rationale; no bare `// @ts-ignore` or bare disables.
- [ ] Used typed `Error` subclasses with `cause` chains, validated external data at trust boundaries with Zod or valibot, and reserved `Result` unions for expected failures.
- [ ] Used domain types (branded newtypes, discriminated unions, `readonly` shapes, `unknown` at boundaries, `import type` for types) instead of reflexive primitives, `any`, or deep class hierarchies.
