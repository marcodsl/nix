---
name: linear
description: "Idempotent upsert of Linear issues against current work: mark started or done, create sub-issues for partial work, attach new issues to open epics or parents, and dedupe before creating. Defaults to dry-run. Triggers: 'sync to Linear', 'create a Linear issue', 'update Linear', 'mark LIN-123 done', 'attach this to the epic', mention of an issue ID like `TEAM-123`, branch names like `feat/team-123-...`, or any reference to a Linear project, cycle, or workflow state. Skip when: the task is GitHub Issues, Jira, or planning that has not yet crossed into actionable work."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: linear, issues, tracking
  version: 3
---

# Linear Sync

<purpose>
Keep Linear issues aligned with repo work as an idempotent upsert. Find the right existing issue, update status when confidence is high, create a sub-issue when the match is broader, or create a new issue under an open broader parent when no direct match exists.
</purpose>

<scope>
  <use_when>
  - The user asks to sync, upsert, update, create, or reconcile Linear issues.
  - The user describes implementation work and wants it reflected in Linear.
  - The user wants issue status changed based on branch, PR, task, bug fix, feature, or review state.
  - Partial work needs tracking as a sub-issue under a broader existing issue.
  </use_when>

  <do_not_use_when>
  - The user is only brainstorming and has not identified actionable work.
  - The request is about GitHub issues, Jira, docs, or planning without Linear sync.
  </do_not_use_when>
</scope>

<governing_rule>
Never claim Linear was updated unless a write operation succeeded and was verified. Default to dry-run. Apply only when the user explicitly says to apply, sync, update, create, attach, or execute now.
</governing_rule>

<working_method>
1. Preflight: confirm Linear tools are available (list, read, create, sub-issue, update status, comment) and discover accessible teams/projects and their workflow states. Run these in parallel when the tool interface allows.
2. Resolve targets: team/project, target status (see `references/linear-reference.md#status-mapping`), assignee, priority. If any are missing and no safe default is discoverable, ask one concise clarifying question.
3. Search Linear and classify the best candidate using `references/linear-reference.md#search-and-scoring-criteria`.
4. Apply the upsert decision flow.
5. Verify the result using `references/linear-reference.md#verification-checklist`.
</working_method>

<section name="required-context">
Collect or infer before proposing changes:
- Work title or concise summary.
- Desired status intent (planned, started, in review, done, blocked, canceled, reopened).
- Target team, project, or workspace area when known.
- Assignee and priority when the user wants them changed.
- Optional: parent or epic hint, branch, commit, PR, URL, acceptance criteria, labels, due date.
</section>

<section name="dry-run-vs-apply">
- Dry-run (default): search and propose the exact update/create action; no writes.
- Apply: only after explicit user request.
- Confirm before changing to `Done`, `Canceled`, or another terminal state unless the user clearly says the work is complete or canceled.
- Confirm when confidence is low or multiple near-equal matches exist.
</section>

<section name="matching-modes">
Offer both modes when the user has no preference. Default to conservative.

- Conservative: update only for a strong direct match. Treat broader or partial matches as parent candidates; create a sub-issue for the current work. Ask when two or more candidates are close.
- Aggressive: update when title, scope, project/team, and status context strongly align. Still create a sub-issue when the matched issue is broader. Still ask before ambiguous or terminal-state changes.
</section>

<section name="upsert-decision-flow">
Strong match → update existing issue:
- Update status to the mapped target status. Upsert assignee and priority when provided.
- Add a short sync comment when useful (branch, PR, implementation context).
- Do not rewrite title, description, labels, project, or due date unless the user asks.

Partial or broader match → create sub-issue:
- Create a sub-issue under the best broader parent.
- Set status to mapped target; set assignee and priority when provided.
- Use a title specific to the current work, not a duplicate of the parent.
- Include the parent rationale in description or sync comment; link back to source context when available.

No direct match → create issue, attach to broader parent when safe:
- Search for an open broader-scope parent in the same team/project/product area.
- One high-confidence parent → create as sub-issue under it.
- Multiple plausible parents → ask the user to choose.
- No high-confidence parent → create a top-level issue and report that no open broader parent was found.
</section>

<section name="idempotency-and-safety">
- Before creating any issue, search recent and open issues by title, branch, PR, URL, or acceptance criteria. If a duplicate exists, update or report instead of creating.
- Never archive, delete, or permanently remove Linear issues.
- Never close or cancel broad parent issues because a sub-issue is complete.
- Never infer sensitive customer or credential details into issue descriptions.
- Prefer asking when the action would affect the wrong team, a terminal status, or multiple similar candidates.
</section>

<section name="output-contract">
Return results in normal markdown. No raw schema dumps or pseudo-JSON.

Cover compactly:
- Mode: `dry-run` or `applied`.
- Action: `update_existing`, `create_sub_issue`, `create_issue_with_parent`, `create_top_level_issue`, `blocked`, or `needs_confirmation`.
- Matching mode: `conservative` or `aggressive`.
- Match confidence: `high`, `medium`, or `low`.
- Matched issue, created issue, and parent issue when relevant.
- Status, assignee, and priority before and after when relevant.
- One or two concise reasoning bullets.

When more input is required, use the agent's follow-up or question tool. Prefer structured choices for picking between candidates, parents, assignees, teams, projects, or states. Fall back to one short markdown question if no question tool is available.

In dry-run, label changes as proposed. In apply mode, label completed writes and verified fallbacks.
</section>

<bundled_resources>
- `references/linear-reference.md` — status mapping, search-and-scoring criteria, verification checklist.
</bundled_resources>
