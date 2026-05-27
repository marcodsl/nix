---
name: workos
description: "Route WorkOS implementation, debugging, migration, and docs-lookup tasks to the correct reference file before answering. Triggers: WorkOS docs URLs, terms, or dashboard fields (Sign-in endpoint, `initiate_login_uri`, Redirect URI, `WORKOS_*` env vars), AuthKit (Next.js/React/React Router/TanStack Start/SvelteKit/vanilla JS) and backend SDKs (Node/Python/Go/Ruby/PHP/Laravel/.NET/Kotlin/Elixir), SSO/SAML, Directory Sync/SCIM, RBAC, FGA, MFA, Vault, Audit Logs, Admin Portal, Pipes (Connected Apps), Feature Flags, Radar (bot/fraud), webhooks, Custom Domains, migration from Auth0/Clerk/Cognito/Firebase/Supabase/Stytch/Descope/Better Auth, `@workos-inc/*` imports, `workos` CLI. Skip when: the task is generic auth design unrelated to WorkOS."
license: MIT
metadata:
  author: workos
  source: https://github.com/workos/skills/tree/main/plugins/workos/skills/workos
  tags: workos, authkit, sso, saml, scim, directory-sync, rbac, fga, mfa, vault, audit-logs, admin-portal, webhooks, auth-migration
  version: 3
---

# WorkOS Skill Router

<purpose>
This file is a router, not the answer. Match the request to a reference file using the decision tree, Read that reference with the Read tool, and follow its instructions before producing any answer, URL, or code.
</purpose>

<scope>
  <use_when>
  - The user asks for a WorkOS docs URL, term, or dashboard field.
  - The user is implementing, debugging, or migrating WorkOS (AuthKit, SSO/SAML, Directory Sync, RBAC, FGA, MFA, Vault, Audit Logs, Admin Portal, Pipes, Feature Flags, Radar, webhooks, Custom Domains).
  - Imports from `@workos-inc/*` appear in the code.
  </use_when>

  <do_not_use_when>
  - The task is generic auth design unrelated to WorkOS.
  </do_not_use_when>
</scope>

<governing_rule>
You must Read the matched reference file before answering. If you have not Read a reference, you have not followed this skill. The reference will tell you which live docs to fetch with WebFetch and which gotchas to avoid.
</governing_rule>

<section name="guardrails">
These apply to every response. The most common failure mode is plausibly-shaped fabrication of CLI commands and Dashboard paths.

- Never invent `workos` CLI commands. The authoritative source is `workos --help --json`. Verify the command tree before suggesting a command. See `references/workos-management.md`.
- Never invent Dashboard click-paths. Phrases like "Dashboard > Organizations > X > Roles" or `dashboard.workos.com/some/specific/path` should not appear unless verified against a docs page you just fetched. Cite the docs URL and describe the destination conceptually instead.
- When the user wants something not in the CLI, say so plainly. See the "Not in the CLI" section of `references/workos-management.md`.
- Prefer docs URLs over prose when writing recipes. Cite literally; do not paraphrase URL slugs.
</section>

<section name="decision-tree">
Apply these rules in order. First match wins.

Rule 0 — Terminology / Docs URL Lookup:
- Triggers: lookup-shaped phrasing ("what is X", "docs URL for X", "where's the docs on X", "where do I configure X in the dashboard") where X is a WorkOS config field, endpoint, env var, or term.
- Do NOT fire for setup-shaped phrasing ("set up Vault", "enable Admin Portal", "configure MFA") — those go to Rule 3.
- Action: Read `references/workos-terms.md`. If the term is in the table, answer with the summary; WebFetch the listed URL only on request. If not in the table, follow the "Still not here?" fallback at the bottom of that file.
- For terminology lookups, do NOT WebFetch `llms.txt` or guess `workos.com/docs/...` URLs before reading the terms file.

