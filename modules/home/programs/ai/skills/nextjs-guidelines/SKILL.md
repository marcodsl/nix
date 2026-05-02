---
name: nextjs-guidelines
description: "Write and review Next.js 16+ App Router code with strict verification and idiomatic design. Use when: writing or reviewing Server Components, Server Actions, Route Handlers, Cache Components (use cache), PPR, typedRoutes, middleware, error.tsx, and route-level patterns with Vitest and Playwright."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: nextjs, app-router, cache-components, server-actions, ppr, vitest, playwright
---

# Next.js Guidelines

Rules for Next.js 16+ App Router code with strict verification, explicit caching boundaries, and idiomatic routes/actions.

## Purpose

Use this skill to write, review, or refactor App Router applications. Keep Server Components the default, opt into caching with `"use cache"`, isolate dynamic content behind `<Suspense>`, and validate every boundary.

## Scope

### Use this skill when

- Writing or reviewing App Router pages, layouts, route handlers, Server Actions, middleware, or metadata.
- Choosing between Server Components, Client Components, Route Handlers, and Server Actions.
- Designing cache, revalidation, or invalidation with Cache Components, `cacheLife`, `cacheTag`, `updateTag`, and `revalidateTag`.
- Tightening PPR, streaming, Suspense boundaries, `typedRoutes`, or boundary validation.

### Do not use this skill when

- The task is plain TypeScript with no Next.js surface. Use `typescript-coding`.
- The task is React primitives without App Router concerns. Use `react-guidelines` and apply this on top.
- The repo is legacy Pages Router only and migration is out of scope.
- The task is mainly toolchain, editor, or CI setup.

## Governing rule

App Router first, Server Components by default, `"use cache"` only where caching is intentional, `'use client'` at leaves, and schema-validated inputs at every boundary. Cache stable data, stream dynamic data, and never hide dynamic reads inside cached scopes.

## Verification defaults

- Use the project manager from the lockfile. Prefer Bun only for greenfield; honor existing Next.js monorepo managers.
- Type-check: inherit `typescript-coding` defaults and enable `typedRoutes`.
- Lint: `next lint` or `eslint .` with `eslint-config-next`; keep `@next/next/core-web-vitals` on.
- Build: `next build`; it catches server/client boundary crossings, unused route segments, and dynamic APIs under `"use cache"`.
- Unit/component tests: `vitest run`; inherit placement and Testing Library guidance from `react-guidelines`.
- E2E: `playwright test` against `next start` or `next dev`; reserve it for routing, caching, Server Actions, or middleware flows.
- CI: frozen install and a pinned Node version that matches the Next.js support matrix.

## Test placement

- Co-locate component tests; keep route-level integration under `tests/` or the route segment's `_tests/` folder.
- Mock `next/navigation`, `next/headers`, and server-only modules in Vitest through shared setup.
- Test Server Components by rendering the exported function or asserting rendered HTML in Playwright.
- Drive Server Action flows in Playwright: fill form, submit, then assert server state and UI update.
- Exercise middleware and Route Handlers with E2E requests rather than fragile unit mocks.

## Strictness defaults

Use documented alternatives only when the repo has a reason:

- `next.config.ts`: `cacheComponents: true`, `typedRoutes: true`, `reactCompiler: true`, and `experimental.ppr: "incremental"` during migration.
- Environment: load and validate `process.env` once in `env.ts` with a schema; import the parsed shape elsewhere.
- ESLint: keep `eslint-config-next` layered with the TypeScript and React configs. Treat `no-html-link-for-pages`, `no-img-element`, and `no-sync-scripts` as errors.

## Error handling

- Add `error.tsx` boundaries at route segments that can fail independently. They must be Client Components with `'use client'`.
- Add `not-found.tsx` where `notFound()` can be called.
- In Server Components, use `notFound()`, `forbidden()`, or `unauthorized()` instead of custom status strings.
- In Server Actions, return typed discriminated unions and read them with `useActionState`; do not throw across the client boundary.
- In Route Handlers, validate request bodies/search params, catch failures, and return `NextResponse.json(body, { status })` with explicit status codes.
- Untrusted input never reaches service code unvalidated.

