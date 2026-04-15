---
name: refactor-planning
description: "Plan incremental refactors with structured discovery, scope control, testing decisions, and safe step-by-step decomposition. Use when a refactor needs a concrete execution plan, an RFC-style decision record, or a breakdown into tiny working commits."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [planning, refactoring, incremental-change]
---

# Refactor Planning

Rules for planning refactors that need careful scope control, explicit tradeoffs, and a sequence of small working steps.

## Purpose

Use this skill to turn a vague or risky refactor request into a concrete execution plan. The outcome should be a plan the user can review, challenge, and implement incrementally without losing track of scope, test strategy, or rollback safety.

## Scope

### Use this skill when

- The user wants to plan a refactor before implementation starts.
- The change is large enough that scope, sequencing, or validation needs to be made explicit.
- The user wants an RFC-style artifact that captures the problem, solution, decisions, and rollout plan.
- The work should be broken into tiny commits or small safe steps that keep the codebase working throughout the refactor.

### Do not use this skill when

- The task is a small direct code change that does not need a planning artifact.
- The user wants a broad architecture or implementation review rather than a refactor execution plan. Use `coding-guidelines` for that.
- The task is pressure-testing an existing proposal one concern at a time. Use `pressure-test` for that.
- The task is mostly about rewriting prose or tightening wording. Use `natural-tone` for that.

## Governing rule

Reduce uncertainty before you reduce code complexity. Verify the current state, define the intended end state, and break the path between them into the smallest practical working increments.

## Discovery and repo verification

Start by understanding the user's problem in their own terms, then verify the important claims against the repo.

- Ask for a detailed description of the problem, the motivation for the refactor, known pain points, and any ideas the user already has.
- Clarify constraints early: deadlines, compatibility requirements, rollout risk, migration limits, ownership boundaries, and what must keep working during the transition.
- Explore the codebase to confirm the relevant behavior, dependencies, coupling points, and existing design constraints.
- Summarize the current state back to the user in concrete terms before planning the refactor itself.

Verify the user's framing against the repo before planning. Call out gaps when the repo contradicts an assumption.

## Alternatives and tradeoffs

Refactor plans are often wrong because the first solution becomes the default too early.

- Ask whether the user has considered other approaches.
- Present realistic alternatives, including smaller fixes, partial refactors, or leaving parts of the current design in place.
- For each serious option, explain the tradeoff in effort, risk, maintenance burden, and expected payoff.
- If one option is clearly better, recommend it and explain why.

Compare only the options that would actually be reasonable in this codebase.

## Scope and exclusions

Before you write the step-by-step plan, define the boundary of the change.

- Work with the user to name what will change and what will not change.
- Separate required work from adjacent cleanup, nice-to-have improvements, and follow-up ideas.
- Record explicit in-scope and out-of-scope items.
- Call out assumptions that could invalidate the plan if they turn out to be wrong.

Prefer a narrow plan with a clean follow-up over a sprawling plan that mixes refactoring with unrelated redesign.

## Testing and validation planning

Refactor safety depends on validation, not optimism.

- Check the current test coverage around the affected behavior, not just the touched modules.
- Identify missing coverage that would make the refactor unsafe or hard to stage incrementally.
- Ask the user what level of testing is expected if the current coverage is weak.
- Describe what a good test should verify for this refactor: external behavior, invariants, failure modes, and migration safety where relevant.
- Note prior art in the repo when similar tests already exist.

If the area has poor coverage, say so directly and factor that into the plan instead of assuming tests will appear later.

## Incremental decomposition

Break the work into the smallest practical sequence of changes that keeps the system working.

- Prefer preparatory steps that create safety rails before structural changes.
- Separate behavior-preserving refactors from behavior changes.
- Each planned step should leave the codebase in a working state with a clear reason for existing.
- Use tiny commits when that reduces risk, improves reviewability, or makes rollback easier.
- State dependencies between steps when order matters.

Martin Fowler's advice applies here: make each refactoring step as small as possible so the program stays understandable and working throughout the change.

## Output contract

When you present the final plan, structure it as a durable planning artifact with the following sections:

1. `Problem Statement`
2. `Solution`
3. `Commits`
4. `Decision Document`
5. `Testing Decisions`
6. `Out of Scope`
7. `Further Notes` (optional)

For each section:

- `Problem Statement`: describe the problem from the developer's perspective.
- `Solution`: describe the proposed direction and why it addresses the problem.
- `Commits`: give a detailed step-by-step implementation plan in plain English. Break it into the smallest practical working increments.
- `Decision Document`: record key implementation decisions, such as modules or subsystems affected, interfaces that will change, technical clarifications, architectural choices, schema changes, API contracts, and notable interactions.
- `Testing Decisions`: describe what good tests should cover, which areas need validation, and any similar tests already present in the codebase.
- `Out of Scope`: state what this refactor will not change.
- `Further Notes`: include follow-up concerns, sequencing caveats, or unresolved questions if they matter.

Keep the plan artifact durable by using stable references (module names, interface descriptions) instead of volatile file paths, line numbers, or code snippets. Add implementation-level detail only when the user explicitly asks for an appendix.

## Delivery guidance

If the user wants the plan captured as a GitHub issue, convert the final artifact into an issue body after the plan is complete and reviewed. Create a GitHub issue only when the user asks for it.

## Verification checklist

- [ ] Gathered a detailed problem statement and clarified the main constraints.
- [ ] Verified the important repo facts instead of relying only on the user's initial framing.
- [ ] Considered realistic alternatives and explained their tradeoffs.
- [ ] Defined explicit in-scope and out-of-scope boundaries.
- [ ] Evaluated current test coverage and documented the validation strategy.
- [ ] Broke the implementation into small working steps with clear sequencing.
- [ ] Produced the plan in the required output structure.
- [ ] Kept the artifact durable by avoiding volatile implementation references unless requested.