Rule 1 — Migration Context:
- Triggers: user mentions migrating FROM another provider (Auth0, Clerk, Cognito, Firebase, Supabase, Stytch, Descope, Better Auth, standalone SSO API).
- Action: Read `references/workos-migrate-[provider].md`. If the provider is not in the table, read `references/workos-migrate-other-services.md`.

Rule 2 — API Reference Request:
- Triggers: user explicitly asks about API endpoints, request format, response schema, API reference, or inspecting HTTP details.
- Action: For features with topic files, read the feature topic file (it includes an endpoint table). For AuthKit or Organization APIs, read `references/workos-api-[domain].md`.

Rule 3 — Feature-Specific Request:
- Triggers: user names a feature (SSO, MFA, Directory Sync, Audit Logs, Vault, RBAC, FGA, Admin Portal, Custom Domains, Events, Integrations, Email, Pipes, Feature Flags, Radar).
- Action: Read `references/workos-[feature].md` where `[feature]` is the slug (`sso`, `mfa`, `directory-sync`, `audit-logs`, `vault`, `rbac`, `fga`, `admin-portal`, `custom-domains`, `events`, `integrations`, `email`, `pipes`, `feature-flags`, `radar`).
- Widget requests → load `workos-widgets` skill via the Skill tool.
- Feature + API → route to the feature topic file (endpoints included). Multiple features → route to the most specific first. FGA ≠ RBAC: FGA is resource-scoped on top of RBAC.
- IdP group → role mapping (Entra / Azure AD / Okta / Google Workspace / SCIM / directory / SSO groups): read BOTH `workos-rbac.md` AND the source-specific reference (`workos-directory-sync.md` for SCIM/Google groups; `workos-sso.md` for SSO-only groups). This is not a CLI operation.

Rule 4 — AuthKit Installation:
- Triggers: authentication setup, login flow, sign-up, session management, or "AuthKit" without a specific feature like SSO or MFA.
- Action: detect the framework or language using the priority order below, then Read the corresponding reference file.
- Routing exceptions: "SSO login via AuthKit" → Rule 3 (SSO). "React login with Google" → Rule 4 (AuthKit React). Adding a feature to an existing AuthKit app → Rule 3.

Rule 5 — Integration Setup:
- Triggers: connecting to external IdPs, configuring third-party integrations, "how do I integrate with [provider]".
- Action: Read `references/workos-integrations.md`. Provider + feature ("Set up Okta SSO") → Rule 3.

Rule 6 — Management / CLI Operations:
- Triggers: managing resources (orgs, users, roles, permissions), seeding data, CLI commands.
- Action: Read `references/workos-management.md`. CLI upgrade ("outdated workos CLI", "unknown command") → Read `references/workos-cli-upgrade.md`. Do NOT guess the latest version.

Rule 7 — Vague or General Request:
- Triggers: "help with WorkOS", "WorkOS setup", "what can WorkOS do", or no feature context.
- Action: WebFetch https://workos.com/docs/llms.txt, scan the index for the best matching section, WebFetch the section URL, summarize capabilities, ASK the user what they want. Do not guess a feature.

Rule 8 — No Match / Ambiguous:
- Action: WebFetch https://workos.com/docs/llms.txt, search the index, WebFetch the matching section. If no match, ask: "I couldn't find a WorkOS feature matching '[term]'. Could you clarify? For example: authentication, SSO, MFA, directory sync, audit logs."
</section>

<section name="framework-detection">
Apply for AuthKit (Rule 4) in this exact order. First match wins:

Frontend:
1. `@tanstack/start` in `package.json` deps → `references/workos-authkit-tanstack-start.md`.
2. `@sveltejs/kit` in `package.json` deps → `references/workos-authkit-sveltekit.md`.
3. `react-router` or `react-router-dom` in deps → `references/workos-authkit-react-router.md`.
4. `next.config.{js,mjs,ts}` exists at root → `references/workos-authkit-nextjs.md`.
5. (`vite.config.{js,ts}` exists) AND `react` in deps → `references/workos-authkit-react.md`.
6. None of the above → `references/workos-authkit-vanilla-js.md`.

