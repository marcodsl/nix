---
name: context-map
description: "Create a reviewable map of the files, dependencies, tests, and reference patterns that matter to a task before implementation. Use when: scoping a change, locating the owning code path, estimating blast radius, or proving the edit surface is understood."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [discovery, scoping, dependencies, tests]
---

# Context Map

## Purpose

Use this skill to map the smallest complete set of files that matter to a task before editing. The goal is not broad repo exploration; it is to identify the owning implementation surface, the likely blast radius, the relevant tests, and the best existing patterns to follow so the next change starts from evidence instead of guesswork.

## Scope

### Use this skill when

- A task names a behavior, feature, or bug but not the exact file to change.
- You need to identify the owning implementation path before editing.
- You are scoping a refactor, bug fix, feature, or review and need to understand blast radius.
- You want a concise, reviewable inventory of code, tests, and neighboring patterns before implementation.

### Do not use this skill when

- The user already identified the exact file, symbol, and local edit surface, and no broader dependency map is needed.
- The task is purely mechanical, such as a wording fix or a one-line change with an obvious owner.
- The task is architectural decision-making or tradeoff analysis. Use `coding-guidelines` for that.

## Governing rule

Map only the files that materially affect the task, and make every inclusion falsifiable: each file should earn its place by owning behavior, constraining the change, validating it, or serving as a concrete pattern to follow.

## Operating rules

1. Start with deterministic discovery: search, file listings, symbol lookups, and nearby reads before inferring relationships.
2. Prefer the owning code path over broad inventories. Stop expanding once you can name the direct edit surface and its immediate blast radius.
3. Include evidence for every file. If you cannot explain why a file matters, leave it out.
4. Separate confirmed relationships from likely ones. Mark inferred edges with explicit uncertainty.
5. Prefer direct dependencies, validation surfaces, and concrete reference patterns over transitive or framework-noise files.
6. Share the map before implementation unless the user explicitly asked for direct execution.

## Task

{{task_description}}

## Workflow

1. Restate the task in one sentence and extract 2 to 6 concrete search anchors such as symbols, config keys, commands, feature names, or error text.
2. Search for candidate files related to those anchors.
3. Group findings by role:
   - `Files to Modify`: code or config that directly computes, mutates, registers, or decides the behavior.
   - `Dependencies`: callers, consumers, imports, module includes, config edges, or schemas that constrain the change.
   - `Tests and Validation`: tests, fixtures, snapshots, or commands that validate the affected behavior.
   - `Reference Patterns`: nearby implementations worth mirroring for consistency.
4. Read the minimum local context needed to confirm each file's role.
5. Trim the set until it is actionable. Keep the smallest map that would let someone make the next change safely.
6. Record risks, unknowns, and the most likely first edit surface.

## Inclusion tests

Include a file only when at least one of these is true:

- It directly owns the behavior or configuration being changed.
- It constrains the change through a call site, import, schema, interface, option, or registration edge.
- It provides the best existing validation surface for the task.
- It is the closest trustworthy pattern to follow.

Exclude these cases unless the task specifically requires them:

- Broad framework or bootstrap files that only happen to sit on the path.
- Generated files, lockfiles, vendored assets, or build outputs.
- Transitive dependencies that do not materially change implementation or validation decisions.
- "Maybe relevant" files with no concrete evidence.

## Instructions

1. Search the codebase for files related to the task using concrete anchors, not broad topic words.
2. Identify the direct dependency edges that matter, including imports and exports when relevant, but also registrations, config references, command entrypoints, or module wiring when the codebase does not use import-based boundaries.
3. Find the narrowest existing tests or validation commands that would prove the mapped behavior.
4. Look for similar patterns in existing code and prefer nearby, currently used examples over abstract style guidance.
5. State uncertainty plainly when ownership or blast radius is not fully confirmed.
6. End with the proposed primary edit target and the first validation step.

## Output Format

```markdown
## Context Map

Task: <one-sentence restatement>
Confidence: high | medium | low

### Files to Modify

| File         | Why It Matters | Expected Change  |
| ------------ | -------------- | ---------------- |
| path/to/file | owns behavior  | what will change |

### Dependencies and Adjacent Surfaces

| File        | Relationship | Confidence |
| ----------- | ------------ | ---------- |
| path/to/dep | constrains X | confirmed  |

### Tests and Validation

| File or Command | Coverage                    | Gap                 |
| --------------- | --------------------------- | ------------------- |
| path/to/test    | validates affected behavior | missing edge case Y |

### Reference Patterns

| File            | Pattern to Mirror | Why It Applies   |
| --------------- | ----------------- | ---------------- |
| path/to/similar | example to follow | same abstraction |

### Risks and Unknowns

- Risk: <breaking API, migration, rollout, config, or validation risk>
- Unknown: <what is still unconfirmed>

### Proposed Next Step

- Primary owner: <file or symbol>
- First validation: <test, command, or check>
```

## Verification checklist

- [ ] Started from concrete search anchors derived from the task.
- [ ] Identified the primary owning file or explicitly named the ambiguity.
- [ ] Included only files with a concrete role in implementation, dependency, validation, or reference patterns.
- [ ] Marked uncertain relationships instead of presenting them as facts.
- [ ] Named the first likely edit surface and the first validation step.
- [ ] Shared the map before implementation unless the user explicitly asked for direct execution.
