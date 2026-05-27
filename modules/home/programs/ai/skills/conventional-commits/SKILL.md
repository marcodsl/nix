---
name: conventional-commits
description: "Generate or execute a Conventional Commits 1.0.0 message that matches the actual diff. Triggers: 'write a commit message', 'commit this', 'is this commit message OK', `feat:`/`fix:`/`docs:`/`refactor:` prefixes, scope choice like `(api)`/`(parser)`, `BREAKING CHANGE` decisions, running `git commit` on the currently staged work. Skip when: general git questions about rebasing, merging, or history."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: git, commits, workflow, prompts
  version: 3
---

# Conventional Commits

<purpose>
Inspect a change, choose the right semantic intent, and produce or execute a Conventional Commits 1.0.0 message that matches the actual diff.
</purpose>

<scope>
  <use_when>
  - The user asks for a conventional commit message for an existing change.
  - The user asks you to commit current changes using Conventional Commits.
  - The user needs help choosing a type, scope, body, or footer.
  - The user wants to check whether a proposed message conforms to the spec.
  </use_when>

  <do_not_use_when>
  - General git troubleshooting unrelated to commit-message structure.
  - The repository enforces a different commit format and the user wants that format.
  - The current changes mix multiple unrelated intents. Recommend a split instead of forcing one vague message.
  </do_not_use_when>
</scope>

<governing_rule>
Describe the semantic intent of the change truthfully, using the smallest cohesive commit message that matches what the diff actually does. The Conventional Commits 1.0.0 specification (https://www.conventionalcommits.org/en/v1.0.0/#specification) is the authority. Do not invent stricter rules than the spec.
</governing_rule>

<working_method>
1. Inspect the working tree and index: `git status --short`, then `git diff --cached` for staged work or `git diff` for unstaged.
2. Prefer the staged diff as the source of truth when files are already staged. If the user asked you to commit, do not silently include unrelated unstaged changes.
3. Decide type, optional scope, optional breaking marker, description, optional body, optional footers.
4. If the diff spans multiple intents, recommend splitting before committing.
5. If the user asked for a message only, return the message and a brief rationale.
6. If the user asked you to commit, run `git commit` and report the exact message used. Do not claim a commit ran unless it did.
</working_method>

<section name="message-format">
Every Conventional Commit follows:

```text
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

- The type comes first, followed by the optional scope, optional `!`, then a required colon and single space.
- The description follows `: ` and is a short summary.
- A body may appear one blank line after the description.
- Footers appear one blank line after the body (or description when no body).
- Footers use `token: value` or `token #value`. Tokens replace spaces with `-`, except `BREAKING CHANGE` (and the equivalent `BREAKING-CHANGE`).
</section>

<section name="type-choice">
- `feat`: new feature. Required mapping when the change adds a feature.
- `fix`: bug or regression fix. Required mapping when the change fixes a bug.
- Other allowed extensions when they describe the change more accurately: `build`, `chore`, `ci`, `docs`, `perf`, `refactor`, `style`, `test`, `revert`. The list is not exhaustive.
- When a change looks like both a feature and a fix, prefer splitting. If it must stay together, choose the type that best matches the primary user-facing effect.
</section>

<section name="scope-choice">
- Add a scope only when it clarifies the subject. Use a short noun in parentheses naming the affected subsystem (`(parser)`, `(api)`, `(docs)`).
- Omit the scope when it adds no information or when the change cuts across the whole repository.
</section>

<section name="breaking-changes">
Treat a change as breaking when existing callers, configs, commands, or consumers must change behavior. Valid forms:
- `feat(api)!: remove v1 session endpoint`
- `feat: remove v1 session endpoint` with a `BREAKING CHANGE:` footer
- Both together when extra emphasis or detail helps

`!`, when present, must appear immediately before the colon.
</section>

<section name="description-style">
- Short, specific, imperative mood. Describe the result, not the process.
- Add a body only when the subject alone does not explain the why, tradeoff, or operational effect.
- Add footers for structured trailers (`BREAKING CHANGE: ...`, `Refs: #123`, `Reviewed-by: A`).
</section>

<section name="ambiguity">
Ask one focused question only when a missing fact changes the correct commit shape:
- Is this a new capability or a bug fix?
- Does this break an existing API, config, or workflow?
- Should these changes be split into separate commits?

If the diff supports one clear conventional message, proceed without asking.
</section>

<review_checklist>
- The message matches the actual diff, not the branch name, PR title, or issue title.
- Subject line follows `<type>[optional scope][optional !]: <description>`.
- `feat` is used for new features and `fix` for bug fixes when those meanings apply.
- Non-`feat`, non-`fix` types are treated as allowed extensions, not a closed list.
- Scope, if present, is a short noun in parentheses.
- Breaking changes use `!`, `BREAKING CHANGE:`, or both.
- Body and footer sections, if present, are separated by one blank line.
- Footer tokens use trailer-style formatting.
- No claim of commit execution unless the commit actually ran.
</review_checklist>

<bundled_resources>
- `references/examples.md` — worked examples for feature, fix, breaking, docs, revert, multi-paragraph commits, and subject/scope phrasing.
</bundled_resources>
