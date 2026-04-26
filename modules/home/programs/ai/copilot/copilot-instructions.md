# Copilot instruction index

Use this file as the first layer of local Copilot guidance. Follow the main rules here before consulting referenced files.

## Session start checklist

Run these two actions before the first substantive tool call in any session, and again after `/clear` or `/compact`:

1. Call `search_nodes` on the `memory` MCP server with terms drawn from the request (user handle, project, repository, language, topic) to surface stored preferences, conventions, and recurring entities.
2. Scan the skill routing table below and load the narrowest matching skill before planning or editing.

These two steps prime memory capture and context-mode usage for the rest of the session.

## Local skill routing rules

Apply when any request could match a local skill under `$HOME/.copilot/skills`. Check the routing table before starting work and invoke the matching skill instead of re-deriving its workflow.

| Skill                  | Use when                                                                                                                                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `brainstorming`        | Brainstorming, ideation, exploring alternatives, or widening the option space before design or planning.                                                                                                                                                                              |
| `coding-guidelines`    | Shaping designs, reviewing code or PRs, planning refactors, evaluating implementation strategies, or making major technical decisions.                                                                                                                                                |
| `context-map`          | Creating a reviewable map of the files, dependencies, tests, and reference patterns that matter to a task before implementation. Use when: scoping a change, locating the owning code path, estimating blast radius, or proving the edit surface is understood.                       |
| `conventional-commits` | Generating or executing commit messages that conform to Conventional Commits 1.0.0. Use when: inspecting a diff, choosing a commit type or scope, drafting a commit subject, body, or footer, or creating a git commit from the current changes.                                      |
| `dockerfile`           | Writing and reviewing Dockerfiles with multi-stage builds, reproducible base images, cache-efficient layers, and container hardening. Use when: creating or reviewing Dockerfiles, shrinking images, improving build caching, choosing base images, or tightening container security. |
| `google-aip-adoption`  | Shaping resource models, choosing standard vs custom methods, defining field behavior, planning compatibility or versioning, or documenting AIP exceptions.                                                                                                                           |
| `natural-tone`         | Editing docs, READMEs, technical notes, commit messages, PR descriptions, or tightening vague, hedged, promotional, or formulaic text.                                                                                                                                                |
| `nextjs-guidelines`    | Writing or reviewing Next.js 16+ App Router code: Server Components, Server Actions, Cache Components, PPR, routing, middleware, and error boundaries.                                                                                                                                |
| `pressure-test`        | Challenging a proposal or pressure-testing a design through focused review.                                                                                                                                                                                                           |
| `prompt-engineering`   | Editing system prompts, agent instructions or rules, `.instructions.md`, `SKILL.md`, `.agent.md`, `.prompt.md`, `.mdc`, or configuring coding agent apps.                                                                                                                             |
| `python-coding`        | Writing, linting, formatting, testing, type-checking, reviewing, or refactoring Python code with `uv`, `ruff`, `mypy`, and `pytest`.                                                                                                                                                  |
| `react-guidelines`     | Writing or reviewing React 19+ code: Server Components, Client boundaries, hooks, React Compiler, Actions, Suspense, composition, and component tests.                                                                                                                                |
| `refactor-planning`    | Building a concrete refactor plan, RFC-style decision record, or breakdown into small safe commits.                                                                                                                                                                                   |
| `rules-distill`        | Extracting cross-cutting principles from multiple skills, promoting repeated guidance into shared rules, or checking for missing rule-level defaults.                                                                                                                                 |
| `rust-coding`          | Writing, linting, testing, building, reviewing, or refactoring Rust code with `cargo` and Clippy.                                                                                                                                                                                     |
| `typescript-coding`    | Writing, linting, formatting, testing, type-checking, reviewing, or refactoring TypeScript code with `tsc`, ESLint, Prettier, and Vitest.                                                                                                                                             |

## Disambiguation

