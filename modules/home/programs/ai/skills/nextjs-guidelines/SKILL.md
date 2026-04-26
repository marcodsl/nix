---
name: nextjs-guidelines
description: "Write and review Next.js 16+ App Router code with strict verification and idiomatic design. Use when: writing or reviewing Server Components, Server Actions, Route Handlers, Cache Components (use cache), PPR, typedRoutes, middleware, error.tsx, and route-level patterns with Vitest and Playwright."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [nextjs, app-router, cache-components, server-actions, ppr, vitest, playwright]
---

# Next.js Guidelines

Rules for writing and reviewing Next.js 16+ App Router code with strict verification, explicit caching boundaries, and idiomatic route and action design.

## Purpose

Use this skill to write, review, or refactor Next.js App Router applications with correctness-first defaults. Prefer designs that keep Server Components the default, opt into caching explicitly with `"use cache"`, isolate dynamic content behind `<Suspense>`, and validate every boundary.

## Scope

### Use this skill when

- Writing or reviewing Next.js 16+ App Router pages, layouts, route handlers, Server Actions, middleware, or metadata.
- Choosing between Server Components, Client Components, Route Handlers, and Server Actions for a given surface.
- Deciding how to cache, revalidate, and invalidate data with Cache Components, `cacheLife`, `cacheTag`, `updateTag`, and `revalidateTag`.
- Tightening rendering strategy (PPR, streaming, Suspense boundaries), routing hygiene (`typedRoutes`), or validation posture.

### Do not use this skill when

- The task is about plain TypeScript with no Next.js surface. Prefer `typescript-coding`.
- The task is about React primitives (hooks, composition, compiler) without App Router specifics. Prefer `react-guidelines` and apply this skill on top.
- The repository uses the legacy Pages Router exclusively and migration is explicitly out of scope.
- The task is mainly installing toolchains, configuring editors, or setting up CI.

## Governing rule

App Router first, Server Components by default, `"use cache"` where caching is intentional, `'use client'` at the leaves, and validated inputs at every boundary. Cache what is stable, stream what is dynamic, and never hide dynamic data inside a cached scope.

## Verification defaults

Treat Next.js work as incomplete until the relevant checks pass. Default to the broadest relevant scope for the repository shape in front of you. Run every tool through the project's package manager.

Prefer Bun for greenfield projects (`bun install`, `bun run <script>`, `bunx`). On brownfield, use the project's existing manager (`pnpm`, `npm`, `yarn`); Bun monorepos currently have rough edges with Next.js, so honor the project's lockfile. Never mix managers.

1. **Type-check**: inherit the `typescript-coding` defaults (`bun run tsc --noEmit` or `tsc -b`). Enable `typedRoutes` so `<Link href>` and `router.push` become compile-time checks.
2. **Lint**: default to `bun run next lint` (or `bun run eslint .` with `eslint-config-next`). Keep `@next/next/core-web-vitals` on.
3. **Build**: default to `bun run next build`. The build catches invalid server/client boundary crossings, unused route segments, and dynamic APIs called under `"use cache"` that the linter cannot.
4. **Unit and component tests**: default to `bun run vitest run`. Inherit test placement and Testing Library guidance from `react-guidelines`.
5. **End-to-end**: default to `bun run playwright test` against `next start` (production) or `next dev` (development). Reserve E2E for flows that exercise routing, caching, Server Actions, or middleware.
6. **Reproducibility**: in CI, install with `--frozen-lockfile` (or `npm ci` / `yarn install --immutable`) and build against a pinned Node version that matches the Next.js support matrix.

## Test placement and organization

- Co-locate component tests next to source (see `react-guidelines`). Keep route-level integration under `tests/` or the `app/` route segment's `_tests/` folder.
- Mock `next/navigation` (`useRouter`, `usePathname`, `useSearchParams`), `next/headers` (`cookies`, `headers`, `draftMode`), and any server-only modules in Vitest via `vi.mock`. Keep the mocks in a shared test setup file.
- Assert Server Component behavior by rendering the exported function and snapshotting the returned JSX tree, or by letting Playwright assert against the rendered HTML.
- Drive Server Action flows in Playwright: fill the form, submit, and assert both the server state (via a follow-up fetch or database check) and the UI update.
- Exercise middleware and route handlers with end-to-end requests rather than unit mocks; both rely on runtime primitives that are hard to fake faithfully.
- If a repository defines narrower file-pattern or test-placement rules, apply them in addition to this skill rather than replacing the skill's general guidance.

## Strictness defaults

Use these settings by default unless the project has a documented reason to differ.

### `next.config.ts`

```ts
import type { NextConfig } from 'next'

const config: NextConfig = {
  cacheComponents: true,
  typedRoutes: true,
  reactCompiler: true,
  experimental: {
    ppr: 'incremental',
  },
}

export default config
```

