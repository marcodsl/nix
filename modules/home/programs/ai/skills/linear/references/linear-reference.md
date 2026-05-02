# Linear Reference

Detailed lookup tables and guidance referenced by the Linear sync skill.

## Status mapping

Map user intent to the closest discovered Linear workflow state for the target team:

- idea, backlog, later, planned → `Backlog`
- todo, ready, accepted, queued → `Todo`
- started, working, implementing, active → `In Progress`
- review, PR open, validating, QA → `In Review`
- shipped, complete, fixed, done, merged → `Done`
- canceled, dropped, duplicate, won't do → `Canceled`

If the preferred state does not exist, choose the closest non-terminal discovered state and report the fallback. Ask when no safe fallback exists.

Do not move an issue to `Done` or `Canceled` unless the user's request explicitly indicates completion or cancellation.

## Assignee and priority upsert rules

- Upsert only when the user provides them or explicitly asks for a change.
- For existing issues, leave assignee and priority unchanged when not mentioned.
- For new issues and sub-issues, set when provided; otherwise leave unset unless the team has an explicit default.
- If the assignee name is ambiguous, search Linear users and ask the user to choose.
- If the requested priority does not map cleanly, use the closest safe value and report the fallback, or ask when the mapping is unclear.
- Do not clear an existing assignee or priority unless explicitly asked.

## Search and scoring criteria

Build a query from the normalized work title, important nouns, component names, route/module names, branch tokens, PR title, and parent hints. Prefer open issues but include recently completed ones to avoid duplicates.

Score candidates using:

- Title and normalized keyword overlap.
- Semantic scope overlap with the described work.
- Same team, project, label, component, or product area.
- Parent/epic relationship or explicit parent hint.
- Recency and current open status.
- Whether the candidate is narrower, equal, or broader in scope.
- Existing links to the same branch, PR, commit, route, module, or acceptance criteria.

## Issue content conventions

- Title: concise, action-oriented, specific to the current work.
- Description: source summary, acceptance criteria if known, relevant links, status intent, and matching/parent rationale.
- Labels, assignee, priority, due date: set only if provided by the user or the team has an explicit default.
- Comments: short and factual; add when the status change reason is not obvious; include branch, PR, commit, or file path links when available.

## Issue breakdown hierarchy

Use a clear hierarchy to keep work navigable. Skip levels that don't add coordination value for the team's size and stage.

- **Epic**: Large feature or capability; weeks–months; PM / Tech Lead.
- **Story**: User-facing slice of an epic; days–1 week; Engineer + PM.
- **Task**: Technical work unit inside a story; hours–1 day; Engineer.
- **Micro-task**: Atomic, single-action step; <2 hours; Engineer.

Example decomposition:

```
Epic:     Checkout & Payment Flow
 └─ Story:   Support multiple payment methods
     └─ Task:   Integrate Stripe payment intent API
         ├─ Micro: Add payment intent creation endpoint
         ├─ Micro: Write unit tests for webhook signature validation
         ├─ Micro: Add payment event logging to audit table
         └─ Micro: Update OpenAPI schema for payment endpoints
```

### Rules of thumb

- Epics map to a roadmap quarter or milestone.
- Stories should be independently deployable or demoable.
- Tasks are code-level—one PR per task is a healthy target.
- Micro-tasks are commit-level units; each should map to a single `feat:` / `fix:` conventional commit.
- If a micro-task takes >2h, split it or escalate to a task.

### When to skip levels

- Solo/early-stage teams: **Epic → Task** is often enough.
- Pure infra/DevOps work: Epics → Tasks is natural; "story" doesn't always fit.
- If a task has 8+ micro-tasks or spans multiple days, split it into sibling tasks under the epic.
- If you can't write a single conventional commit message for a micro-task, it's too big. If you can't close a task in one focused session (~half a day), split it.

## Sample output

Use these examples to calibrate the output contract.

### Dry-run — update existing issue

```
Mode: dry-run
Action: update_existing
Matching mode: conservative
Confidence: high

Matched: ENG-412 — "Integrate Stripe payment intent API" (In Progress → In Review)
Assignee: unchanged (alice)
Priority: unchanged (Medium)

— Title and component overlap is exact; branch `feat/stripe-payment-intent` links directly to this issue.
— Status mapped from "in review" → `In Review`; no terminal-state risk.
```

### Applied — create sub-issue under parent

```
Mode: applied
Action: create_sub_issue
Matching mode: conservative
Confidence: medium (parent match)

Created: ENG-521 — "Add payment intent creation endpoint" (Todo)
Parent: ENG-412 — "Integrate Stripe payment intent API"
Assignee: alice  Priority: Medium

— No existing issue for this specific endpoint unit; ENG-412 is broader and owns it.
— Duplicate check ran; no open issue matched branch or title tokens.
```

## Verification checklist

After applying changes, verify and report:

- The target issue or sub-issue exists.
- The final status matches the mapped target state.
- The final assignee and priority match the requested values when they were part of the request.
- The parent-child relation exists when a parent was selected.
- Duplicate detection ran before creating a new issue.
- Any intended sync comment or source link was added.
- Any skipped action or fallback was explained.