## Type and API design

- Page/layout props: in Next.js 16, `params` and `searchParams` are promises. Type the promise shape and `await` both before use.
- Route Handlers: type request and response through schemas; use them for external API consumers, webhooks, streaming responses, and non-UI integrations.
- Server Actions: keep them thin over colocated services (`_lib`, `_services`, or `_actions`), make mutations idempotent where possible, and redirect or revalidate on success.
- Typed routes: with `typedRoutes: true`, use `Route` from `next` across generic boundaries and avoid hand-built route strings.
- Metadata: use `generateMetadata` for dynamic metadata and exported `metadata` objects for static metadata.

## Idiomatic defaults

- Server Components by default. Use Client Components only for interactivity, browser APIs, or hooks; push the boundary as deep as possible.
- Cache explicitly with `"use cache"` on async functions or components. Keep cache inputs small and serializable.
- Tune revalidation with `cacheLife`; default to the shortest window that meets the product requirement.
- Invalidate with `cacheTag` plus `updateTag` for read-your-writes or `revalidateTag` for stale-while-revalidate. Use `revalidatePath` only when tags cannot model the change.
- Call `connection()` before non-deterministic values (`Date.now`, `Math.random`, crypto IDs, cookies, headers) and wrap the subtree in `<Suspense>`.
- Use Suspense fallbacks that match final layout to keep CLS low.
- Colocate private route files in `_lib/`, `_components/`, `_actions/`, or `_services/`.
- Use Parallel and Intercepting Routes for URL-backed modals/drawers.
- Use Server Actions for mutations from your UI; Route Handlers for external consumers, webhooks, and streaming.
- Keep middleware thin for auth gates, redirects, buckets, and header rewrites; put business logic in actions or services.
- Use `<Link>`, `<Image>`, `next/font`, and the Metadata API. Do not bypass framework primitives.
- Roll out PPR incrementally with `experimental.ppr: "incremental"` and route-level opt-in.
- Prefer Cache Components plus tag invalidation over mixing cache models on the same surface.

## Patterns to correct

- Replace `getServerSideProps` and `getStaticProps` with App Router Server Component fetches.
- Move broad `'use client'` directives to the smallest interactive leaf.
- Replace internal `<a href>` with `<Link>` and `<img>` with `<Image>` plus dimensions and `priority` when needed.
- Replace hand-assembled routes with typed `Route` helpers.
- Replace non-deterministic reads under `"use cache"` with `connection()` plus `<Suspense>`.
- Replace broad `revalidatePath` with tag invalidation when tags fit.
- Replace route-level `useEffect` fetching with Server Component fetches or a client data library only when interactivity requires it.
- Replace global-state modals with Intercepting plus Parallel Routes when the modal maps to URL state.
- Replace scattered `process.env` reads with validated `env.ts`.
- Replace Server Action throws across client boundaries with typed result unions.
- Replace `error.tsx` files missing `'use client'`.
- Replace Client Component fetches that can run server-side with Server Component fetches plus props.

## Verification checklist

- [ ] Ran type-check, lint, build, Vitest, and relevant Playwright checks broadly.
- [ ] Kept `cacheComponents`, `typedRoutes`, `reactCompiler`, and incremental PPR on where applicable.
- [ ] Awaited and typed `params` and `searchParams`; used typed `Route` helpers.
- [ ] Added proper `error.tsx`/`not-found.tsx` surfaces and used framework navigation helpers.
- [ ] Scoped `"use cache"`, `cacheLife`, tag invalidation, `connection()`, and Suspense correctly.
- [ ] Kept Server Actions thin, validated inputs, returned typed results, and used Next.js primitives.
