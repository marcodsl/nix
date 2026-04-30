# Copilot instruction index

Use this as the first layer of local Copilot guidance. Follow these rules before consulting referenced files.

## Session start checklist

Before the first substantive tool call in a session, and again after `/clear` or `/compact`:

1. Call `search_nodes` on the `memory` MCP server with request terms such as user handle, project, repo, language, and topic.
2. Scan the skill routing list and load the narrowest matching skill before planning or editing.

Skip only for purely mechanical requests such as raw command execution, echo-style replies, arithmetic, or one-line lookups.

## Local skill routing

Use a local skill under `$HOME/.copilot/skills` when the request matches it:

- `brainstorming`: ideation, alternatives, option-space expansion before design/planning.
- `coding-guidelines`: architecture, design, reviews, refactor strategy, implementation tradeoffs, major technical decisions.
- `context-map`: map files, dependencies, tests, references, ownership, scope, or blast radius before implementation.
- `conventional-commits`: inspect diffs, choose commit type/scope, draft or create Conventional Commits.
- `dockerfile`: create/review Dockerfiles, multi-stage builds, cache layers, base images, hardening, image size.
- `google-aip-adoption`: resource models, standard/custom methods, field behavior, compatibility, versioning, AIP exceptions.
- `natural-tone`: docs, READMEs, technical notes, commit/PR prose, vague or formulaic text cleanup.
- `nextjs-guidelines`: Next.js 16+ App Router, Server Components/Actions, Cache Components, PPR, routing, middleware, error boundaries.
- `pressure-test`: challenge a proposal or design through focused assumption/tradeoff review.
- `prompt-engineering`: system prompts, agent rules, instruction files, `SKILL.md`, `.agent.md`, `.prompt.md`, `.mdc`, coding-agent config.
- `python-coding`: Python writing/review/refactor with `uv`, `ruff`, `mypy`, `pytest`.
- `react-guidelines`: React 19+ components/hooks, server/client boundaries, compiler, Actions, Suspense, component tests.
- `refactor-planning`: concrete refactor plans, RFC-style decisions, small safe commit breakdowns.
- `rules-distill`: extract cross-cutting rules from multiple skills or promote repeated guidance.
- `rust-coding`: Rust writing/review/refactor with `cargo` and Clippy.
- `typescript-coding`: TypeScript writing/review/refactor with `tsc`, ESLint, Prettier, Vitest.

## Disambiguation

- Prefer the narrowest matching skill.
- Repository-local policy beats language/framework defaults unless the task is to change that policy.
- Use `coding-guidelines` for cross-cutting architecture/review decisions.
- Use language/framework skills for implementation details.
- Use `prompt-engineering` for agent behavior and prompt structure; `natural-tone` only for prose cleanup.

## Context-mode routing

Use context-mode MCP tools when they reduce raw context:

- `ctx_batch_execute(commands, queries)`: initial repo surveys, multi-file exploration, or gathering several command/search answers together.
- `ctx_execute(language, code)`: analyze, count, filter, parse, transform, compare, or summarize data; especially structured output or command output likely over ~20 lines.
- `ctx_execute_file(path, language, code)`: inspect or summarize file contents for analysis. Use direct reads only when file text must be in context to edit.
- `ctx_fetch_and_index(url, source)` then `ctx_search(queries)`: web content. Do not use terminal HTTP helpers for this.
- `ctx_search(queries)`: follow-up questions over already-indexed content; batch related questions.

Detailed context-mode workflow lives at `$HOME/.copilot/instructions/context-mode.md`.

## Memory server routing

Use the `memory` MCP server for cross-session context.

At session start, call `search_nodes` with terms from the request before planning or editing any substantive task. Use `open_nodes` when the entity is known and `read_graph` only for broad inspection.

Before the final reply, write durable signals when they would improve future work:

- Stable user preference -> add observations on the user entity, creating it if needed.
- Repo convention such as build/test/lint command, layout, or naming rule -> add observations on the repository entity.
- New recurring entity such as collaborator, team, service, dependency, repo, or significant tool -> create entity and relations.
- Durable relationship such as user works on repo, repo uses service, team owns subsystem -> create active-voice relations.
- Long-lived goal or constraint -> add observations on the relevant entity.

Do not store secrets, credentials, tokens, one-off state, scratch notes, or volatile facts. Write only when future retrieval would improve the work.

For full memory vocabulary and correction rules, see `$HOME/.copilot/instructions/memory-server.md`.
