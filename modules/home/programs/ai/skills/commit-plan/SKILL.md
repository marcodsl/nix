---
name: commit-plan
description: Plan atomic commits from the current working tree and emit a paste-ready bash script; use when you want to stage and commit changes.
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: git, commits, workflow, planning
---

# Commit Plan

Investigate the working tree, group changes into atomic commits, write Conventional Commits messages, and emit a paste-ready shell script. Do not run any mutating git commands yourself.

## Use this skill when

- The user asks to commit, stage, or plan commits from uncommitted changes.
- The user wants a commit script or batch-commit plan for the current working tree.
- The user asks for help grouping or splitting changes into logical commits.

## Do not use this skill when

- The user only needs a single commit message for already-staged changes. Use `conventional-commits` instead.
- The user is asking about git history, rebasing, merging, or branch management unrelated to commit planning.

## Steps

### 1. Survey changes

Run read-only git inspection only:

- `git status --porcelain=v1 -uall`
- `git diff --stat` and `git diff` (unstaged)
- `git diff --staged` if anything is already staged
- For untracked files, read their contents directly.

Do not run `git add`, `git commit`, `git push`, or any other mutating command.

### 2. Group into atomic commits

Each group must satisfy all three properties:

- **Single scope of work** — one feature, fix, refactor, docs change, config update, or chore. If a change mixes intents (e.g., a feature and a refactor), split them.
- **Coupling** — files that must land together stay together: implementation + its tests, schema + migration, code + generated lockfile, type definition + all call-site updates.
- **Atomicity** — the commit compiles and passes tests on its own and is independently revertable.

Additional rules:

- Split unrelated drive-by edits in the same file into separate commits via `git add -p` hunks. Flag this in the plan when needed.
- Prefer fewer, well-scoped commits over many trivial ones. One commit per logical concern, not one per file.
- If a change breaks an existing contract (API, config key, CLI flag), isolate it so it can be reverted independently.
- Group infrastructure or tooling changes (CI config, lint rules, dependency updates) separately from feature/fix code when both exist in the same working tree.

### 3. Write commit messages

Follow Conventional Commits 1.0.0. Apply these rules inline; read `references/conventional-commits.md` for the full decision guide.

**Format:**

```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

**Type selection** — use the narrowest truthful type:

- `feat` — new user-facing feature.
- `fix` — bug or regression fix.
- `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `style`, `revert` — when they describe the change more accurately than `feat` or `fix`.

**Scope** — add only when it clarifies the subject. Short noun in parentheses: `(auth)`, `(parser)`, `(api)`. Omit when the change spans the whole repo or when scope adds no information.

**Breaking changes** — mark with `!` before the colon, a `BREAKING CHANGE:` footer, or both. Use when existing callers, configs, or consumers must change behavior.

**Description** — imperative mood, describe the result not the process, ≤72 characters.

Good: `fix(parser): reject invalid UTF-8 sequences`
Weak: `fix(parser): fixed parser bug`

**Body** — add when the subject alone does not explain the why, tradeoff, or operational effect. Wrap at 72 characters.

**Footers** — use for structured trailers: `BREAKING CHANGE:`, `Refs: #123`, `Closes: #456`, `Reviewed-by:`.

### 4. Optional PR metadata

If the change set spans more than one commit or is non-trivial, draft a PR title and description:

- Title mirrors the dominant commit's subject.
- Description states what changed, why, and any follow-ups — facts only.
- Apply `natural-tone` rules: direct, concrete, no filler, no marketing voice, no emoji, no hedging.

## Output format

Reply in this exact structure, nothing else:

### Plan

A 2–6 line summary of how you grouped the changes and why.

### Commands

A single fenced `bash` block the user can paste verbatim. For each commit:

```bash
git add -- <file1> <file2> ...
git commit -m "type(scope): subject" -m "optional body"
```

Use `git add -p -- <file>` (with a comment explaining which hunks) when a file must be split across commits. Quote paths with spaces.

### PR (only if drafted)

```
Title: <title>

<description>
```

## Constraints

- Only reference paths reported by `git status` / `git diff`. Do not invent files.
- If the working tree is clean, respond with exactly: `Working tree is clean - nothing to commit.` Do not emit the Plan/Commands structure.
- If you are uncertain how to split a change, ask one focused question and do not emit the Plan/Commands structure yet.
- Do not claim a commit was created unless you actually ran `git commit`.

## Verification

Before emitting the Plan/Commands structure, verify:

- Every file from `git status` appears in exactly one commit group (none omitted, none duplicated unless split via `-p`).
- Each commit message type matches the actual change (e.g., `feat` for new features, `fix` for bugs).
- Breaking changes are marked with `!` or a `BREAKING CHANGE:` footer.
- The script, if pasted verbatim, would produce a clean working tree.

## Bundled resources

Read `references/conventional-commits.md` for the full type decision guide, scope rules, breaking-change forms, and common mistakes.
