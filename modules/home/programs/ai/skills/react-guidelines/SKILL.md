---
name: react-guidelines
description: "Write and review React 19+ code with strict verification and idiomatic design. Use when: writing or reviewing React components, hooks, Server Components, client boundaries, React Compiler usage, Actions, Suspense, composition, and component tests with Vitest, React Testing Library, and Playwright."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [react, react-compiler, server-components, vitest, testing-library, playwright]
---

# React Guidelines

Rules for writing and reviewing React 19+ code with strict verification, clean server/client boundaries, and idiomatic component design.

## Purpose

Use this skill to write, review, or refactor React components and hooks with correctness-first defaults. Prefer designs that keep Server Components the default, `'use client'` at the leaves, state local, and let the React Compiler handle memoization.

## Scope

### Use this skill when

- Writing or reviewing React 19+ component, hook, or feature code.
- Refactoring React modules where server/client boundaries, hook rules, state placement, or composition matter.
- Deciding how to validate React changes with ESLint React plugins, Vitest, React Testing Library, and Playwright.
- Tightening lint posture, test placement, or accessibility coverage in a React codebase.

### Do not use this skill when

- The task is about plain TypeScript with no React surface. Prefer `typescript-coding` instead.
- The task is about Next.js App Router specifics such as routing, caching, Server Actions wiring, or `error.tsx`. Prefer `nextjs-guidelines` and apply this skill underneath for component concerns.
- The task is mainly installing toolchains, configuring editors, or setting up CI.

## Governing rule

Keep Server Components the default, `'use client'` at the leaves, state local, and let the React Compiler do memoization work. Test what the user sees and does, not the component internals.

## Verification defaults

Treat React work as incomplete until the relevant checks pass. Default to the broadest relevant scope for the repository shape in front of you. Run every tool through the project's package manager.

Prefer Bun for greenfield projects (`bun install`, `bun run <script>`, `bunx`). On brownfield, use the project's existing manager (`pnpm`, `npm`, `yarn`) and never mix managers.

1. **Type-check**: inherit the `typescript-coding` defaults (`bun run tsc --noEmit`, or `tsc -b` with project references). React 19 removes the need for `import React from 'react'`, so new-JSX-transform settings must be on.
2. **Lint**: default to `bun run eslint .` with an ESLint v9 flat config that includes `eslint-plugin-react`, `eslint-plugin-react-hooks` (Rules of Hooks and exhaustive-deps as errors), and `eslint-plugin-jsx-a11y`. Add `eslint-plugin-react-compiler` when the compiler is enabled so violations are caught at lint time.
3. **Unit and component tests**: default to `bun run vitest run` with a `jsdom` or `happy-dom` environment, `@testing-library/react`, and `@testing-library/user-event`. Prefer Vitest over `bun test` for component tests because the jsdom + Testing Library story is stronger.
4. **End-to-end**: default to `bun run playwright test` against the application's real build or dev server. Reserve E2E for flows that cross component or route boundaries.
5. **Accessibility**: treat `jsx-a11y` lint rules as errors and run `axe` checks inside component tests where the component shape allows it.

## Test placement and organization

- Co-locate component tests next to source as `Button.tsx` + `Button.test.tsx` by default. Keep integration and E2E flows under a top-level `tests/` or `e2e/` tree.
- Query by accessible role, label, or text with `screen.getByRole(...)` / `getByLabelText(...)`. Avoid `data-testid` unless there is no accessible handle, and prefer fixing the accessibility gap over adding a test id.
- Drive interactions with `@testing-library/user-event`, not fireEvent, so events match real user behavior (focus, pointer, keyboard sequences).
- Prefer `findBy*` and `waitFor` over arbitrary `setTimeout` / `sleep`. The Testing Library has built-in auto-waiting; reach for it before manual timers.
- Use `vi.mock()` at the top of the file for module boundaries (API client, router), not to stub internal component behavior. Mock module edges, exercise component internals.
- Isolate each test: reset state, storage, and any shared module caches in `afterEach`. Do not rely on test ordering.
- If a repository defines narrower file-pattern or test-placement rules, apply them in addition to this skill rather than replacing the skill's general guidance.

## Strictness defaults

Use these settings by default unless the project has a documented reason to differ.

### ESLint flat config additions

