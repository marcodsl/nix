---
name: nextjs
description: "Write and review Next.js 16+ App Router code with strict verification and idiomatic design, plus the Vercel-Labs Next.js best-practices reference (auto-applied alongside the guidelines). Triggers: Server Components, Server Actions, Route Handlers, Cache Components (use cache), PPR, typedRoutes, middleware/proxy, error.tsx, file conventions, RSC boundaries, async APIs (params/searchParams/cookies/headers), data patterns, hydration, Suspense, parallel and intercepting routes, metadata, OG images, image/font, bundling, scripts, self-hosting, debug tricks, Vitest, Playwright."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: nextjs, app-router, rsc, server-components, server-actions, cache-components, ppr, data-fetching, metadata, hydration, suspense, vitest, playwright
---

# Next.js

Umbrella skill for Next.js 16+ App Router work. Two reference layers:

- `references/nextjs-guidelines.md` — opinionated rules and verification defaults for writing or reviewing App Router code (caching, Server Actions, typed routes, error boundaries, test placement). Use this when authoring or reviewing code.
- `references/nextjs-best-practices/` — the Vercel-Labs catalog of file conventions, async APIs, data patterns, image/font/bundling, hydration debugging, and self-hosting, indexed below. Auto-applied background reference; consult for canonical patterns.

## Routing

| When the task involves… | Read |
| --- | --- |
| Cache Components (`"use cache"`), `cacheLife`, `cacheTag`, `updateTag`, `revalidateTag`, PPR, typed routes, Server Action design, `error.tsx`/`not-found.tsx`, Vitest/Playwright placement, verification checklist | [references/nextjs-guidelines.md](./references/nextjs-guidelines.md) |
| File conventions, route segments, `(.)` interceptors, parallel routes, middleware → proxy rename | [references/nextjs-best-practices/file-conventions.md](./references/nextjs-best-practices/file-conventions.md) |
| RSC boundaries, async client component traps, non-serializable props, Server Action exceptions | [references/nextjs-best-practices/rsc-boundaries.md](./references/nextjs-best-practices/rsc-boundaries.md) |
| Async `params`, `searchParams`, `cookies()`, `headers()`, migration codemod | [references/nextjs-best-practices/async-patterns.md](./references/nextjs-best-practices/async-patterns.md) |
| Node vs Edge runtime selection | [references/nextjs-best-practices/runtime-selection.md](./references/nextjs-best-practices/runtime-selection.md) |
| `'use client'`, `'use server'`, `'use cache'` directives | [references/nextjs-best-practices/directives.md](./references/nextjs-best-practices/directives.md) |
| Navigation hooks, server functions, `generateStaticParams`, `generateMetadata` | [references/nextjs-best-practices/functions.md](./references/nextjs-best-practices/functions.md) |
| `error.tsx`, `global-error.tsx`, `not-found.tsx`, `redirect`, `forbidden`, `unauthorized`, `unstable_rethrow` | [references/nextjs-best-practices/error-handling.md](./references/nextjs-best-practices/error-handling.md) |
| Server Components vs Server Actions vs Route Handlers, avoiding waterfalls, preload, client fetching | [references/nextjs-best-practices/data-patterns.md](./references/nextjs-best-practices/data-patterns.md) |
| `route.ts` basics, GET conflicts with `page.tsx`, when to pick over Server Actions | [references/nextjs-best-practices/route-handlers.md](./references/nextjs-best-practices/route-handlers.md) |
| Static and dynamic metadata, `generateMetadata`, OG images with `next/og`, file-based metadata | [references/nextjs-best-practices/metadata.md](./references/nextjs-best-practices/metadata.md) |
| `next/image`, remote images, responsive sizes, blur placeholders, LCP priority | [references/nextjs-best-practices/image.md](./references/nextjs-best-practices/image.md) |
| `next/font` setup, Google/local fonts, Tailwind integration, subset preloading | [references/nextjs-best-practices/font.md](./references/nextjs-best-practices/font.md) |
| Server-incompatible packages, CSS imports, polyfills, ESM/CJS issues, bundle analysis | [references/nextjs-best-practices/bundling.md](./references/nextjs-best-practices/bundling.md) |
| `next/script` vs raw script tags, inline script `id`, loading strategies, `@next/third-parties` | [references/nextjs-best-practices/scripts.md](./references/nextjs-best-practices/scripts.md) |
| Hydration error debugging | [references/nextjs-best-practices/hydration-error.md](./references/nextjs-best-practices/hydration-error.md) |
| `useSearchParams`/`usePathname` Suspense bailout | [references/nextjs-best-practices/suspense-boundaries.md](./references/nextjs-best-practices/suspense-boundaries.md) |
| Modal patterns with `@slot` and `(.)` interceptors, `default.tsx`, `router.back()` | [references/nextjs-best-practices/parallel-routes.md](./references/nextjs-best-practices/parallel-routes.md) |
| `output: 'standalone'`, Docker, multi-instance ISR cache handlers | [references/nextjs-best-practices/self-hosting.md](./references/nextjs-best-practices/self-hosting.md) |
| MCP debug endpoint, `--debug-build-paths` | [references/nextjs-best-practices/debug-tricks.md](./references/nextjs-best-practices/debug-tricks.md) |

## Do not use this skill when

- The task is plain TypeScript with no Next.js surface — use `typescript-coding` (see the `coding` parent skill).
- The task is React primitives without App Router concerns — use `react-guidelines` and apply this skill on top.
- The repo is legacy Pages Router only and migration is out of scope.
- The task is mainly toolchain, editor, or CI setup.
