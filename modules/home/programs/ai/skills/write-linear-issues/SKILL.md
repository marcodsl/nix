---
name: write-linear-issues
description: "Write, rewrite, or improve Linear issues following the Linear Method: short plain-language titles, optional descriptions, concrete tasks instead of user stories. Prompts to split scope when the issue is too big for one task. Falls back to writing one markdown file per issue when no Linear workspace is reachable. Defaults to dry-run; writes only on explicit user approval. Triggers: 'write a Linear issue', 'improve this issue', 'rewrite as a task', 'turn this user story into an issue', pasting a draft issue into chat, or asking for an issue from a feature or bug description. Skip when: the task is GitHub Issues or Jira (no Linear writing), pure status changes on an existing issue (use the `linear` skill), or general product spec or roadmap discussion that is not yet a task."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: linear, issues, writing
  version: 1
---

# Write Linear Issues

<purpose>
Turn intent, drafts, or pastes into Linear issues that follow the Linear Method: a concrete task with a short, plain-language title and only the description text the assignee needs to do the work. Split the work when the scope spans more than one task. Apply only on explicit user approval; otherwise produce a dry-run proposal.
</purpose>

<scope>
  <use_when>
  - The user asks to write, rewrite, draft, improve, polish, or shorten a Linear issue.
  - The user pastes a draft, a Slack-style bug report, an email, or a user story and wants it turned into one or more issues.
  - The user describes work in chat and wants the corresponding issue text produced.
  - The user wants a too-big issue split into siblings or sub-issues.
  </use_when>

  <do_not_use_when>
  - The user only wants to change the status, assignee, priority, or parent of an existing issue. Defer to the `linear` skill, which owns idempotent upsert and status sync.
  - The work is GitHub Issues, Jira, or another tracker with no Linear writing involved.
  - The conversation is still product or roadmap exploration and no concrete task has emerged. Suggest a project spec doc, or a placeholder issue like `Write project spec for X`, then stop.
  - The input is a long narrative description and the user only wants prose-level cleanup. Defer to the `natural-tone` skill, then return here for the structural rewrite.
  </do_not_use_when>
</scope>

<governing_rule>
An issue is a concrete task with a defined outcome, written in plain language. No `As a <role>, I want <X> so that <Y>` wrapper. Descriptions are optional; include only what the assignee needs to do the work.

**Why:** invented detail and user-story scaffolding make the issue look complete while leaving the actual task unspecified, and they push product-level decisions down into the task layer where they get re-litigated by whoever picks it up. See `references/linear-method-rules.md` for the source quotes.

**How to apply:** strip everything the assignee does not need. Move product or UX rationale into the project spec or the parent epic. If a description repeats the title, delete the description.
</governing_rule>

<working_method>
1. Collect the source: a paste, a chat description, a bug report, an existing issue ID, or a free-form request. Normalize into one input block before drafting.
2. Classify the input as `feature`, `bug`, `chore`, `spike`, or `not-a-task`. For `not-a-task`, propose the right home (spec doc, comment on a project, placeholder issue) and stop.
3. Run the scope check (`<section name="scope-check">`). If two or more signals fire, ask the user with a structured choice before drafting any title.
4. Draft the title (imperative verb plus one object) and the minimum description. For bugs, populate the bug-issue fields in `<section name="bug-issues">`.
5. Decide the sink (`<section name="sink-and-host">`) and the apply gating (`<section name="dry-run-vs-apply">`). Output the proposal and stop. Apply only after the user says `write`, `apply`, `create`, `update`, `publish`, or `save`.
</working_method>

<section name="title-and-description">
- Title is imperative, names one object, and is scannable in a list view. `Add password reset flow`, not `Password reset` and not `Implement a flow that lets users reset their password if they forget it`.
- No `As a <role>, I want…` and no `So that…`. The rationale belongs in the project spec.
- Description is optional. Include it only when the assignee needs context that the title cannot carry: the route, the file, the endpoint, the failure mode, the acceptance criteria the team has already agreed on. Skip it when the title is enough.
- Do not invent acceptance criteria. If the user did not give them and they are not obvious from the title, omit the section. Inventing criteria is what padded user stories did wrong.
- No marketing voice, no hedging, no consolation clauses. If the description is more than a short paragraph and reads as prose, run it through the `natural-tone` skill first.
</section>

<section name="what-doesnt-belong">
Linear: "if it's not a task, then it doesn't belong in the issue tracker." Route non-tasks to the right home:

- Speculative product idea → spec doc or roadmap entry. Optionally a placeholder issue like `Write project spec for <area>`.
- Open-ended exploration → `Explore <area>` placeholder issue with a time box, not a feature issue.
- UX or design debate → comment on the project, or a `Decide <X> approach` spike issue, not a feature issue.
- Status update or FYI → comment on the relevant issue, not a new issue.
- Bug report from a non-assignee that lacks reproduction → keep as a bug issue, but flag that the assignee should rewrite it as a task once the cause is known.
</section>

<section name="scope-check">
Run before drafting. Full signal list in `references/scope-split-signals.md`. Quick signals:

- More than one imperative verb in the proposed title.
- More than one subsystem, screen, route, or service named.
- Three or more distinct acceptance criteria.
- Estimated effort exceeds one focused day. Linear's sizing guide is hours-to-a-day for fixes and 1–3 weeks for projects; anything in between is usually a project, not an issue.
- Likely to need more than one PR or more than one assignee.
- The description contains `and also`, `plus`, `while we're at it`, `refactor`, or `cleanup`.
- Mixes a bug fix with new feature work.