```ts
import react from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import jsxA11y from "eslint-plugin-jsx-a11y";
import reactCompiler from "eslint-plugin-react-compiler";

export default [
  { ...react.configs.flat.recommended, settings: { react: { version: "19.0" } } },
  react.configs.flat["jsx-runtime"],
  { plugins: { "react-hooks": reactHooks }, rules: reactHooks.configs.recommended.rules },
  jsxA11y.flatConfigs.recommended,
  {
    plugins: { "react-compiler": reactCompiler },
    rules: { "react-compiler/react-compiler": "error" },
  },
];
```

- Keep `react-hooks/rules-of-hooks` and `react-hooks/exhaustive-deps` as errors.
- Keep `react/jsx-key` as an error.
- Drop the legacy `react/react-in-jsx-scope` rule; the new JSX transform makes it obsolete.
- Turn on `react-compiler/react-compiler` so violations of the Rules of React (impure renders, mutating props, reading refs in render) are caught before build.

### Opt into the React Compiler

Enable the React Compiler in the project's build config (e.g. `babel-plugin-react-compiler` for Vite, the built-in compiler flag in Next.js). Write compiler-friendly code: pure render functions, stable inputs, no side effects in render. The compiler memoizes for you, which is why the defaults below remove most manual memoization.

### Suppressions

Reach for `// eslint-disable-next-line rule-name` only when the rule is a false positive or the compliant alternative would materially worsen the code.

- Scope every disable to a single line and name the specific rule.
- Place a rationale comment immediately above, naming the false positive or the tradeoff.
- Prefer restructuring the component (extract a child, hoist state, split the effect) over adding a suppression.

## Error handling

- Wrap feature and route subtrees in an error boundary so that an unhandled render error does not blank the app. Prefer `react-error-boundary` for the API (`<ErrorBoundary>` with `FallbackComponent`, `onReset`, `onError`) rather than a hand-rolled class.
- Surface async errors by throwing inside a Server Component or by re-throwing from a Client Component effect; the nearest error boundary catches them.
- For form submissions, model errors as returned state from the action, not as thrown exceptions that cross the client boundary. Use `useActionState` to read the shape.
- Validate external input (form data, URL params, fetched JSON) at the boundary with a schema library such as Zod before it reaches component state.
- Never render `Error` objects directly; render a human message and log the cause chain (`error.cause`) to your observability stack.

```tsx
import { ErrorBoundary } from "react-error-boundary";

export function FeatureShell({ children }: { children: React.ReactNode }) {
  return (
    <ErrorBoundary FallbackComponent={FeatureFallback} onError={(err) => logger.error("feature crashed", { cause: err })}>
      {children}
    </ErrorBoundary>
  );
}
```

## Type and API design

### Props

Describe props with a plain `type` alias. Model children as `React.ReactNode`. Avoid `React.FC` because it worsens inference for generics and implies an implicit `children` prop that should be explicit.

```tsx
type ButtonProps = {
  variant?: "primary" | "secondary" | "ghost";
  disabled?: boolean;
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
  children: React.ReactNode;
};

export function Button({ variant = "primary", ...rest }: ButtonProps) {
  return <button data-variant={variant} {...rest} />;
}
```

### Variant props via discriminated unions

When a component has mutually exclusive modes (for example, controlled vs uncontrolled, or linked vs button), model them as a discriminated union so invalid combinations fail to type-check.

```tsx
type InputProps = { kind: "controlled"; value: string; onChange: (v: string) => void } | { kind: "uncontrolled"; defaultValue?: string };
```

### Ref-as-prop in React 19

React 19 lets components accept `ref` as a regular prop. Do not reach for `forwardRef` unless you are maintaining an older surface.

```tsx
type InputRef = React.Ref<HTMLInputElement>;
type TextInputProps = { ref?: InputRef; placeholder?: string };

export function TextInput({ ref, ...rest }: TextInputProps) {
  return <input ref={ref} {...rest} />;
}
```

### Composition over configuration

Prefer composing children and slot props over growing a long list of configuration booleans. Reach for render props or `cloneElement` only when slots and children cannot express the dynamic case.

### Hook return shapes

Return a tuple from a hook when it has exactly two values and the ordering is obvious (`[value, setValue]`). Return a labeled object when there are three or more values, or when labels clarify which field is which.

