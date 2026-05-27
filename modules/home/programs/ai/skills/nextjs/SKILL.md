---
name: nextjs
description: "Write and review Next.js 16+ App Router code with strict verification and idiomatic design, plus the Vercel-Labs Next.js best-practices reference (auto-applied alongside the guidelines). Triggers: `app/` directory, `'use client'`/`'use server'`/`'use cache'`, Server Components, Server Actions, Route Handlers (`route.ts`), Cache Components, PPR, `typedRoutes`, middleware → proxy rename, `error.tsx`/`not-found.tsx`/`global-error.tsx`, async `params`/`searchParams`/`cookies()`/`headers()`, `next/image`, `next/font`, `next/og`, hydration errors, Suspense bailouts, parallel and intercepting routes (`@slot`, `(.)`), `output: 'standalone'`, Vitest, Playwright. Skip when: legacy Pages Router only with no migration, or plain TypeScript/React without App Router."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: nextjs, app-router, rsc, server-components, server-actions, cache-components, ppr, data-fetching, metadata, hydration, suspense, vitest, playwright
  version: 3
---

# Next.js

<purpose>
Umbrella skill for Next.js 16+ App Router work. Two reference layers stack: opinionated guidelines for writing and reviewing code, plus the Vercel-Labs best-practices catalog for canonical patterns.
</purpose>

<scope>
  <use_when>
  - Writing or reviewing App Router code: Server Components, Server Actions, Route Handlers, Cache Components, PPR, typed routes, middleware/proxy, file conventions.
  - Debugging hydration, Suspense bailout, parallel/intercepting routes.
  - Configuring image, font, metadata, OG images, bundling, scripts.
  - Self-hosting with `output: 'standalone'`, multi-instance ISR.
  </use_when>

  <do_not_use_when>
  - Plain TypeScript with no Next.js surface.
  - React primitives without App Router concerns.
  - The repo is legacy Pages Router only and migration is out of scope.
  - The task is mainly toolchain, editor, or CI setup.
  </do_not_use_when>
</scope>

<governing_rule>
Two layers stack: `references/nextjs-guidelines.md` is the opinionated rule set for authoring and reviewing code. `references/nextjs-best-practices/` is the canonical pattern reference, always available. Consult both; cite the specific file when applying a rule.
</governing_rule>

<section name="routing">
For opinionated authoring/review (caching, Server Action design, typed routes, error boundaries, Vitest/Playwright placement, verification checklist) → `references/nextjs-guidelines.md`.

For canonical Vercel-Labs patterns, pick the topic:
- File conventions, route segments, `(.)` interceptors, parallel routes, middleware → proxy rename → `references/nextjs-best-practices/file-conventions.md`
- RSC boundaries, async client component traps, non-serializable props, Server Action exceptions → `references/nextjs-best-practices/rsc-boundaries.md`
- Async `params`, `searchParams`, `cookies()`, `headers()`, migration codemod → `references/nextjs-best-practices/async-patterns.md`
- Node vs Edge runtime selection → `references/nextjs-best-practices/runtime-selection.md`
- `'use client'`, `'use server'`, `'use cache'` directives → `references/nextjs-best-practices/directives.md`
- Navigation hooks, server functions, `generateStaticParams`, `generateMetadata` → `references/nextjs-best-practices/functions.md`
- `error.tsx`, `global-error.tsx`, `not-found.tsx`, `redirect`, `forbidden`, `unauthorized`, `unstable_rethrow` → `references/nextjs-best-practices/error-handling.md`
- Server Components vs Server Actions vs Route Handlers, avoiding waterfalls, preload, client fetching → `references/nextjs-best-practices/data-patterns.md`
- `route.ts` basics, GET conflicts with `page.tsx`, picking over Server Actions → `references/nextjs-best-practices/route-handlers.md`
- Static and dynamic metadata, `generateMetadata`, OG images with `next/og`, file-based metadata → `references/nextjs-best-practices/metadata.md`
- `next/image`, remote images, responsive sizes, blur placeholders, LCP priority → `references/nextjs-best-practices/image.md`
- `next/font` setup, Google/local fonts, Tailwind integration, subset preloading → `references/nextjs-best-practices/font.md`
- Server-incompatible packages, CSS imports, polyfills, ESM/CJS, bundle analysis → `references/nextjs-best-practices/bundling.md`
- `next/script` vs raw script tags, inline script `id`, loading strategies, `@next/third-parties` → `references/nextjs-best-practices/scripts.md`
- Hydration error debugging → `references/nextjs-best-practices/hydration-error.md`
- `useSearchParams`/`usePathname` Suspense bailout → `references/nextjs-best-practices/suspense-boundaries.md`
- Modal patterns with `@slot` and `(.)` interceptors, `default.tsx`, `router.back()` → `references/nextjs-best-practices/parallel-routes.md`
- `output: 'standalone'`, Docker, multi-instance ISR cache handlers → `references/nextjs-best-practices/self-hosting.md`
- MCP debug endpoint, `--debug-build-paths` → `references/nextjs-best-practices/debug-tricks.md`
</section>
