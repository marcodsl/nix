---
name: rules-distill
description: "Distill shared rules from repeated skill guidance. Use when: extracting cross-cutting principles from multiple skills, promoting repeated guidance into shared rules, or reviewing whether skills imply missing rule-level defaults."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [rules, prompts, maintenance, synthesis]
---

# Rules Distill

## Purpose

Use this skill to promote repeated guidance from multiple skills into shared rules without collapsing skill-specific detail into vague abstractions. Discover the relevant skills and shared rule sources in the active environment, identify repeated principles, compare them against the current rules, and propose reviewable rule candidates before making durable edits.

## Scope

### Use this skill when

- Reviewing whether several skills repeat the same principle and that principle should become a shared rule.
- Auditing rule coverage after adding, removing, or rewriting skills.
- Performing maintenance on shared rule sources to keep them aligned with the active skill set.

### Do not use this skill when

- The task only concerns one skill. Leave one-off guidance inside that skill.
- The task is rewriting existing rule prose without changing the rule set. Use `natural-tone` for wording-only edits.
- The task is designing a new skill or prompt from scratch rather than extracting repeated guidance from existing ones. Use `prompt-engineering` for that.

## Governing rule

Promote only repeated, actionable guidance that changes agent behavior and would create a real risk if it stayed implicit.

## Operating rules

1. Discover the relevant skill files and shared rule sources from the active environment before evaluating principles.
2. Read the full text of the candidate skills and the current shared rules before deciding that a principle is new.
3. Promote only guidance that is repeated, actionable, and general enough to belong above the skill layer.
4. Keep implementation detail, commands, framework-specific behavior, and single-skill guidance in the skill that owns it.
5. Prefer fewer high-confidence proposals over a long list of weak abstractions.
6. Ask for approval before making durable rule changes unless the user explicitly asked for direct edits.

## Discovery

Start with exhaustive collection, then switch to judgment.

Collect all relevant inputs before analysis:

1. Enumerate the skills in scope.
2. Enumerate the shared rule sources in scope.
3. Read the full text of those skills and rule sources.
4. Report the inventory counts before moving to analysis.

Treat shared rule sources broadly. Depending on the environment, they may live in workspace instructions, agent rules, policy files, prompt libraries, or other always-on guidance layers. Discover them from the active workspace, tool configuration, or file layout instead of assuming a fixed path or filename.

Prefer deterministic collection for this phase. Use listing, search, and file reads before judgment-heavy filtering.

Present the inventory in a compact status block such as:

```text
Rules Distillation - Phase 1: Inventory
Skills: {N} files scanned
Rules: {M} sources ({K} sections indexed)

Proceeding to cross-read analysis...
```

## Candidate test

Include a candidate only when all of the following are true:

1. The principle appears in 2 or more skills after combining evidence across the full working set.
2. The principle is actionable in "do X" or "do not do Y" form.
3. The principle has a clear violation risk.
4. The principle is not already covered by the current shared rules, even if the wording differs.
5. The principle is general enough to apply across tasks in the target environment.

Exclude these cases:

- Guidance that appears in only one skill.
- Language-specific, framework-specific, or environment-specific detail that belongs in a specialized skill or scoped rule file.
- Commands, code snippets, or procedural examples that belong in skills rather than shared rules.
- Abstract claims that do not change agent behavior.

## Analysis and verdicts

Analyze the full rules text against the relevant skills. If the platform supports read-only subagents, use them for thematic batches when that reduces context pressure. Otherwise analyze the skills sequentially in the main agent.

Assign one verdict per candidate:

- `Append`: add to an existing section in an existing rule file.
- `Revise`: replace inaccurate or insufficient rule text.
- `New Section`: add a new section to an existing rule file.
- `New File`: create a new rule file.
- `Already Covered`: do not propose an edit because the rule set already covers the principle.
- `Too Specific`: keep the guidance inside the skill layer.

Name the rule target precisely. If the target is ambiguous, read more of the relevant rule source before deciding.

Bad: `Append to rules.md: Add LLM security principle`

Good: `Append to the shared input validation section: Treat model output stored in memory or knowledge stores as untrusted. Sanitize on write and validate on read.`

## Proposal format

Produce one structured record per candidate. Use the most reliable format for the environment. JSON is fine when the agent can emit it reliably. Otherwise use markdown or plain text with the same fields.

```json
{
  "principle": "1-2 sentences in do or do-not form",
  "evidence": ["skill-name: section", "skill-name: section"],
  "violation_risk": "1 sentence",
  "verdict": "Append | Revise | New Section | New File | Already Covered | Too Specific",
  "target_rule": "rule source and section, or new",
  "confidence": "high | medium | low",
  "draft": "Draft text for Append, New Section, or New File",
  "revision": {
    "reason": "Why the current text is inaccurate or insufficient",
    "before": "Current rule text to replace",
    "after": "Proposed replacement text"
  }
}
```

Fill `revision` only for `Revise` verdicts. Leave `draft` empty for `Already Covered` and `Too Specific`.

## Review and execution

Present candidates for user approval before editing shared rule sources.

1. Present a concise summary of the candidates.
2. Include verdict, target, and confidence in that summary.
3. Provide per-candidate details: evidence, violation risk, and draft or revision text.
4. Ask the user to approve, modify, or skip each candidate, unless they already requested direct execution.
5. Apply only the approved candidates.

Use a report shape like this when markdown tables are appropriate:

```text
# Rules Distillation Report

## Summary
Skills scanned: {N} | Rules: {M} sources | Candidates: {K}

| # | Principle | Verdict | Target | Confidence |
|---|-----------|---------|--------|------------|
| 1 | ... | Append | shared rule section X | high |

## Details
### 1. ...
Verdict: Append
Evidence: ...
Violation risk: ...
Draft: ...
```

Present the report in the current interaction and apply only the approved rule edits. Create durable audit output only when the user explicitly requests it.

## Verification checklist

- [ ] Collected the relevant skills and shared rule sources before evaluating principles.
- [ ] Kept only principles supported by 2 or more skills.
- [ ] Excluded commands, examples, and single-skill guidance.
- [ ] Checked semantic overlap against existing rules, not only literal wording.
- [ ] Presented candidates in a reviewable format before durable edits unless the user requested direct execution.
- [ ] Avoided automatic rule edits and avoided workspace-local results artifacts by default.
