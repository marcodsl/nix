---
name: coding-guidelines
description: "Plan, design, architect, and review software solutions with structured tradeoff analysis across architecture, implementation quality, validation, and performance. Use when: shaping designs, reviewing code or PRs, planning refactors, evaluating implementation strategies, or picking between two or more approaches. Skip for trivial typo/rename/format edits, pure prose, or when a narrower skill (brainstorming, pressure-test, refactor-planning, react-guidelines, nextjs, frontend-design, dockerfile) owns the task."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: architecture, code-review, planning, refactoring, testing, design
---

# Coding Guidelines

<purpose>
Default workflow for guiding code review, design, and engineering decisions. For each concern, surface the concrete problem, compare 2-3 realistic options with tradeoffs, recommend one, and ask the user to confirm before moving on. No silent picks. Use this as the routine review and design lens, not only for "major" decisions.
</purpose>

<scope>
  <use-when>
    - Reviewing code, a PR, a diff, or a snippet the user is asking feedback on.
    - Designing or architecting a feature, module, boundary, interface, refactor, workflow, or dependency.
    - Choosing between two or more implementation approaches.
    - Evaluating validation, testing, error handling, performance, or rollout tradeoffs before writing code.
    - Making any technical decision that benefits from explicit options and recommended direction.
  </use-when>

  <do-not-use-when>
    - The task is a small direct fix, typo, rename, formatting pass, or prose-only edit.
    - The user is brainstorming options without a frame yet — use `brainstorming`.
    - The user already has a plan and wants it pressure-tested via interview-style probing — use `pressure-test`.
    - The user needs a step-by-step refactor execution plan or RFC — use `refactor-planning`.
    - A narrower language, framework, or domain skill clearly owns the decision (e.g., `react-guidelines`, `nextjs`, `frontend-design`, `dockerfile`).
  </do-not-use-when>
</scope>

<defaults>
  - Value DRY when duplication creates drift, fragmented ownership, or real maintenance cost.
  - Treat validation and testing as required; scale coverage with risk and blast radius.
  - Prefer explicit requirements, boundaries, data flow, and error handling over cleverness.
  - Handle edge cases, rollout concerns, failure modes, and operational risk before polish.
  - Avoid fragile shortcuts and avoid abstractions that do not remove real complexity.
</defaults>

<start>
  - Infer or ask for task type: Planning, Design, Architecture, or Review.
  - Infer or ask for depth: BIG CHANGE for staged interactive review; SMALL CHANGE for one focused question per stage.
  - Ask about timeline, scope, and scale when those priorities would change the recommendation.
  - If the user already gave these details, state the mode and proceed.
</start>

<workflow>
Work in this order and pause after each meaningful section for feedback:

  <stage id="1" name="architecture-and-system-design">
    Boundaries, coupling, data flow, scalability, single points of failure, auth and security boundaries, requirements clarity, assumptions.
  </stage>

  <stage id="2" name="implementation-quality">
    Organization, duplication, edge cases, error handling, technical debt, over- or under-engineering, readability, maintainability.
  </stage>

  <stage id="3" name="validation-and-test-strategy">
    Acceptance criteria, unit/integration/e2e coverage, assertion strength, failure paths, rollback paths, test scope vs risk.
  </stage>

  <stage id="4" name="performance-and-scalability">
    N+1 access, memory usage, caching, complexity, capacity limits, whether the risk is worth fixing now.
  </stage>
</workflow>

<concern-format>
For each concern or decision point:

  - Lead with the highest-risk issues first; defer minor nits.
  - Reference files, lines, requirements, or subsystems when available.
  - Present the recommended option first, then alternatives including "do nothing" when reasonable.
  - For each option, state effort, risk, impact on other code, and maintenance burden.
  - Label items so the user can answer unambiguously, for example `Issue 2, Option A`.
  - Ask whether the user agrees or wants a different path before moving to the next stage.
</concern-format>

<verification-checklist>
  - [ ] Established task type, depth, scope, timeline, and scale when they matter.
  - [ ] Covered architecture, implementation quality, validation, and performance in order.
  - [ ] For each major concern, included problem, options, tradeoffs, recommendation, and confirmation.
  - [ ] Ranked risks before minor issues and tied recommendations to the user's priorities.
</verification-checklist>
