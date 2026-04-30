---
name: prompt-engineering
description: "Write and review LLM prompts and coding-agent instruction files. Use when: editing system prompts, agent rules, SKILL.md, .instructions.md, .agent.md, .prompt.md, or .mdc files."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [prompts, agents, instructions]
---

# Prompt Engineering

Use this skill to write or review prompts, instruction files, and skill bundles so the model gets clear routing, actionable behavior, and portable defaults.

## Purpose

Turn vague prompt ideas into explicit instructions that control output, tool use, reasoning, and instruction layering.

## Scope

### Use this skill when

- Writing or editing system prompts, developer prompts, or reusable prompt templates.
- Reviewing coding-agent customization files such as `SKILL.md`, `.instructions.md`, `.agent.md`, `.prompt.md`, and `.mdc`.
- Fixing weak routing, over-aggressive tool rules, vague constraints, or portability problems across agent apps.

### Do not use this skill when

- The task is only tightening prose or removing filler without changing prompt structure. Use `natural-tone` for tone-only edits.
- The task is mainly a language, framework, or product implementation problem and only touches prompts incidentally. Use the domain skill first and apply this one underneath it.

## Governing rule

Say exactly what you want, in the layer that controls that behavior, and write the instruction so the model can follow it without guessing.

## Working method

1. Identify the artifact type and control layer before editing anything.
2. Rewrite the highest-leverage instructions first: routing, behavior defaults, format constraints, tool use, and verification.
3. Keep loaded instructions short; move long examples and reference material into bundled resources.
4. Test the rewritten guidance against the real task it is supposed to steer.

## First classify the surface

- Use model-level prompts to improve reasoning quality, output format, grounding, and consistency.
- Use agent-level instructions to control tool use, safety boundaries, autonomy, context recovery, and multi-step workflows.
- For skills, explain the three-layer loading model explicitly when it matters:
  1. `metadata` in frontmatter is the discovery surface. `name` and `description` decide whether the skill can be found.
  2. The `SKILL.md` body is the loaded workflow surface. Keep it focused on what to do once the skill loads.
  3. Bundled resources are on-demand detail. Move long examples, tables, schemas, and helper material into `references/`, `scripts/`, or `assets/`.

## Rewrite prompts to be executable

- State the desired output shape and constraints before generation starts.
- Tell the model what to do, not only what to avoid.
- Give motivation for non-obvious rules so the model can generalize them.
- Use examples only when they materially reduce ambiguity; keep them relevant and varied.
- Pick one structure style per file or prompt: consistent markdown sections or structured tags.

## Tool use and reasoning

- Make actions vs suggestions explicit. If you want execution, say to implement or change something instead of merely suggesting improvements.
- Use conditional tool guidance, not blanket defaults. Prefer `Use tool X when...` over `ALWAYS use tool X`.
- Tell the model to parallelize independent tool calls, but only when parameters are already known.
- Prefer provider-native reasoning controls when available. Otherwise ask for focused reasoning plus a concrete verification step.
- Avoid aggressive emphasis (`CRITICAL`, ALL-CAPS, repeated MUSTs) unless you have evidence a target model underfollows normal instructions.

## Author portable customization files

- Start with a portable markdown baseline that works across agents.
- Add vendor-specific syntax only when it unlocks a capability the portable version cannot express clearly.
- Keep precedence explicit when repo defaults, scoped instructions, skills, and persona files can stack.
- When multiple layers can apply, state which layer wins and avoid duplicating the same rule across those layers.
- Keep routing text tight. `Use this skill when` and `Do not use this skill when` are routing controls, not filler sections.
- Avoid Markdown tables unless two-dimensional structure is essential and cannot be expressed as bullets. Tables consume significantly more tokens than equivalent bullet lists due to border syntax and padding; prefer `- key: value` or `- trigger → action` formats.
- Name tool availability, confirmation boundaries, and context assumptions explicitly instead of assuming every agent behaves like your primary one.

## Review checklist

Check these before finalizing a prompt or instruction file:

- The discovery surface matches likely user requests.
- Every rule is actionable and tied to a real behavior.
- The prompt names the required output format, grounding expectations, and verification criteria.
- Tool-use guidance is conditional, not over-broad.
- Long examples live in bundled resources instead of bloating the loaded file.
- Tables are only used when two-dimensional structure is essential; bullet lists replace them everywhere else.
- Stacked instruction layers do not repeat the same rule without a clear reason.
- Cross-agent files stay portable, and vendor-only syntax is isolated.

## Bundled resources

Read the bundled resources when you need detailed patterns or examples:

- `references/prompt-patterns.md` for prompt structure, long-context patterns, tool-use phrasing, and reasoning controls.
- `references/customization-files.md` for skill layout, instruction-layer precedence, portability rules, and file-type-specific guidance.
