---
name: plan-commits
description: "Investigate the working tree, group changes into atomic commits with Conventional Commits messages, and emit a paste-ready bash script. Inspects only; never runs `git add`/`commit`/`push` itself. Triggers: 'plan commits', 'commit my changes', 'stage and commit', 'split these changes', 'group into commits', running `git status` on a working tree with multiple unrelated edits, or any request to turn the current diff into more than one commit. Skip when: the task is general git history, rebasing, or branch management."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: git, commits, workflow, planning
  version: 3
---

# Plan Commits

<purpose>
Investigate the working tree, group changes into atomic commits, write Conventional Commits messages, and emit a paste-ready shell script. Do not run any mutating git commands.
</purpose>

<scope>
  <use_when>
  - The user asks to commit, stage, or plan commits from uncommitted changes.
  - The user wants a commit script or batch-commit plan for the current working tree.
  - The user asks for help grouping or splitting changes into logical commits.
  </use_when>

  <do_not_use_when>
  - The user is asking about git history, rebasing, merging, or branch management unrelated to commit planning.
  </do_not_use_when>
</scope>

<governing_rule>
Only inspect; never mutate. Do not run `git add`, `git commit`, `git push`, or any other write command. Reference only paths reported by `git status` / `git diff`; never invent files.
</governing_rule>

<working_method>
1. Survey changes with read-only git inspection.
2. Group changes into atomic commits.
3. Write Conventional Commits messages.
4. Optionally draft PR metadata.
5. Emit the Plan + Commands script in the required format.
</working_method>

<section name="survey">
Run read-only inspection only:
- `git status --porcelain=v1 -uall`
- `git diff --stat` and `git diff` (unstaged)
- `git diff --staged` if anything is staged
- For untracked files, read their contents directly.
</section>

<section name="grouping">
Each group must satisfy all three:
- Single scope of work: one feature, fix, refactor, docs change, config update, or chore. Split mixed intents.
- Coupling: files that must land together stay together (implementation + tests, schema + migration, code + lockfile, type definition + call-site updates).
- Atomicity: the commit compiles and passes tests on its own and is independently revertable.

Additional rules:
- Split unrelated drive-by edits in the same file via `git add -p` hunks. Flag this in the plan when needed.
- Prefer fewer, well-scoped commits over many trivial ones. One commit per logical concern, not per file.
- If a change breaks an existing contract (API, config key, CLI flag), isolate it for independent revert.
- Group infrastructure or tooling changes (CI, lint rules, dep updates) separately from feature/fix code.
</section>

<section name="messages">
Follow Conventional Commits 1.0.0. The full decision guide is `references/conventional-commits.md`.

Format:
```
<type>[optional scope][optional !]: <description>

[optional body]

[optional footer(s)]
```

- Type: narrowest truthful. `feat` for new user-facing features, `fix` for bug or regression fixes. `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `style`, `revert` when more accurate.
- Scope: short noun in parentheses (`(auth)`, `(parser)`, `(api)`) only when it clarifies the subject. Omit for repo-wide changes.
- Breaking: `!` before the colon, a `BREAKING CHANGE:` footer, or both, whenever existing callers, configs, or consumers must change behavior.
- Description: imperative mood, describe the result not the process, ≤72 chars. Good: `fix(parser): reject invalid UTF-8 sequences`. Weak: `fix(parser): fixed parser bug`.
- Body: add only when the subject alone does not explain the why, tradeoff, or operational effect. Wrap at 72 chars.
- Footers: `BREAKING CHANGE:`, `Refs: #123`, `Closes: #456`, `Reviewed-by:`.
</section>

<section name="pr-metadata">
If the change set spans more than one commit or is non-trivial, draft a PR title and description:
- Title mirrors the dominant commit's subject.
- Description states what changed, why, and follow-ups. Facts only.
- Apply `natural-tone` rules: direct, concrete, no filler, no marketing voice, no emoji, no hedging.
</section>

<section name="output-format">
Reply in this exact structure, nothing else:

### Plan

2-6 line summary of grouping and rationale.

### Commands

A single fenced `bash` block, paste-ready:

```bash
git add -- <file1> <file2> ...
git commit -m "type(scope): subject" -m "optional body"
```

Use `git add -p -- <file>` with a comment for hunk-split files. Quote paths with spaces.

### PR (only if drafted)

```
Title: <title>

<description>
```
</section>

<section name="edge-cases">
- Working tree clean: respond with exactly `Working tree is clean - nothing to commit.` Do not emit the Plan/Commands structure.
- Uncertain how to split: ask one focused question; do not emit the structure yet.
- Never claim a commit ran unless `git commit` actually executed.
</section>

<review_checklist>
- Every file from `git status` appears in exactly one commit group (none omitted, none duplicated unless split via `-p`).
- Each commit message type matches the actual change.
- Breaking changes are marked with `!` or a `BREAKING CHANGE:` footer.
- The script, if pasted verbatim, would produce a clean working tree.
</review_checklist>

<bundled_resources>
- `references/conventional-commits.md` — full type decision guide, scope rules, breaking-change forms, common mistakes.
</bundled_resources>