```tsx
export function useToggle(initial = false) {
  const [on, setOn] = React.useState(initial);
  return [on, () => setOn((prev) => !prev)] as const;
}

export function useUserQuery(id: string) {
  // ... fetch logic
  return { user, isLoading, error, refetch };
}
```

### Explicit return types on exported hooks

Annotate the return type of every exported hook. Inferred types drift silently and break downstream consumers on refactor.

## Idiomatic React defaults

- Server Components by default. Mark the smallest subtree that genuinely needs interactivity, browser APIs, or React hooks with `'use client'`. Nest Client Components inside Server Components; never the other way around.
- With the React Compiler on, skip manual `useMemo`, `useCallback`, and `React.memo` unless profiling shows the cost. The compiler memoizes functions and values; your job is to write pure, stable render code.
- Use `<Suspense>` as the primary async boundary. Let nested fetches stream; place the boundary at the level whose fallback matches the UX you want.
- For mutations, prefer `<form action={serverAction}>` + `useActionState` on the client. Reach for `useTransition` + `startTransition` when the action runs on the client side. Avoid ad-hoc loading flags.
- Keep state local. Lift state only when two or more children genuinely need it. Pass state down with props or through a narrow context, not through a global store by default.
- Use context for cross-cutting concerns (theme, auth, i18n, feature flags) where the value rarely changes. Remember that every Provider must be a Client Component.
- Reach for an external state library (Zustand, Jotai, TanStack Query) when the shape of shared state (caches, derived data, server sync) outgrows component-local state. Pick one store per concern; do not layer Redux on top of React Query on top of context without a reason.
- Use stable list keys. Never use the array index when the list can reorder, filter, or prepend.
- Keep effects out of the render path. `useEffect` is for synchronizing with external systems (subscriptions, browser APIs, non-React libraries), not for computing render output. Derive, memoize, or move to a Server Component instead.
- Use the new React 19 primitives where they match: `useOptimistic` for optimistic updates, `useFormStatus` inside forms, `use(promise)` for reading promises and contexts inside render. Do not reimplement them by hand.
- Follow the new asset loading APIs (`<link rel="preload">` helpers such as `preload`, `preinit`, `preloadModule`) instead of manually injecting `<link>` tags.

## Patterns to correct

- Replace class components with functional components plus hooks, unless the class is used to plug into an external library that requires it.
- Remove reflexive `useMemo`, `useCallback`, and `React.memo` when the React Compiler is on and the cost has not been measured. Keep them only for ref identity required by a third-party API.
- Move `'use client'` from an entire page or layout down to the smallest interactive leaf. Data fetching should happen in the Server Component parent.
- Replace `useEffect`-based data fetching in routes with a Server Component fetch plus `<Suspense>`, or with a dedicated data library (TanStack Query, SWR) inside a Client Component if interactivity demands it.
- Replace `React.FC<Props>` with a plain prop type and an ordinary function component.
- Replace `forwardRef` with React 19 ref-as-prop.
- Replace array-index keys in lists that can reorder with stable domain IDs.
- Replace prop-drilling chains of four or more levels with composition (children, slots) or a narrowly scoped context.
- Replace `useEffect` + `useState` that only derive from props with a plain computed value, memoized only if profiling shows a hot path.
- Replace `any` or `unknown` in exported props with concrete types or a discriminated union.
- Replace test queries that rely on class names, test ids, or `container.querySelector` with accessible role, label, or text queries.

## Verification checklist

- [ ] Ran type-check, lint, unit, and E2E tests at the broadest relevant scope before considering the work complete.
- [ ] Co-located component tests next to source, kept integration and E2E under `tests/` or `e2e/`, and queried by accessible role, label, or text.
- [ ] Kept `react-hooks/rules-of-hooks`, `react-hooks/exhaustive-deps`, `react/jsx-key`, and `react-compiler/react-compiler` as errors.
- [ ] Scoped `'use client'` to the smallest interactive leaf; kept data fetching and heavy dependencies in Server Components.
- [ ] Removed reflexive `useMemo` / `useCallback` / `React.memo` under the React Compiler and avoided effects that only derive from props.
- [ ] Used plain prop types (no `React.FC`), discriminated unions for variant props, ref-as-prop instead of `forwardRef`, and composition over configuration.
- [ ] Wrapped feature or route subtrees in an error boundary and modeled action errors as returned state rather than thrown exceptions across the client boundary.