- `cacheComponents: true` turns on the opt-in `"use cache"` model and makes PPR the default rendering strategy.
- `typedRoutes: true` gives `<Link href>` and typed `useRouter().push` routing safety.
- `reactCompiler: true` enables the React Compiler so manual memoization is unnecessary.
- `experimental.ppr: 'incremental'` lets routes opt into PPR one at a time during migration.

### Validated environment

Load and validate environment variables once, in a single `env.ts`, and import the parsed shape everywhere else. Do not read `process.env` in route code.

```ts
import { z } from 'zod'

const schema = z.object({
  DATABASE_URL: z.string().url(),
  STRIPE_SECRET_KEY: z.string().min(1),
  NEXT_PUBLIC_SITE_URL: z.string().url(),
})

export const env = schema.parse(process.env)
```

### ESLint additions

Keep `eslint-config-next` on and layer it on top of the TypeScript and React flat configs from `typescript-coding` and `react-guidelines`. Treat the `@next/next/no-html-link-for-pages`, `@next/next/no-img-element`, and `@next/next/no-sync-scripts` rules as errors.

## Error handling

- Put an `error.tsx` boundary at every route segment that can fail independently. Leaf boundaries give tighter fallbacks; layout-level boundaries catch cross-segment crashes. Only Client Components work as `error.tsx`; mark the file `'use client'`.
- Put `not-found.tsx` at segments that call `notFound()` so 404 paths render the right shell.
- In Server Components, throw `notFound()`, `forbidden()`, or `unauthorized()` from `next/navigation` rather than returning custom status strings. Next.js renders the matching `not-found.tsx`, `forbidden.tsx`, or `unauthorized.tsx`.
- In Server Actions, return a typed discriminated union rather than throwing across the client boundary. The client reads the result with `useActionState` and renders the error surface.

```ts
'use server'

import { z } from 'zod'

const schema = z.object({ email: z.string().email() })

type SubscribeResult =
  | { success: true; email: string }
  | { success: false; errors: Record<string, string> }

export async function subscribe(
  _prev: SubscribeResult | null,
  formData: FormData,
): Promise<SubscribeResult> {
  const parsed = schema.safeParse({ email: formData.get('email') })
  if (!parsed.success) {
    return { success: false, errors: parsed.error.flatten().fieldErrors }
  }
  try {
    await mailer.add(parsed.data.email)
    return { success: true, email: parsed.data.email }
  } catch (err) {
    logger.error('subscribe failed', { cause: err })
    return { success: false, errors: { email: 'could not subscribe' } }
  }
}
```

- In Route Handlers, return `NextResponse.json(body, { status })` with an explicit status code. Do not throw; catch and map to a typed error response.
- Validate every request body, search param, and form field at the boundary with a schema library. Untrusted input never reaches service code as `unknown`.

## Type and API design

### Page and layout signatures

In Next.js 16 the `params` and `searchParams` props are promises. Always `await` them and type the promise shape explicitly.

```tsx
type PageProps = {
  params: Promise<{ slug: string }>
  searchParams: Promise<Record<string, string | string[] | undefined>>
}

export default async function Page({ params, searchParams }: PageProps) {
  const { slug } = await params
  const { ref } = await searchParams
  return <Article slug={slug} referrer={ref} />
}
```

### Route Handlers

Type request and response with schemas. Return `NextResponse.json` with an explicit status. Use Route Handlers for external API consumers, webhooks, and anything that cannot be expressed as a Server Action.

```ts
import { NextResponse } from 'next/server'
import { z } from 'zod'

const schema = z.object({ id: z.string().uuid() })

export async function POST(request: Request) {
  const parsed = schema.safeParse(await request.json())
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 })
  }
  const result = await service.enqueue(parsed.data.id)
  return NextResponse.json(result, { status: 202 })
}
```

### Server Actions

Server Actions are thin orchestrators. Extract domain logic into colocated services (`_lib/*.service.ts`) so the action stays small, testable, and reusable from Route Handlers or background jobs. Keep mutations idempotent where possible and always redirect or revalidate on success.

### Typed routes

With `typedRoutes: true`, use the `Route` helper from `next` when you need to pass a route through a generic boundary. Never hand-assemble route strings in call sites.

```tsx
import type { Route } from 'next'

type NavItemProps = { href: Route; label: string }
```

### Metadata

Prefer the `generateMetadata` export for dynamic metadata so Next.js can stream it. Keep static metadata as a plain exported `metadata` object.

## Idiomatic Next.js defaults

