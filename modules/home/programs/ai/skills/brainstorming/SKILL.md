---
name: brainstorming
description: "Generate a spread of distinct software-engineering options with concrete tradeoffs, then narrow to one before design. Triggers: 'brainstorm', 'ideas for', 'what are my options', 'how should I approach', 'explore alternatives', 'wide mode', or any prompt where you would otherwise pick one approach silently."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: brainstorming, ideation, software-engineering, design
  version: 3
---

# Brainstorming

<purpose>
Turn a vague software-engineering problem into a short set of concrete options worth evaluating. Start wide enough to find real alternatives, then narrow far enough that the next step is obvious.
</purpose>

<scope>
  <use_when>
  - Exploring options before committing to a design, approach, or plan.
  - The task needs multiple plausible approaches instead of immediate convergence.
  - Generating alternatives, hybrids, tradeoffs, or next steps for a software-engineering decision.
  - Shared understanding matters but the task is too early for a detailed execution artifact.
  </use_when>

  <do_not_use_when>
  - Casual free association with no need to organize or compare ideas.
  </do_not_use_when>
</scope>

<governing_rule>
Generate a real spread of options before recommending one. Every serious option must solve the stated problem, expose a distinct tradeoff, and leave the user with a clear next move.
</governing_rule>

<working_method>
1. Frame the problem: name the actor, the system boundary, the decision, and the success condition. Challenge the premise if it looks like an X-Y problem (user asks about a solution when a different problem is the real one).
2. Generate a wide option set using lenses that force diversity.
3. Force contrast: compare options against each other instead of presenting parallel summaries.
4. Narrow to the strongest candidates, or keep the set explicitly open in wide mode.
5. Hand off with a recommended next step.
</working_method>

<section name="modes">
- `Focused mode` (default): generate a manageable option set, compare it, and narrow to the strongest candidates.
- `Wide mode`: keep the option space broader for longer, explore more axes, and defer ranking until the user is ready.
</section>

<section name="frame-the-problem">
- Analyze the stated problem. If the premise seems misaligned with standard engineering practices, challenge it explicitly and respectfully.
- Ask for missing constraints only when they change the option set in a material way.
- State the success condition in concrete terms.
- If available context can answer a factual question quickly, inspect it instead of asking.
- Keep this stage short. The goal is a stable frame, not a pressure test.
</section>

<section name="generate-options">
- Apply lenses to force diversity: "Simplest/Dumbest Way", "Infinite Scale Way", "No-Code/Process Way".
- Aim for a manageable set of distinct options in focused mode; expand only when a new option introduces a genuinely new angle in wide mode.
- Include the obvious baseline when realistic, including "do nothing" if that is a serious option.
- Vary the dimension of change: system design, interface shape, ownership split, process, tooling, or scope reduction.
- If all options look similar, say so and widen a different axis instead of pretending there is diversity.

Each option must answer:
1. What changes?
2. Why might this work well here?
3. What cost, risk, or limitation comes with it?
</section>

<section name="force-contrast">
- Call out the main dimension separating each option from the others.
- Note where one option is cheaper, safer, faster to try, easier to operate, or easier to maintain.
- Collapse near-duplicates into one stronger option.
- If a hybrid is stronger than the originals, propose it as a first-class candidate.
</section>

<section name="narrow-and-hand-off">
- Eliminate options that fail the stated constraints or duplicate a stronger candidate.
- Prefer options with a clear path to evaluation over vague promise.
- Recommend one leading option when the tradeoff is clear; otherwise name the information that would change the ranking.
- Finish with a next move: a single recommendation, a structured challenge, a fuller design review, or planning, whichever fits.
</section>

<section name="conversational-pacing">
Pace delivery in phases instead of one monolithic response:
1. Present the problem frame (decision, constraints, success condition). Pause for confirmation.
2. Present candidate options (mechanism, benefit, cost). Pause and ask which lenses to explore further.
3. Present key contrasts, then leading options (or open option set in wide mode), then the recommended next step.
</section>

<section name="delivery">
- Keep the tone concrete and exploratory, not promotional.
- Prefer short option names that reflect the mechanism, not vague labels like "balanced approach".
- Stay at brainstorming level: options, contrasts, next step. Escalate to a full RFC or implementation plan only when the user asks.
- If the user wants more ideas after convergence, widen one new axis instead of repeating the set with different wording.
- Adapt to the repository, framework, or skill set the user provides rather than assuming one.
</section>

<review_checklist>
- Checked for the X-Y problem and challenged the premise if needed.
- Framed the problem and paused for feedback before generating options.
- Applied lenses (simplest, infinite scale, no-code) to force true diversity.
- Produced multiple distinct options rather than small variants of one idea.
- Named the main benefit and main cost of each serious option.
- Paced delivery conversationally rather than outputting a single monolithic response.
- Used focused mode or wide mode intentionally.
- Narrowed the option set when convergence was the goal, or kept it open on purpose.
- Recommended a next action.
- Kept deep review and execution detail in their owning workflows.
</review_checklist>