Backend (when no frontend framework is detected):
1. `pyproject.toml` / `requirements.txt` / `setup.py` → `references/workos-python.md`.
2. `go.mod` → `references/workos-go.md`.
3. `Gemfile` or `config/routes.rb` → `references/workos-ruby.md`.
4. `composer.json` with `laravel/framework` → `references/workos-php-laravel.md`.
5. `composer.json` (without Laravel) → `references/workos-php.md`.
6. `*.csproj` / `*.sln` → `references/workos-dotnet.md`.
7. `build.gradle{.kts}` → `references/workos-kotlin.md`.
8. `mix.exs` → `references/workos-elixir.md`.
9. `package.json` with `express` / `fastify` / `hono` / `koa` → `references/workos-node.md`.

Edge cases:
- Multiple frameworks (e.g., Next.js + TanStack): ask the user which to use. Do not guess.
- Framework unclear and files not inspectable: ask "Which framework/language?" Do not default without confirmation.
</section>

<section name="reference-map">
AuthKit installation:
- Next.js → `references/workos-authkit-nextjs.md`
- React SPA → `references/workos-authkit-react.md`
- React Router → `references/workos-authkit-react-router.md`
- TanStack Start → `references/workos-authkit-tanstack-start.md`
- SvelteKit → `references/workos-authkit-sveltekit.md`
- Vanilla JS → `references/workos-authkit-vanilla-js.md`
- Architecture → `references/workos-authkit-base.md`
- Widgets → load `workos-widgets` via Skill tool.

Backend SDKs:
- Node.js → `references/workos-node.md`
- Python → `references/workos-python.md`
- .NET → `references/workos-dotnet.md`
- Go → `references/workos-go.md`
- Ruby → `references/workos-ruby.md`
- PHP → `references/workos-php.md`
- PHP Laravel → `references/workos-php-laravel.md`
- Kotlin → `references/workos-kotlin.md`
- Elixir → `references/workos-elixir.md`

Features:
- SSO → `references/workos-sso.md`
- Directory Sync → `references/workos-directory-sync.md`
- RBAC → `references/workos-rbac.md`
- Vault → `references/workos-vault.md`
- Events / webhooks → `references/workos-events.md`
- Audit Logs → `references/workos-audit-logs.md`
- Admin Portal → `references/workos-admin-portal.md`
- MFA → `references/workos-mfa.md`
- Email → `references/workos-email.md`
- Custom Domains → `references/workos-custom-domains.md`
- Integrations → `references/workos-integrations.md`
- FGA → `references/workos-fga.md`
- Pipes / Connected Apps → `references/workos-pipes.md`
- Feature Flags → `references/workos-feature-flags.md`
- Radar → `references/workos-radar.md`

API references (when no feature topic exists):
- AuthKit API → `references/workos-api-authkit.md`
- Organization API → `references/workos-api-organization.md`

Migrations:
- Auth0 → `references/workos-migrate-auth0.md`
- AWS Cognito → `references/workos-migrate-aws-cognito.md`
- Better Auth → `references/workos-migrate-better-auth.md`
- Clerk → `references/workos-migrate-clerk.md`
- Descope → `references/workos-migrate-descope.md`
- Firebase → `references/workos-migrate-firebase.md`
- Stytch → `references/workos-migrate-stytch.md`
- Supabase Auth → `references/workos-migrate-supabase-auth.md`
- Standalone SSO API → `references/workos-migrate-the-standalone-sso-api.md`
- Other services → `references/workos-migrate-other-services.md`

Management & CLI:
- Resource CLI commands → `references/workos-management.md`
- CLI upgrade → `references/workos-cli-upgrade.md`
</section>