- Server Components by default. Use Client Components (with `'use client'`) only for interactivity, browser APIs, or React hooks that do not run on the server. Push the boundary as deep as possible.
- Cache explicitly with `"use cache"` on async functions or components. Arguments and closed-over values automatically become part of the cache key, so keep inputs small and serializable.
- Tune revalidation with `cacheLife('minutes' | 'hours' | 'days' | 'weeks' | 'max')`. Default to the shortest window that meets the product requirement; escalate only when the data is genuinely stable.
- Invalidate with `cacheTag(tag)` on the cached function, then `updateTag(tag)` inside a Server Action for read-your-writes, or `revalidateTag(tag)` for stale-while-revalidate. Reach for `revalidatePath` only when tag-based invalidation cannot express the change.
- Call `connection()` from `next/server` before any non-deterministic value (`Date.now`, `Math.random`, crypto IDs, cookies, headers) and wrap the consuming subtree in `<Suspense>`. This lets PPR prerender the static shell while the dynamic slot streams in at request time.
- Use Suspense boundaries to isolate dynamic content. Fallbacks should match the final layout to keep CLS low.
- Colocate private files inside a route segment with the `_` prefix: `_lib/`, `_components/`, `_actions/`, `_services/`. Files and folders that start with `_` are never treated as routable segments.
- Use Parallel Routes (`@slot`) and Intercepting Routes (`(.)`, `(..)`, `(...)`) for modal and drawer patterns instead of hand-rolling client-side modal state on top of global URL state.
- Use Server Actions for form mutations that originate in your own UI. Use Route Handlers for external API consumers, webhooks, and streaming responses.
- Keep middleware thin. Use it for auth gating, redirects, A/B bucket assignment, and header rewrites. Put business logic in Server Actions or services. Run middleware on the Edge runtime unless Node-only APIs force otherwise.
- Use `<Link>` for internal navigation, `<Image>` with explicit `width`/`height` and `priority` on the LCP image, `next/font` for font loading, and the Metadata API for `<head>` content. Do not bypass these primitives.
- Gate incremental PPR rollout with `experimental.ppr: 'incremental'` plus `export const experimental_ppr = true` on individual route segments. Do not flip the repo to `ppr: true` everywhere in one commit.
- Prefer Cache Components + tag invalidation over `fetch(..., { next: { revalidate } })` knobs once Cache Components are enabled. Mixing the two caches on the same surface is confusing.

## Patterns to correct

- Replace `getServerSideProps` and `getStaticProps` with Server Component fetches in the App Router.
- Move `'use client'` from whole pages or layouts down to the smallest interactive leaf; fetch data in the Server Component parent.
- Replace `<a href>` for internal routes with `<Link>`. Replace `<img>` with `<Image>` and provide explicit width, height, and `priority` where it matters for LCP.
- Replace hand-assembled route strings with typed `Route` helpers under `typedRoutes: true`.
- Replace inline `Math.random()`, `Date.now()`, or crypto ID usage under `"use cache"` with a `connection()` boundary plus `<Suspense>` so the static shell can still prerender.
- Replace broad `revalidatePath('/some/path')` invalidations with `cacheTag` + `updateTag` / `revalidateTag` when the cache is tag-keyed.
- Replace `useEffect`-based client-side data fetching in route components with a Server Component fetch + `<Suspense>` or a dedicated data library if client-side interactivity is genuinely required.
- Replace ad-hoc modals managed with global state with Intercepting + Parallel Routes where the modal maps to a URL state.
- Replace `process.env` reads scattered through the code with a validated `env.ts` module imported at use sites.
- Replace thrown exceptions that cross the server/client boundary in Server Actions with a typed `{ success, data } | { success: false, errors }` result.
- Replace `error.tsx` files that forget `'use client'` (they silently fail to render) with a proper Client Component boundary.
- Replace fetches in Client Components that could run on the server with a Server Component fetch plus props; reserve client fetching for interactivity-driven data (polling, optimistic UI, websocket-backed views).

## Verification checklist

- [ ] Ran type-check, lint, build, Vitest, and Playwright at the broadest relevant scope before considering the work complete.
- [ ] Kept `cacheComponents`, `typedRoutes`, and `reactCompiler` on, and enabled `experimental.ppr: 'incremental'` during migration.
- [ ] Awaited `params` and `searchParams` promises, typed them explicitly, and used typed `Route` helpers instead of string-concatenated hrefs.
- [ ] Added `error.tsx` (as Client Components) and `not-found.tsx` at the right segments; used `notFound()`, `forbidden()`, `unauthorized()` in Server Components.
- [ ] Scoped `"use cache"` to async functions and components with small serializable inputs, tuned revalidation with `cacheLife`, and invalidated with `cacheTag` + `updateTag` / `revalidateTag`.
- [ ] Placed `connection()` + `<Suspense>` around non-deterministic reads so PPR can prerender the static shell.
- [ ] Kept Server Actions as thin orchestrators over colocated `_lib` services, validated input with a schema, and returned typed result unions rather than throwing across the client boundary.
- [ ] Used `<Link>`, `<Image>`, `next/font`, and the Metadata API instead of bypassing the Next.js primitives.
