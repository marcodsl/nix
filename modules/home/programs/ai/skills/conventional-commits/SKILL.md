---
name: conventional-commits
description: "Generate or execute commit messages that conform to Conventional Commits 1.0.0. Use when: inspecting a diff, choosing a commit type or scope, drafting a commit subject/body/footer, or creating a git commit from the current changes."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: git, commits, workflow, prompts
---

# Conventional Commits

## Purpose

Use this skill to inspect a change, choose the right semantic intent, and produce or execute a Conventional Commits 1.0.0 message that matches the actual diff.

## Source of truth

Use the Conventional Commits 1.0.0 specification as the authority:

- https://www.conventionalcommits.org/en/v1.0.0/#specification

If this skill conflicts with old habits, ad hoc examples, or local folklore, follow the specification unless the user or repository provides an explicit extension.

Do not invent stricter rules than the specification. In particular:

- `feat` and `fix` have required meanings when applicable.
- Additional types are allowed, but the specification does not define a closed list.
- Scope, body, and footers are optional.
- Breaking changes may be indicated with `!`, a `BREAKING CHANGE:` footer, or both.

## Scope

### Use this skill when

- The user asks for a conventional commit message for an existing change.
- The user asks you to commit current changes using Conventional Commits.
- The user needs help choosing a type, scope, body, or footer.
- The user wants to check whether a proposed commit message conforms to the spec.

### Do not use this skill when

- The task is general git troubleshooting unrelated to commit-message structure.
- The repository has a different enforced commit format and the user asked to follow that format instead.
- The current changes mix multiple unrelated intents and should be split before committing. In that case, recommend a split instead of forcing one vague message.

## Governing rule

Describe the semantic intent of the change truthfully, using the smallest cohesive commit message that matches what the diff actually does.

## Operating rules

1. Inspect the actual change before proposing or executing a commit message. Start with `git status --short`, then inspect `git diff --cached` for staged work or `git diff` for unstaged work.
2. Prefer the staged diff as the source of truth when files are already staged. If the user asked you to commit, do not silently include unrelated unstaged changes.
3. Use `feat` when the commit adds a new feature. Use `fix` when the commit fixes a bug. Treat these mappings as required when they apply.
4. Use another type only when it better matches the change. Common extensions include `build`, `chore`, `ci`, `docs`, `perf`, `refactor`, `style`, `test`, and `revert`, but the list is not exhaustive.
5. Use a scope only when it adds useful context. The scope should be a noun in parentheses such as `(parser)`, `(api)`, or `(docs)`.
6. Mark breaking changes with `!` immediately before the colon, a `BREAKING CHANGE:` footer, or both.
7. If one diff spans multiple semantic changes, recommend splitting it into multiple commits whenever practical instead of flattening everything into one description.
8. Do not claim a commit was created unless you actually ran `git commit`.

## Message format

Every Conventional Commit must follow this shape:

```text
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

Apply these rules from the spec:

- The type comes first and is followed by the optional scope, the optional `!`, then a required colon and single space.
- The description immediately follows the `: ` and should be a short summary of the change.
- A body may appear one blank line after the description.
- One or more footers may appear one blank line after the body, or one blank line after the description when there is no body.
- Each footer uses a token followed by `: ` or ` #`, then a value.
- Footer tokens use `-` instead of spaces, except `BREAKING CHANGE`, which is allowed as written. `BREAKING-CHANGE` is also valid.

## Decision guide

### Choose the type

Use the narrowest truthful type:

- `feat`: introduces a new feature.
- `fix`: fixes a bug or regression.
- `docs`: documentation-only change.
- `refactor`: internal restructuring that does not change external behavior.
- `perf`: performance improvement.
- `test`: adds or updates tests.
- `build`, `ci`, `chore`, `style`, `revert`: common extensions when they describe the change more accurately.

When a change looks like both a feature and a fix, prefer splitting it into multiple commits if possible. If it must stay together, choose the type that best represents the primary user-facing effect.

### Choose the scope

Add a scope only when it makes the subject clearer. Good scopes are short nouns that name the affected subsystem, package, or surface area.

Good: `feat(api): add cursor pagination`

Weak: `feat(stuff): add pagination`

Omit the scope when it adds no information or when the change cuts across the whole repository.

### Choose whether it is breaking

Treat the change as breaking when existing callers, configs, commands, or consumers must change behavior to keep working.

Use one of these valid forms:

- `feat(api)!: remove v1 session endpoint`
- `feat: remove v1 session endpoint` with a `BREAKING CHANGE:` footer
- Both of the above when extra emphasis or detail helps

If `!` is present, it must appear immediately before the colon.

### Choose the description

The description should be short, specific, and written in the imperative mood.

- Good: `fix(parser): reject invalid UTF-8 sequences`
- Weak: `fix(parser): fixed parser bug`
- Weak: `chore: stuff`

Describe the result of the change, not the process used to make it.

### Choose whether to add a body or footers

Add a body when the subject line alone does not explain the why, tradeoff, or operational effect.

Add footers when you need structured trailers such as:

- `BREAKING CHANGE: configuration files must now use TOML`
- `Refs: #123`
- `Reviewed-by: A`

## Ambiguity handling

Ask a focused question only when one missing fact changes the correct commit shape. Typical clarifications:

- Is this a new capability or a bug fix?
- Does this break an existing API, config, or workflow?
- Should these changes be split into separate commits?

If the user asked you to commit and the diff clearly supports one conventional message, proceed without unnecessary questions.

## Execution workflow

1. Inspect the working tree and index.
2. Determine whether the requested commit should use staged changes, specific files, or the full current diff.
3. Decide the type, optional scope, optional breaking marker, description, optional body, and optional footers.
4. If the diff contains multiple intents, recommend splitting before committing.
5. If the user asked for a message only, return the proposed commit message and a brief rationale.
6. If the user asked you to create the commit, run the necessary git commands and report the exact message used.

When executing a commit with a body or footers, preserve paragraph breaks. Repeated `-m` flags are usually the simplest approach:

```bash
git commit -m "fix(parser): prevent racing of requests" \
  -m "Introduce a request id and keep only the latest response." \
  -m "Refs: #123"
```

Do not promise that a commit command ran automatically. Run it only when the user asked you to commit or the surrounding workflow explicitly authorizes that action.

## Examples

### Feature

```text
feat(lang): add Polish language
```

### Bug fix with body and footers

```text
fix(parser): prevent racing of requests

Introduce a request id and keep only the latest response.
Remove timeout-based mitigation that is now obsolete.

Reviewed-by: Z
Refs: #123
```

### Breaking change with `!`

```text
feat(api)!: remove v1 session endpoint
```

### Breaking change with footer

```text
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` in config files now loads and merges external config files.
```

### Documentation-only change

```text
docs: correct spelling of CHANGELOG
```

### Revert-style extension

```text
revert: drop experimental formatter integration

Refs: 676104e
```

## Verification checklist

- [ ] The message matches the actual diff, not the branch name, PR title, or issue title.
- [ ] The subject line follows `<type>[optional scope][optional !]: <description>`.
- [ ] `feat` is used for new features and `fix` is used for bug fixes when those meanings apply.
- [ ] Any non-`feat` and non-`fix` type is treated as an allowed extension, not as part of a closed required list.
- [ ] The scope, if present, is a short noun in parentheses.
- [ ] Breaking changes use `!`, `BREAKING CHANGE:`, or both.
- [ ] Body and footer sections, if present, are separated by one blank line.
- [ ] Footer tokens use trailer-style formatting.
- [ ] The assistant does not claim to have committed anything unless it actually executed the commit.
