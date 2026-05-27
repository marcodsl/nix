---
name: react-guidelines
description: "Write and review React 19+ code with strict verification and idiomatic design: Server Components by default, `'use client'` at the smallest interactive leaf. Triggers: `.tsx`/`.jsx` components, hooks (`useState`, `useEffect`, `useMemo`, `useCallback`, `useActionState`, `useOptimistic`, `useFormStatus`, `use()`), `'use client'` boundaries, React Compiler (`react-compiler/react-compiler`, `babel-plugin-react-compiler`), `react-error-boundary`, ref-as-prop / `forwardRef`, `@testing-library/react`, `user-event`, Vitest component tests, Playwright. Skip when: plain TypeScript without React."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: react, react-compiler, server-components, vitest, testing-library, playwright
  version: 3
---

# React Guidelines

<purpose>
Write, review, or refactor React 19+ components and hooks with strict verification, clean server/client boundaries, and idiomatic design.
</purpose>

<scope>
  <use_when>
  - Writing or reviewing component, hook, or feature code.
  - Refactoring server/client boundaries, hook usage, state placement, or composition.
  - Choosing validation with ESLint React plugins, Vitest, Testing Library, Playwright.
  - Tightening accessibility, lint posture, or component test placement.
  </use_when>

  <do_not_use_when>
  - Plain TypeScript with no React surface.
  - The task is mainly toolchain, editor, or CI setup.
  </do_not_use_when>
</scope>

<governing_rule>
Server Components by default; `'use client'` at the smallest interactive leaf. Keep state local, write compiler-friendly renders, and test based on what users see and do.
</governing_rule>

<section name="verification">
- Use the project's package manager. Prefer Bun only for greenfield.
- Type-check: inherit the TypeScript branch of the `coding` skill. React 19 uses the new JSX transform; no `import React from "react"` for JSX.
- Lint: `eslint .` with `eslint-plugin-react`, `eslint-plugin-react-hooks`, `eslint-plugin-jsx-a11y`, and `eslint-plugin-react-compiler` when the compiler is enabled.
- Component tests: `vitest run` with `jsdom`/`happy-dom`, `@testing-library/react`, and `@testing-library/user-event`. Prefer Vitest over `bun test` for browser-like tests.
- E2E: `playwright test` against the real build or dev server; reserve for flows crossing component or route boundaries.
- Accessibility: keep `jsx-a11y` rules as errors; add axe checks where component shape allows.
</section>

<section name="test-placement">
- Co-locate component tests: `Button.tsx` plus `Button.test.tsx`.
- Integration and E2E flows go under `tests/` or `e2e/`.
- Query by role, label, or text with Testing Library. Avoid `data-testid` unless there is no accessible handle; prefer fixing the accessibility gap.
- Drive interactions with `user-event`, not low-level `fireEvent`.
- Prefer `findBy*` and `waitFor` over arbitrary timers.
- Mock module boundaries (`vi.mock` for API clients, routers, storage), not internal component behavior.
- Reset state, storage, and module caches in `afterEach`; do not rely on test order.
</section>

<section name="strictness">
- Keep `react-hooks/rules-of-hooks`, `react-hooks/exhaustive-deps`, `react/jsx-key`, and `react-compiler/react-compiler` as errors.
- Drop legacy `react/react-in-jsx-scope`.
- Enable the React Compiler through the build config (`babel-plugin-react-compiler`, Next.js compiler flag, or equivalent).
- Compiler-friendly code: pure renders, stable inputs, no prop mutation, no reading refs in render, no side effects in render.
- Prefer restructuring (extract a child, hoist state, split an effect) over suppressing lint. If suppressing, scope to one line, name the rule, and add a rationale.
</section>

<section name="error-handling">
- Wrap feature or route subtrees in an error boundary; prefer `react-error-boundary` for `FallbackComponent`, `onReset`, `onError`.
- Surface async errors by throwing in a Server Component or rethrowing from a Client Component effect so the nearest boundary catches them.
- For form submissions, model errors as returned state from the action and read with `useActionState`; do not throw across the client boundary.
- Validate form data, URL params, and fetched JSON at the boundary with a schema before component state.
- Never render `Error` objects directly; show user-safe messages and log the cause chain.
</section>

<section name="types-and-api">
- Props: plain `type` alias. Model `children` as `React.ReactNode`. Avoid `React.FC`.
- Variant props: discriminated unions for mutually exclusive modes (controlled vs uncontrolled, link vs button).
- Refs: in React 19, accept `ref` as a prop; use `forwardRef` only for older surfaces.
- Composition: prefer children and slot props over boolean-heavy configuration. Use render props or `cloneElement` only when slots cannot express the case.
- Hooks: return a tuple for exactly two obvious values; return a labeled object for three+ values or when labels matter.
- Exported hooks: annotate return types so consumers do not break silently after refactors.
</section>

<section name="idiomatic-defaults">
- Server Components by default; Client Components only for interactivity, browser APIs, or hooks. Nest clients inside servers.
- With the compiler on, skip reflexive `useMemo`, `useCallback`, `React.memo` unless profiling or third-party ref identity requires them.
- Use `<Suspense>` as the async boundary; place fallbacks where they match the UX.
- Prefer `<form action={serverAction}>` plus `useActionState` for mutations; `useTransition` for client-side actions.
- Keep state local; lift only when multiple children need it. Use narrow context for rare cross-cutting values.
- Reach for external state only when shared state, caches, derived data, or server sync outgrows component-local state.
- Use stable domain keys; never array index keys when lists can reorder, filter, or prepend.
- Use `useEffect` only to sync with external systems; derive render output directly or move it server-side.
- Use React 19 primitives (`useOptimistic`, `useFormStatus`, `use(promise)`) and asset-loading helpers instead of reimplementing them.
</section>

<section name="anti-patterns">
- Class components when functions and hooks suffice.
- Reflexive memoization under the compiler.
- Broad `'use client'` directives instead of leaf-level placement.
- Route data fetching in `useEffect` instead of Server Component fetches, Suspense, or a data library.
- `React.FC`, old `forwardRef` surfaces, index keys, four-level prop drilling, derived-state effects, exported `any`, inaccessible test queries.
</section>

<review_checklist>
- Ran type-check, lint, unit/component tests, and relevant E2E tests.
- Tested through accessible roles, labels, or text; drove interactions with `user-event`.
- Kept hook, accessibility, key, and compiler rules as errors.
- Scoped `'use client'` to the smallest leaf; kept data fetching and heavy deps server-side.
- Used plain prop types, discriminated unions, ref-as-prop, composition, typed hooks, error boundaries, and action-returned error state.
</review_checklist>
