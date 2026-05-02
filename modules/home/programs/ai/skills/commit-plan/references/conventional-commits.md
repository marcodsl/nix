# Conventional Commits Reference

Detailed decision guide for writing Conventional Commits 1.0.0 messages. Source of truth: https://www.conventionalcommits.org/en/v1.0.0/#specification

## Message shape

```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

- Type is first, followed by optional scope, optional `!`, then `: ` and description.
- Body starts one blank line after description.
- Footers start one blank line after body (or after description when no body).
- Footer tokens use `-` instead of spaces, except `BREAKING CHANGE`.

## Type decision guide

Use the narrowest truthful type:

- `feat` — adds a new user-facing feature. Required when applicable.
- `fix` — fixes a bug or regression. Required when applicable.
- `docs` — documentation-only change.
- `refactor` — internal restructuring with no external behavior change.
- `perf` — performance improvement.
- `test` — adds or updates tests only.
- `build` — build system or external dependency changes.
- `ci` — CI configuration or script changes.
- `chore` — maintenance work not fitting other types.
- `style` — formatting, whitespace, semicolons (no logic change).
- `revert` — reverts a previous commit.

When a change looks like both `feat` and `fix`, split into separate commits if possible. If it must stay together, choose the type that best represents the primary user-facing effect.

Additional types are allowed; the spec does not define a closed list.

## Scope rules

- Add a scope only when it makes the subject clearer.
- Scope is a short noun in parentheses: `(parser)`, `(api)`, `(auth)`.
- Omit scope when it adds no information or when the change spans the whole repo.

Good: `feat(api): add cursor pagination`
Weak: `feat(stuff): add pagination`

## Breaking changes

Mark breaking when existing callers, configs, commands, or consumers must change behavior. Valid forms:

- `feat(api)!: remove v1 session endpoint` — `!` immediately before the colon.
- `feat: remove v1 session endpoint` with footer `BREAKING CHANGE: description`.
- Both for extra emphasis.

## Description rules

- Short, specific, imperative mood.
- Describe the result of the change, not the process.
- Good: `fix(parser): reject invalid UTF-8 sequences`
- Weak: `fix(parser): fixed parser bug`
- Weak: `chore: stuff`

## When to add body

Add a body when the subject alone does not explain the why, tradeoff, or operational effect. Wrap at ~72 characters.

## When to add footers

Use footers for structured trailers:

- `BREAKING CHANGE: config files must now use TOML`
- `Refs: #123`, `Closes: #456`
- `Reviewed-by: A`
- `Co-authored-by: Name <email>`

## Common mistakes

- Using `feat` for bug fixes or `fix` for new features.
- Writing past tense (`fixed`, `added`) instead of imperative (`fix`, `add`).
- Vague descriptions (`update stuff`, `misc changes`).
- Missing `!` or `BREAKING CHANGE:` footer for breaking changes.
- Flattening multiple unrelated intents into one commit instead of splitting.
