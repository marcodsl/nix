---
name: coding-guidelines
description: "Plan, design, architect, and review software solutions with structured tradeoff analysis across architecture, implementation quality, validation, and performance. Use when: shaping designs, reviewing code or PRs, planning refactors, evaluating implementation strategies, or making major technical decisions."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [architecture, code-review, planning, refactoring, testing]
---

# Coding Guidelines

## Purpose

Use this skill to plan, design, architect, or review software solutions in a structured, interactive way. Use it before code exists, while a design is taking shape, or when reviewing an implementation that already exists. For every concern, decision point, or recommendation, explain the concrete tradeoffs, give an opinionated recommendation, and ask for user input before assuming a direction.

## Scope

### Use this skill when

- Planning a software solution that has meaningful architectural, validation, maintainability, or performance tradeoffs.
- Designing an implementation, system boundary, interface, refactor, or rollout strategy before committing to a direction.
- Architecting a system or subsystem and pressure-testing decisions around coupling, data flow, failure modes, scalability, and operability.
- Reviewing code, a PR, or a proposal that needs structured feedback with risks, options, and recommendations.

### Do not use this skill when

- The task only needs a quick style, formatting, or prose pass.
- The task is a narrow single-domain audit that does not need cross-cutting tradeoff analysis.
- The user already asked for a tiny, direct fix and does not want an interactive planning, design, or review workflow.

## Governing rule

For every concern or decision point, name the concrete problem or choice, compare realistic options, recommend the option that best fits the user's priorities, and ask the user to confirm the direction before you move on.

## Default engineering preferences

Use these defaults unless the user gives different priorities:

- Value DRY. Flag repetition aggressively when it increases maintenance cost, drifts behavior, or fragments responsibility.
- Treat strong validation and testing as non-negotiable. Prefer too much coverage over too little.
- Aim for solutions that are engineered enough: avoid fragile shortcuts and avoid premature abstraction.
- Handle edge cases thoughtfully. Bias toward covering failure modes, rollout concerns, and operational risks instead of assuming the happy path.
- Prefer explicit requirements, boundaries, interfaces, data flow, and error handling over cleverness.

## Before you start

1. Ask about timeline, scope, and scale priorities before making assumptions, unless the user already provided them.
2. Ask what kind of task this is, unless the user already made it clear:
   - **Planning**: shape a solution before implementation begins.
   - **Design**: evaluate interfaces, workflows, dependencies, and implementation approach.
   - **Architecture**: evaluate system boundaries, responsibility splits, data flow, and scaling strategy.
   - **Review**: inspect an existing design, PR, or code change.
3. Ask which depth the user wants, unless they already chose one:
   - **BIG CHANGE**: Work through the discussion interactively, one section at a time, with at most 4 top concerns in each section.
   - **SMALL CHANGE**: Work through the discussion interactively with one focused question per section.
4. If the user already set the task type, depth, scope, or urgency, follow that guidance and state the mode you are using.

## Workflow

- Start from the user's task type: Planning, Design, Architecture, or Review.
- Work through the discussion in this order: Architecture and system design -> Implementation quality -> Validation and test strategy -> Performance and scalability.
- After each section, pause and ask for feedback before moving on.
- If a section is in good shape, say so briefly, note any residual risk, and ask whether the user wants a deeper pass before continuing.
- Keep the discussion focused on the most important concerns for the selected mode. Do not exhaustively list minor nits before surfacing major risks.
- If no code exists yet, evaluate requirements, boundaries, interfaces, dependencies, failure modes, rollout risks, and validation strategy instead of inventing implementation details.

## 1. Architecture and system design

Evaluate:

- Overall system design and component boundaries.
- Dependency graph and coupling concerns.
- Data flow patterns and potential bottlenecks.
- Scaling characteristics and single points of failure.
- Security architecture (auth, data access, API boundaries).
- Whether the design matches the stated scope, timeline, and maintenance expectations.
- Requirements clarity, interface boundaries, and assumptions that could invalidate the design.

## 2. Implementation quality

Evaluate:

- Code organization, module structure, or the planned implementation shape if code does not exist yet.
- DRY violations. Be aggressive when duplication creates maintenance burden or inconsistent behavior.
- Error handling patterns and missing edge cases (call these out explicitly).
- Technical debt hotspots.
- Areas that are over-engineered or under-engineered relative to the preferences above.
- Places where cleverness hides intent, control flow, or operational risk.
- Whether the proposed implementation approach is understandable, maintainable, and realistic for the team.

## 3. Validation and test strategy

Evaluate:

- Validation gaps before implementation, including unclear acceptance criteria and missing failure-mode coverage.
- Test coverage gaps (unit, integration, e2e) when code or test plans already exist.
- Test quality and assertion strength when tests already exist.
- Missing edge case coverage. Be thorough.
- Untested failure modes, rollback paths, and error paths.
- Whether the validation strategy matches the risk of the change and the stability requirements of the system.

## 4. Performance and scalability

Evaluate:

- N+1 queries and database access patterns.
- Memory-usage concerns.
- Caching opportunities.
- Slow or high-complexity code paths.
- Capacity limits, scalability assumptions, and likely bottlenecks before implementation.
- Whether performance risks are real, likely, and worth fixing now relative to product and maintenance goals.

## For each concern or decision point

For every specific concern, defect, design choice, or risk:

- Describe the concern concretely, with file and line references when available, or with explicit references to the requirement, design choice, or subsystem being discussed.
- Present 2 to 3 options, including "do nothing" where that is reasonable.
- For each option, specify implementation effort, risk, impact on other code, and maintenance burden.
- Put the recommended option first. Explain why it best fits the user's priorities or the default review preferences above.
- Then explicitly ask whether the user agrees or wants to choose a different direction before proceeding.

## For each stage

- Explain the stage clearly before listing issues or questions.
- Number issues and use letters for options so the user can respond unambiguously.
- Label options clearly, for example `Issue 2, Option A`.
- Include concrete pros and cons for each option, not generic summaries.
- Place the recommended option first.
- If the task is planning, design, or architecture, frame items as decision points or risks instead of pretending there is already code to review.
- Ask for feedback before you move to the next section.

## Verification checklist

- [ ] Asked about timeline, scope, and scale priorities unless the user already provided them.
- [ ] Confirmed or inferred the task type and depth before starting.
- [ ] Covered architecture, implementation quality, validation, and performance in order.
- [ ] For each concern or decision point, included the problem, options, tradeoffs, a recommendation, and a request for user input.
- [ ] Paused after each section for feedback.
- [ ] Mapped recommendations to the user's priorities or the default review preferences.
