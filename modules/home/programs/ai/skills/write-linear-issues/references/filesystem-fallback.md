# Filesystem Fallback

When no Linear write tool is reachable, the skill writes one markdown file per issue. This file documents the directory choice, the naming scheme, the frontmatter contract, and how the existing `linear` skill can later consume the files.

## When this mode is active

Trigger any one of:

1. No Linear write tool is exposed by the host (no MCP, no native tool).
2. A read-only Linear probe (`list_teams` or equivalent) errors.
3. The user explicitly says `save to disk`, `write to files`, or `no Linear`.

Detect once per session. Report the sink in every output (`Sink: filesystem: <path>`).

## Directory choice

Default: `./linear-issues/` in the user's working directory.

Before creating it, scan for an existing directory the user probably already uses:

1. `./linear-issues/` (preferred — matches the default).
2. `./issues/`.
3. `./.linear/`.
4. `./docs/issues/`.

If one of the above exists with at least one `*.md` file, use it. If multiple exist, ask the user which to use. If none exist, ask once before creating `./linear-issues/`.

Never write outside the working directory tree. Never delete files. Never overwrite an existing file without an explicit second confirmation.

## File-name scheme

Parent–child is encoded in the filename so `ls` sorts naturally and parentage is scannable without opening the files.

- **Top-level:** `NNN-<kebab-slug>.md`, where `NNN` is the next free three-digit sequence in the directory (`001`, `002`, …).
- **Child:** `NNN.MMM-<kebab-slug>.md` (`001.001`, `001.002`, …).
- **Grandchild:** `NNN.MMM.KKK-<kebab-slug>.md`.

Slug rules:

- Lowercase, ASCII, hyphenated.
- Maximum 60 characters.
- Strip articles and filler (`a`, `the`, `for`, `to`, `of`) only if needed to fit the budget.
- Slug should be derivable from the title alone; do not include the sequence number in the slug.

To find the next free sequence: list the directory, parse the leading `NNN[.MMM…]` from each filename, take the max at the relevant level, add one.

## Frontmatter contract

Each file is YAML frontmatter followed by the description as markdown body. The frontmatter mirrors the fields the `linear` skill needs to upsert later, so a future `sync to Linear` pass can consume the directory without re-asking the user.

```yaml
---
title: <imperative title, matches what the issue title will be in Linear>
classification: feature | bug | chore | spike
team: <optional team key or name>
project: <optional project name>
priority: <optional: urgent | high | medium | low>
assignee: <optional username or email>
status_intent: backlog | todo | in_progress | in_review | done
parent: <NNN[.MMM…]-slug.md filename of the parent, or null>
source: <optional URL, branch, PR, or other origin link>
---

<description body, or empty when the title is sufficient>
```

Field rules:

- `title` is required. Everything else is optional.
- `classification` is required so the later sync can pick the right Linear label or template.
- `parent` is the filename, not a path. Empty or `null` means top-level.
- Do not invent values. If the user did not give `team`, `project`, `priority`, or `assignee`, omit the key or leave it empty. Inventing is the user-story anti-pattern in disguise.
- `status_intent` defaults to `backlog` for new issues written from scratch and to whatever the user said for rewrites.

## Worked example

User asks: `Save these to disk. Split the auth refactor into the three siblings we discussed.`

The skill writes four files (one parent project-shaped issue plus three children):

```
linear-issues/
├── 001-auth-jwt-migration.md
├── 001.001-replace-session-middleware-with-jwt-verifier.md
├── 001.002-migrate-existing-sessions-to-jwt-on-next-login.md
└── 001.003-update-auth-docs-to-describe-jwt-flow.md
```

`001-auth-jwt-migration.md`:

```yaml
---
title: Auth → JWT migration
classification: spike
status_intent: backlog
parent: null
---

Tracking parent for the JWT migration. Children carry the implementation work.
```

`001.001-replace-session-middleware-with-jwt-verifier.md`:

```yaml
---
title: Replace session middleware with JWT verifier
classification: feature
status_intent: backlog
parent: 001-auth-jwt-migration.md
---

Swap the session lookup middleware in `server/auth/middleware.ts` for a JWT verifier.
Verifier accepts the `Authorization: Bearer <token>` header and rejects expired tokens with 401.
```

Children 002 and 003 follow the same pattern.

## Apply gating in filesystem mode

Same rules as the Linear sink. Dry-run prints the proposed paths, frontmatter, and bodies. The skill writes files only after the user says `write`, `apply`, `create`, or `save`.

For a split, ask the user whether to apply one file at a time, all at once, or per-issue. Do not assume `apply all` unless the user said it.

## Later sync into Linear

When the workspace becomes reachable again, the existing `linear` skill can sync the directory upward. The contract:

1. Read each `*.md` in numeric order.
2. For each file, upsert in Linear using the frontmatter as the field source and the body as the description.
3. Resolve `parent` by sync'ing parents before children and mapping local filenames to created Linear issue IDs.
4. After successful upsert, the `linear` skill may append a `linear_id: <ID>` line to the file's frontmatter so subsequent syncs are idempotent. This skill does not append `linear_id` itself.

The contract lives in this one file. Both skills read from here; do not duplicate it in the `linear` skill's reference.
