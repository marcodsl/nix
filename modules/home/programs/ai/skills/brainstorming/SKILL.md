---
name: brainstorming
description: "Generate and compare software-engineering ideas before converging on a direction. Use when: brainstorming, ideation, exploring alternatives, or widening the option space before design or planning."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: brainstorming, ideation, software-engineering, design
---

# Brainstorming

## Purpose

Use this skill to turn a vague software-engineering problem into a short set of concrete options worth evaluating. Start wide enough to find real alternatives, then narrow far enough that the next step is obvious.

## Scope

### Use this skill when

- The user wants to explore options before committing to a design, approach, or plan.
- The task needs multiple plausible approaches instead of immediate convergence on the first idea.
- The user wants help generating alternatives, hybrids, tradeoffs, or next steps for a software-engineering decision.
- Shared understanding matters, but the task is still too early for a detailed execution artifact.

### Do not use this skill when

- The user already chose a direction and wants a structured challenge of that choice. Use `pressure-test` for that.
- The task needs a full tradeoff review across architecture, validation, performance, or operational risk. Use `coding-guidelines` for that.
- The user wants a step-by-step execution, refactor, or rollout artifact. Use `refactor-planning` for that.
- The task is casual free association with no need to organize or compare ideas.

## Governing rule

Generate a real spread of options before you recommend one. Every serious option must solve the stated problem, expose a distinct tradeoff, and leave the user with a clear next move.

## Operating rules

1. Clarify the goal, constraints, and success condition before generating options.
2. Start with breadth. Keep the space open until you have genuinely different options.
3. Keep options concrete. Name the mechanism, the expected benefit, and the main cost.
4. Prefer distinct options over minor variations of the same approach.
5. When the user explicitly asks for wider ideation, stay in exploration mode longer before ranking or narrowing.
6. When two weak options combine into a stronger one, propose the hybrid explicitly.
7. Converge before you stop unless the user asked to keep the space wide. End with ranked leading options or an explicitly open set.
8. End with a recommended next step. Mention a specific follow-on workflow only when the environment provides one and it helps.

## Modes

Use one of these modes based on the user's request.

- `Focused mode`: generate a manageable option set, compare it, and narrow to the strongest candidates.
- `Wide mode`: keep the option space broader for longer, explore more axes, and defer ranking until the user is ready.

If the user does not specify a mode, default to focused mode.

## Workflow

### 1. Frame the problem

Start by making the problem sharp enough to brainstorm well. Guard against the **"X-Y Problem"**: engineers frequently ask for help with a specific solution ("Y") when they should be solving an underlying problem ("X").

- Analyze the stated problem. If the premise seems misaligned with standard engineering practices, explicitly and respectfully challenge it.
- Name the actor, the system boundary, and the decision to make.
- Ask for missing constraints only when they change the option set in a material way.
- State the success condition in concrete terms.
- If the available context can answer a factual question quickly, inspect it instead of asking.

Keep this stage short. The goal is to create a stable frame for the options, not to pressure-test the design yet.

### 2. Generate a wide option set

Produce a small set of genuinely different approaches. To prevent defaulting to minor variants of the same standard architecture, apply specific "Lenses" to force diverse thinking.

- **Lenses for forced diversity**: actively explore extremes like "The Simplest/Dumbest Way", "The Infinite Scale Way", or "The No-Code/Process Way".
- In focused mode, aim for a manageable set of distinct options.
- In wide mode, expand the set only when the added options introduce a genuinely new angle.
- Include the obvious baseline when it is realistic, including "do nothing" if that is a serious option.
- Vary the dimension of change: system design, interface shape, ownership split, process, tooling, or scope reduction.
- If all options look similar, say so and widen a different axis instead of pretending there is diversity.

Each option should answer three questions:

1. What changes?
2. Why might this work well here?
3. What cost, risk, or limitation comes with it?

### 3. Force contrast

Compare options directly instead of presenting them as parallel summaries.

- Call out the main dimension that separates each option from the others.
- Note where one option is cheaper, safer, faster to try, easier to operate, or easier to maintain.
- Collapse near-duplicates into one stronger option.
- If a hybrid is stronger than the originals, describe it as a first-class candidate instead of a side note.

This step matters because brainstorming fails when every option sounds equally plausible.

### 4. Narrow to the strongest candidates

In focused mode, reduce the set to the few options that deserve deeper review. In wide mode, narrow only when the user asks to converge or when the weaker options are clearly redundant.

- Eliminate options that fail the stated constraints.
- Eliminate options that duplicate a stronger candidate.
- Prefer options with a clear path to evaluation over vague promise.
- Recommend one leading option when the tradeoff is already clear.

If the tradeoff is still under-specified, say what information would change the ranking.

### 5. Hand off cleanly

Finish with a clear next move instead of another brainstorming round by default.

- If one candidate stands out, recommend it and say why.
- If the choice needs deeper challenge, recommend a structured review or challenge workflow next.
- If the choice needs broader tradeoff analysis, recommend a fuller design review next.
- If the choice is made and execution planning is next, recommend a planning workflow next.

## Conversational workflow

Use a multi-turn, phase-based pacing to facilitate a discussion:

1. **Phase 1: Problem Frame**
   - Present the `Problem Frame` (state the decision, constraints, and success condition).
   - Pause and ask the user for feedback or confirmation before generating options.
2. **Phase 2: Option Generation**
   - Present the `Candidate Options` (list the distinct options with their mechanism, benefit, and cost).
   - Pause and ask the user which architectures or lenses feel right to explore further.
3. **Phase 3: Contrast and Converge**
   - Apply structured comparison logic to the remaining options. Present `Key Contrasts` (explain the differences that matter for choosing between them).
   - Present `Leading Options` (narrow to the strongest candidates and explain why they survived. In wide mode, use `Open Option Set` to describe which options still deserve exploration).
   - Present the `Recommended Next Step` (recommend the next action, mentioning a specific follow-on workflow only when it is available and useful).

## Delivery guidance

- Keep the tone concrete and exploratory, not promotional.
- Prefer short option names that reflect the mechanism, not vague labels like "balanced approach".
- Keep the output at brainstorming level: options, contrasts, and a recommended next step. Escalate to a full RFC or implementation plan only when the user asks.
- If the user wants more ideas after convergence, widen one new axis instead of repeating the same set with different wording.
- Keep the skill portable. Adapt to the repository, framework, or skill set provided by the user or environment rather than assuming one.

## Verification checklist

- [ ] Checked for the X-Y Problem and challenged the premise if needed.
- [ ] Framed the problem and paused for feedback before generating options (Conversational Workflow).
- [ ] Applied "Lenses" (e.g., simplest, infinite scale) to force true diversity.
- [ ] Produced multiple distinct options rather than small variants of one idea.
- [ ] Named the main benefit and main cost of each serious option.
- [ ] Paced the delivery conversationally rather than outputting a single monolithic response.
- [ ] Used focused mode or wide mode intentionally.
- [ ] Narrowed the option set when convergence was the goal, or kept it open on purpose when the user asked for wider ideation.
- [ ] Recommended a next action.
- [ ] Kept deep review and execution detail in their owning workflows.
