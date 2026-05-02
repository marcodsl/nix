---
name: linear
description: "Create, update, or sync Linear issues with your current work: mark issues started or done, create sub-issues for partial work, attach new issues to open epics, and check for duplicates before creating."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: linear, issues, tracking
---

# Linear Sync

Use this skill to keep Linear issues aligned with repo work. The goal is an idempotent upsert: find the right existing issue, update status when confidence is high, create a sub-issue when the existing issue is broader, or create a new issue attached to a broader open parent when no direct match exists.

## Use when

- The user asks to sync, upsert, update, create, or reconcile Linear issues.
- The user describes implementation work and asks to reflect it in Linear.
- The user wants issue status changed based on current branch, PR, task, bug fix, feature, or review state.
- The user wants partial work tracked as a sub-issue under a broader existing issue.

## Do not use when

- The user is only brainstorming and has not identified actionable work.
- The request is about GitHub issues, Jira, docs, code implementation, or planning without Linear sync.

## Required context

Collect or infer before proposing changes:

- Work title or concise summary.
- Desired status intent (planned, started, in review, done, blocked, canceled, reopened).
- Target team, project, or workspace area when known.
- Assignee and priority when the user wants them changed.
- Optional: parent or epic hint, branch, commit, PR, URL, acceptance criteria, labels, due date.

If team/project, target status, assignee, or priority cannot be inferred and no safe default is discoverable, ask one concise clarifying question.

## Preflight

1. Confirm Linear tools are available (list, read, create, sub-issue, update status, comment).
2. Discover accessible teams/projects and their workflow states.

Steps 1 and 2 are independent; run them in parallel when the tool interface allows it.

3. Resolve target team/project from user input, work context, or discovered defaults.
4. Resolve target status from the [status mapping](references/linear-reference.md#status-mapping).
5. Resolve target assignee to an exact Linear user when provided.
6. Resolve target priority to the team's supported value when provided.
7. If tools, permissions, team, assignee, priority, or workflow states are unavailable, stop at a dry-run recommendation and state what is missing.

Never claim Linear was updated unless a write operation succeeded and was verified.

## Dry-run versus apply

Default to dry-run.

- In dry-run mode, search and propose the exact update/create action but do not write to Linear.
- Apply only when the user explicitly says to apply, sync, update, create, attach, or execute now.
- Even in apply mode, ask for confirmation before changing an issue to `Done`, `Canceled`, or another terminal state unless the user clearly says the work is complete or canceled.
- Ask for confirmation when confidence is low or multiple near-equal matches exist.

## Matching mode

Offer both modes when the user has not specified a preference. Default to conservative.

### Conservative mode

- Update only for a strong direct match.
- Treat broader or partial matches as parent candidates; create a sub-issue for the current work.
- Ask when two or more candidates are close.

### Aggressive mode

- Update when title, scope, project/team, and status context strongly align.
- Still create a sub-issue when the matched issue is broader than the current work.
- Still ask before ambiguous or terminal-state changes.

## Search and classify

Search Linear and classify the best candidate using [scoring criteria](./references/linear-reference.md#search-and-scoring-criteria):

- **Strong match**: same concrete work item.
- **Partial/broader match**: related issue exists but is wider, partially overlaps, or should own the current work as a child.
- **No direct match**: no issue represents the current work.

## Upsert decision flow

### 1. Strong match: update existing issue

- Update status to the mapped target status.
- Upsert assignee and priority when provided.
- Add a short sync comment when useful (branch, PR, or implementation context).
- Do not rewrite title, description, labels, project, or due date unless the user asks.

### 2. Partial or broader match: create sub-issue

- Create a sub-issue under the best broader parent.
- Set status to the mapped target status; set assignee and priority when provided.
- Use a title specific to the current work, not a duplicate of the parent.
- Include the parent rationale in the description or sync comment; link back to source context when available.

### 3. No direct match: create issue and attach to broader parent when safe

- Search for an open broader-scope parent in the same team/project/product area.
- If exactly one high-confidence parent exists, create as a sub-issue under it.
- If multiple plausible parents exist, ask the user to choose.
- If no high-confidence parent exists, create a top-level issue and report that no open broader parent was found.
- Set status to the mapped target status; set assignee and priority when provided.

## Idempotency and safety

- Before creating any issue, search recent and open issues for the same title, branch, PR, URL, or acceptance criteria.
- If a duplicate exists, update or report that issue instead of creating another one.
- Never archive, delete, or permanently remove Linear issues.
- Never close or cancel broad parent issues just because a sub-issue is complete.
- Never infer sensitive customer or credential details into issue descriptions.
- Prefer asking when the action would affect the wrong team, a terminal status, or multiple similar candidates.

## Output contract

Return results in normal markdown. Do not emit a raw schema dump, pseudo-JSON, or fenced text contract.

Use a compact structure with short sections or flat bullets covering:

- Mode: `dry-run` or `applied`.
- Action: `update_existing`, `create_sub_issue`, `create_issue_with_parent`, `create_top_level_issue`, `blocked`, or `needs_confirmation`.
- Matching mode: `conservative` or `aggressive`.
- Match confidence: `high`, `medium`, or `low`.
- Matched issue, created issue, and parent issue when relevant.
- Status, assignee, and priority before and after when relevant.
- One or two concise reasoning bullets.

When more input is required:

- Use follow-up or question tools to collect missing choices instead of writing plain-text requests.
- Prefer structured choices when the user needs to pick between candidates, parents, assignees, teams, projects, or states.
- If no interactive question tool is available, ask one short markdown question.
- Keep the response concise; do not add a separate `follow_up_needed` field.

In dry-run mode, label changes as proposed. In apply mode, label completed writes and verified fallbacks.

After applying, verify using the [verification checklist](references/linear-reference.md#verification-checklist).