- Prefer the narrowest matching skill.
- When repository-local documented policy conflicts with a language or framework skill default, follow the repository policy unless the task is to change that policy.
- For shared rule extraction across several skills, use `rules-distill`.
- For prompt or agent-behavior structure, use `prompt-engineering`.
- For prose cleanup only, use `natural-tone`.
- For language-specific coding tasks, use the language skill (`python-coding`, `typescript-coding`, `rust-coding`); `coding-guidelines` covers architecture and review across languages.

## Context-mode routing rules

You have context-mode MCP tools available. Default to them whenever a task matches one of the cues below — these are positive defaults, not preferences to weigh.

Default to `ctx_batch_execute(commands, queries)` when starting an investigation that needs several commands or several search questions answered together (initial repo survey, multi-file exploration, gathering build + test + git output in one pass).

Default to `ctx_execute(language, code)` when the task is to analyze, count, filter, compare, parse, transform, or summarize data. Concrete cues:

- the command output is likely to exceed ~20 lines (test runners, `git log`, `gh`/`curl` responses, package manager output, container or pod listings).
- the input is JSON, CSV, XML, log lines, or any structured blob.
- you would otherwise read raw output and reason about it manually — write code that prints the answer instead.

Default to `ctx_execute_file(path, language, code)` when you need to inspect a file's contents for analysis (logs, large source files, data files) rather than editing it. Use direct file reads only when the contents must be in context to edit them.

Default to `ctx_fetch_and_index(url, source)` followed by `ctx_search(queries)` for any web fetch. Do not reach for `curl`, `wget`, or terminal HTTP helpers — route the same intent through context-mode instead.

Default to `ctx_search(queries)` for follow-up questions on already-indexed content. Batch related questions into one call.

For deeper guidance (tool selection hierarchy, output constraints, `ctx` slash commands), see `$HOME/.copilot/instructions/context-mode.md`.

## Memory server routing rules

You have the `memory` MCP server available. It is the only mechanism that carries context across sessions, so both retrieval and capture have defined moments to fire.

### At session start

Call `search_nodes` with terms drawn from the request before planning or editing on any substantive task (coding, design, review, planning, or any answer that depends on user or project context). Skip only for purely mechanical requests (raw command execution, echo-style replies, arithmetic, one-line lookups). Use `open_nodes` when the entity is already known, and `read_graph` only when broad inspection is justified.

### Before ending each turn

Before your final reply in a turn, scan what surfaced during the work for durable signals and write them. Treat the cues below as concrete triggers — when one fires, call the corresponding memory tool before ending the turn.

| Trigger surfaced during the turn                                                                                                | Write to capture it                                                                            |
| ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| User states a stable preference ("I prefer X", "always use Y", "never do Z", a recurring style choice).                         | `add_observations` on the user entity, or `create_entities` for the user if it does not exist. |
| Project or repository convention discovered (build command, test command, lint command, directory layout, naming rule).         | `add_observations` on the repository entity, creating it with `create_entities` if missing.    |
| New recurring entity appears (collaborator, team, organization, service, dependency, repository, significant tool).             | `create_entities` for the entity, then `create_relations` to link it to user, project, etc.    |
| Existing entities gain a durable link (user `works_on` repo, repo `depends_on` service, project `uses` library, team `owns` X). | `create_relations` in active voice (`works_on`, `owns`, `prefers`, `depends_on`, `uses`).      |
| Long-lived goal or constraint stated (commitments, deadlines beyond this session, hardware or platform constraints).            | `add_observations` on the relevant goal or user entity.                                        |

Keep these out of memory: secrets, credentials, tokens, one-off task state, scratch debugging notes, volatile facts likely to change within days.

Decision rule before each write: would retrieving this in a future session improve the work? If yes, write before ending the turn. If no, skip.

For the full capture vocabulary, correction rules, and priority order, see `$HOME/.copilot/instructions/memory-server.md`.
