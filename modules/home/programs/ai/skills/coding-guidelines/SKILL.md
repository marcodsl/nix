---
name: coding-guidelines
description: "Plan, design, or review software changes with structured tradeoff analysis across architecture, implementation quality, validation, and performance, surfacing 2-3 options per concern with explicit recommendation. Triggers: 'review this code', 'PR review', 'how should I design', 'compare these approaches', 'is this approach OK', evaluating two or more realistic implementation strategies, or any non-trivial decision. Skip for typo/rename/format edits or pure prose."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: architecture, code-review, planning, refactoring, testing, design
  version: 3
---

# Coding Guidelines

<purpose>
Default workflow for code review, design, and engineering decisions. For each concern, surface the concrete problem, compare 2-3 realistic options with tradeoffs, recommend one, and ask the user to confirm before moving on. No silent picks.
</purpose>

<scope>
  <use_when>
  - Reviewing code, a PR, a diff, or a snippet the user wants feedback on.
  - Designing or architecting a feature, module, boundary, interface, refactor, workflow, or dependency.
  - Choosing between two or more implementation approaches.
  - Evaluating validation, testing, error handling, performance, or rollout tradeoffs before writing code.
  - Any technical decision that benefits from explicit options and a recommended direction.
  </use_when>

  <do_not_use_when>
  - Small direct fixes, typos, renames, formatting, or prose-only edits.
  </do_not_use_when>
</scope>

<governing_rule>
Lead with the highest-risk issue first. Recommend one option, present 2-3 alternatives including "do nothing" when reasonable, and pause for the user to confirm before moving to the next concern.
</governing_rule>

<working_method>
1. Infer or ask for task type (Planning, Design, Architecture, Review) and depth (BIG CHANGE for staged interactive review; SMALL CHANGE for one focused question per stage).
2. Ask about timeline, scope, and scale only when those priorities would change the recommendation.
3. Walk the four stages in order: architecture, implementation quality, validation, performance.
4. Pause after each meaningful section for feedback before continuing.
</working_method>

<section name="defaults">
- Value DRY when duplication creates drift, fragmented ownership, or real maintenance cost.
- Treat validation and testing as required; scale coverage with risk and blast radius.
- Prefer explicit requirements, boundaries, data flow, and error handling over cleverness.
- Handle edge cases, rollout concerns, failure modes, and operational risk before polish.
- Avoid fragile shortcuts and avoid abstractions that do not remove real complexity.
</section>

<section name="stages">
1. Architecture and system design: boundaries, coupling, data flow, scalability, single points of failure, auth and security boundaries, requirements clarity, assumptions.
2. Implementation quality: organization, duplication, edge cases, error handling, technical debt, over- or under-engineering, readability, maintainability.
3. Validation and test strategy: acceptance criteria; unit, integration, and e2e coverage; assertion strength; failure paths; rollback paths; test scope vs risk.
4. Performance and scalability: N+1 access, memory usage, caching, complexity, capacity limits, whether the risk is worth fixing now.
</section>

<section name="per-concern-format">
For each concern or decision point:
- Lead with the highest-risk issues; defer minor nits.
- Reference files, lines, requirements, or subsystems when available.
- Present the recommended option first, then alternatives including "do nothing" when reasonable.
- For each option, state effort, risk, impact on other code, and maintenance burden.
- Label items so the user can answer unambiguously, for example `Issue 2, Option A`.
- Ask whether the user agrees or wants a different path before moving to the next stage.
</section>

<review_checklist>
- Established task type, depth, scope, timeline, and scale when they matter.
- Covered architecture, implementation quality, validation, and performance in order.
- For each major concern: stated problem, options, tradeoffs, recommendation, asked for confirmation.
- Ranked risks before minor issues and tied recommendations to the user's priorities.
</review_checklist>