When two or more signals fire, stop and ask the user with a structured choice:

1. **Keep as one issue** — acknowledge the size in the description and accept the risk.
2. **Split into siblings** — propose 2–5 sibling issues with draft titles, all under the same parent or project.
3. **Promote to a project** — the work is project-sized; draft a project name and 2–5 sub-issue titles.

Do not draft titles or descriptions for the split until the user picks an option.
</section>

<section name="bug-issues">
Bug issues need fields the Linear method article does not spell out. Populate when the input is a bug:

- **Steps to reproduce** — numbered, minimal, runnable by someone other than the reporter.
- **Expected** — what should happen.
- **Actual** — what happens.
- **Environment** — OS, browser, app version, device, account or tenant when relevant.
- **Evidence** — screenshot, video, log excerpt, request ID, or link. Link, do not paste long logs.

Do not write a speculative root cause in the description. `probably a cache issue` and `looks like a race condition` belong in a comment after investigation, not in the body of the issue.

Title pattern: `Fix <observable behavior> <condition>`. Example: `Fix Submit button no-op on slow networks`, not `Submit button bug`.
</section>

<section name="rewrite-user-stories">
Pattern to apply to any `As a <role>, I want <X> so that <Y>`:

1. Extract the concrete change from `<X>`.
2. Restate as an imperative title with one object.
3. Drop `<role>` unless the role changes the implementation (admin vs end user, signed-in vs anonymous). If it does, name the role in the title or description, not as a wrapper.
4. Move `<Y>` (the rationale) into the project spec or omit it. Do not put it in the issue.

See `references/before-after.md` for worked examples covering user stories, vague features, and bug pastes.
</section>

<section name="dry-run-vs-apply">
- Default mode is dry-run. Propose the title, description, and sink; do not write.
- Switch to apply only on an explicit verb: `write`, `apply`, `create`, `update`, `publish`, or `save`.
- Before overwriting the title or description of an existing issue, show the diff and require a second explicit confirmation.
- Never change status, assignee, priority, or parent from this skill. Hand those off to the `linear` skill.
- Never bulk-apply a split. Confirm the split decision first, then apply one issue at a time or in a single batch after the user says `apply all`.
</section>

<section name="sink-and-host">
Two sinks. Detect once per session:

- **Linear sink** — a Linear write tool is available. From Claude Code that is the Linear MCP (`mcp__claude_ai_Linear__save_issue`, `save_comment`, and related tools). From Linear Ask that is the host's native issue write tool. Use whichever the host exposes; do not hardcode the tool name in user-facing output.
- **Filesystem sink** — no Linear write tool is reachable, or the user said `save to disk` or `write to files`. Detect by attempting one read-only Linear call (for example `list_teams`); if it errors or the tool is not present, switch to filesystem mode and say so in the output. See `references/filesystem-fallback.md` for the path scheme and the frontmatter contract.

The apply gating in `<section name="dry-run-vs-apply">` applies to both sinks equally. The filesystem sink is not a free pass to write files without the user asking.
</section>

<section name="output-contract">
Return markdown. No raw JSON, no schema dumps. Cover compactly:

- **Mode**: `dry-run` or `applied`.
- **Sink**: `linear` or `filesystem: <path>`.
- **Classification**: `feature`, `bug`, `chore`, `spike`, or `not-a-task`.
- **Scope decision**: `single-issue`, `split-proposed`, or `split-applied`.
- **Proposed title** (and, for splits, the list of sibling or sub-issue titles).
- **Proposed description** or `(none)`.
- **Proposed team or project** when known; `unset` when not.
- **For filesystem sink**: the file path(s), with the parent–child name scheme visible (`001-…md`, `001.001-…md`).
- **Reasoning**: one or two bullets naming which Linear-method rule shaped the draft (for example, "dropped user-story wrapper", "split because three subsystems named", "description omitted because title is sufficient").

When a structured choice is needed (split decision, sibling selection, parent picking), use the host's question tool. Fall back to one short markdown question if no question tool is available.
</section>

<review_checklist>
- [ ] Title is imperative, names one object, and reads cleanly in a list view.
- [ ] Description is the minimum the assignee needs, or omitted entirely.
- [ ] No `As a <role>, I want…` wrapper anywhere in the output.
- [ ] No invented acceptance criteria.
- [ ] Scope check ran; if two or more signals fired, the user was asked before drafting titles.
- [ ] For bugs: steps, expected, actual, environment, and evidence are present; no speculative cause in the body.
- [ ] Sink is named explicitly (`linear` or `filesystem: <path>`).
- [ ] Mode is `dry-run` unless the user used an explicit apply verb.
- [ ] No status, assignee, priority, or parent changes were made. Those belong to the `linear` skill.
</review_checklist>

<bundled_resources>
- `references/linear-method-rules.md` — quoted source rules from the Linear Method articles, with URLs.
- `references/before-after.md` — worked rewrites for user stories, vague features, and bug pastes.
- `references/filesystem-fallback.md` — on-disk layout, naming scheme, and frontmatter contract.
- `references/scope-split-signals.md` — full signal checklist and the three split modalities.
</bundled_resources>
