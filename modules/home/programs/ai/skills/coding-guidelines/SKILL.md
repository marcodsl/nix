---
name: coding-guidelines
description: "Plan, design, architect, and review software solutions with structured tradeoff analysis across architecture, implementation quality, validation, and performance. Use when: shaping designs, reviewing code or PRs, planning refactors, evaluating implementation strategies, or making major technical decisions."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: architecture, code-review, planning, refactoring, testing
---

# Coding Guidelines

Use this skill for architecture, design, planning, refactoring strategy, and code or PR review when the work needs explicit tradeoffs rather than a tiny direct fix.

## Purpose

Guide a structured discussion before implementation or during review. For each concern or decision, name the problem, compare realistic options, recommend one, and ask the user to confirm before assuming the direction.

## Scope

### Use this skill when

- Planning software with architectural, validation, maintainability, rollout, or performance tradeoffs.
- Designing a boundary, interface, refactor, workflow, or dependency shape.
- Reviewing code, a PR, or a proposal that needs risk-ranked feedback and options.
- Making major technical decisions across modules, teams, services, or user-facing behavior.

### Do not use this skill when

- The task is a small direct fix, formatting pass, or prose-only edit.
- A narrower language, framework, prompt, or domain skill owns the decision.

## Governing rule

Every recommendation must include the concrete concern, 2-3 realistic options, tradeoffs, a preferred option, and a confirmation question.

## Defaults

- Value DRY when duplication creates drift, fragmented ownership, or real maintenance cost.
- Treat validation and testing as required; scale coverage with risk and blast radius.
- Prefer explicit requirements, boundaries, data flow, and error handling over cleverness.
- Handle edge cases, rollout concerns, failure modes, and operational risk before polish.
- Avoid fragile shortcuts and avoid abstractions that do not remove real complexity.

## Start

- Infer or ask for task type: Planning, Design, Architecture, or Review.
- Infer or ask for depth: BIG CHANGE for staged interactive review; SMALL CHANGE for one focused question per stage.
- Ask about timeline, scope, and scale when those priorities would change the recommendation.
- If the user already gave these details, state the mode and proceed.

## Workflow

Work in this order and pause after each meaningful section for feedback:

1. Architecture and system design: boundaries, coupling, data flow, scalability, single points of failure, auth/security boundaries, requirements clarity, and assumptions.
2. Implementation quality: organization, duplication, edge cases, error handling, technical debt, over/under-engineering, readability, and maintainability.
3. Validation and test strategy: acceptance criteria, unit/integration/e2e coverage, assertion strength, failure paths, rollback paths, and test scope vs risk.
4. Performance and scalability: N+1 access, memory usage, caching, complexity, capacity limits, and whether the risk is worth fixing now.

## Concern Format

For each concern or decision point:

- Lead with the highest-risk issues first; defer minor nits.
- Reference files, lines, requirements, or subsystems when available.
- Present the recommended option first, then alternatives including "do nothing" when reasonable.
- For each option, state effort, risk, impact on other code, and maintenance burden.
- Label items so the user can answer unambiguously, for example `Issue 2, Option A`.
- Ask whether the user agrees or wants a different path before moving to the next stage.

## Verification checklist

- [ ] Established task type, depth, scope, timeline, and scale when they matter.
- [ ] Covered architecture, implementation quality, validation, and performance in order.
- [ ] For each major concern, included problem, options, tradeoffs, recommendation, and confirmation.
- [ ] Ranked risks before minor issues and tied recommendations to the user's priorities.
