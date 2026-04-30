---
name: react-guidelines
description: "Write and review React 19+ code with strict verification and idiomatic design. Use when: writing or reviewing React components, hooks, Server Components, client boundaries, React Compiler usage, Actions, Suspense, composition, and component tests with Vitest, React Testing Library, and Playwright."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [react, react-compiler, server-components, vitest, testing-library, playwright]
---

# React Guidelines

Rules for React 19+ with strict verification, clean server/client boundaries, and idiomatic component design.

## Purpose

Use this skill to write, review, or refactor React components and hooks. Keep Server Components the default, put `'use client'` at the leaves, keep state local, and let the React Compiler handle memoization.

## Scope

### Use this skill when

- Writing or reviewing React component, hook, or feature code.
- Refactoring server/client boundaries, hook usage, state placement, or composition.
- Choosing validation with ESLint React plugins, Vitest, Testing Library, and Playwright.
- Tightening accessibility, lint posture, or component test placement.

### Do not use this skill when

- The task is plain TypeScript with no React surface. Use `typescript-coding`.
- Next.js App Router specifics are central. Use `nextjs-guidelines` and apply this underneath for component concerns.
- The task is mainly toolchain, editor, or CI setup.

## Governing rule

Server Components by default, `'use client'` at the smallest interactive leaf, local state first, compiler-friendly render code, and tests based on what users see and do.

## Verification defaults

- Use the project's existing package manager; prefer Bun only for greenfield.
- Type-check: inherit `typescript-coding` defaults. React 19 should use the new JSX transform; no `import React from "react"` for JSX.
- Lint: `eslint .` with `eslint-plugin-react`, `eslint-plugin-react-hooks`, `eslint-plugin-jsx-a11y`, and `eslint-plugin-react-compiler` when the compiler is enabled.
- Component tests: `vitest run` with `jsdom` or `happy-dom`, `@testing-library/react`, and `@testing-library/user-event`. Prefer Vitest over `bun test` for browser-like tests.
- E2E: `playwright test` against the real build or dev server; reserve it for flows crossing component or route boundaries.
- Accessibility: keep `jsx-a11y` rules as errors and add axe checks where component shape allows.

## Test placement

- Co-locate component tests by default: `Button.tsx` plus `Button.test.tsx`.
- Keep integration and E2E flows under `tests/` or `e2e/`.
- Query by role, label, or text with Testing Library. Avoid `data-testid` unless there is no accessible handle; prefer fixing the accessibility gap.
- Drive interactions with `user-event`, not low-level `fireEvent`.
- Prefer `findBy*` and `waitFor` over arbitrary timers.
- Mock module boundaries (`vi.mock` for API clients, routers, storage), not internal component behavior.
- Reset state, storage, and module caches in `afterEach`; do not rely on test order.

## Strictness defaults

- Keep `react-hooks/rules-of-hooks`, `react-hooks/exhaustive-deps`, `react/jsx-key`, and `react-compiler/react-compiler` as errors.
- Drop legacy `react/react-in-jsx-scope`; the new JSX transform makes it obsolete.
- Enable the React Compiler through the build config (`babel-plugin-react-compiler`, Next.js compiler flag, or project equivalent).
- Write compiler-friendly code: pure renders, stable inputs, no prop mutation, no reading refs in render, no side effects in render.
- Prefer restructuring (extract a child, hoist state, split an effect) over suppressing lint. If a suppression is necessary, scope it to one line, name the rule, and add a rationale.

## Error handling

- Wrap feature or route subtrees in an error boundary; prefer `react-error-boundary` for `FallbackComponent`, `onReset`, and `onError`.
- Surface async errors by throwing in a Server Component or rethrowing from a Client Component effect so the nearest boundary catches them.
- For form submissions, model errors as returned state from the action and read them with `useActionState`; do not throw across the client boundary.
- Validate form data, URL params, and fetched JSON at the boundary with a schema before it reaches component state.
- Never render `Error` objects directly; show user-safe messages and log the cause chain.

## Type and API design

- Props: use a plain `type` alias. Model `children` explicitly as `React.ReactNode`. Avoid `React.FC`.
- Variant props: use discriminated unions for mutually exclusive modes such as controlled vs uncontrolled or link vs button.
- Refs: in React 19, accept `ref` as a prop; use `forwardRef` only for older surfaces.
- Composition: prefer children and slot props over boolean-heavy configuration. Use render props or `cloneElement` only when slots cannot express the case.
- Hooks: return a tuple only for exactly two obvious values; return a labeled object for three or more values or when labels matter.
- Exported hooks: annotate return types so downstream consumers do not break silently after refactors.

## Idiomatic defaults

- Use Server Components by default. Client Components are only for interactivity, browser APIs, or hooks; nest them inside Server Components.
- With the compiler on, skip reflexive `useMemo`, `useCallback`, and `React.memo` unless profiling or third-party ref identity requires them.
- Use `<Suspense>` as the async boundary and place fallbacks where they match the UX.
- Prefer `<form action={serverAction}>` plus `useActionState` for mutations; use `useTransition` for client-side actions.
- Keep state local; lift only when multiple children need it. Use narrow context for rare cross-cutting values.
- Reach for external state only when shared state, caches, derived data, or server sync outgrows component-local state.
- Use stable domain keys, never array index keys when lists can reorder, filter, or prepend.
- Use `useEffect` only to synchronize with external systems; derive render output directly or move it server-side.
- Use React 19 primitives (`useOptimistic`, `useFormStatus`, `use(promise)`) and asset-loading helpers instead of reimplementing them.

## Patterns to correct

- Replace class components with functions and hooks unless an external API requires classes.
- Remove reflexive memoization under the compiler unless measured or required for identity.
- Move broad `'use client'` directives down to interactive leaves.
- Replace route data fetching in `useEffect` with Server Component fetches, Suspense, or a data library for truly client-driven data.
- Replace `React.FC`, old `forwardRef` surfaces, index keys, four-level prop drilling, derived-state effects, exported `any`, and inaccessible test queries.

## Verification checklist

- [ ] Ran type-check, lint, unit/component tests, and relevant E2E tests broadly.
- [ ] Tested through accessible roles, labels, or text and used `user-event`.
- [ ] Kept hook, accessibility, key, and compiler rules as errors.
- [ ] Scoped `'use client'` to the smallest leaf and kept data fetching/heavy dependencies server-side.
- [ ] Used plain prop types, discriminated unions, ref-as-prop, composition, typed hooks, error boundaries, and action-returned error state.
