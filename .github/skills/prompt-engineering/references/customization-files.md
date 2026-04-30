# Customization Files

Use this file for details about skills, instruction files, agent personas, and cross-agent portability.

## Model vs Agent

- Model prompts control answer quality, format, grounding, and consistency.
- Coding-agent instructions control tool use, safety boundaries, approvals, context handling, and multi-step workflows.

The same model can behave differently across agent apps, and the same agent app can behave differently across models.

## Portable Baseline

- Start with plain markdown, imperative language, and explicit success criteria.
- Add vendor-specific syntax only when the target agent needs it for a capability that portable markdown cannot express clearly.
- Keep vendor-specific details in vendor-specific files.

## Precedence

Customization layers can stack: repo defaults, scoped instructions, skills, persona files, and runtime config. State which layer wins when rules conflict, avoid duplicating the same rule, and keep scoped files narrow so unrelated contexts do not load.

## Skill Files

- YAML frontmatter uses `name` and `description` as the discovery surface.
- `SKILL.md` is the loaded workflow surface. Write imperative instructions, not explanations of what the skill is.
- Bundled resources are on-demand detail. Move long examples, schemas, tables, and helper contracts into `references/`, `scripts/`, or `assets/`.
- `Use this skill when` should name concrete triggers.
- `Do not use this skill when` should only block realistic misroutes or true non-use cases.

## Instruction Files

Use neutral markdown first. Scope instructions with agent-supported mechanisms only when needed.

```yaml
---
applyTo: "src/**/*.test.ts"
---
```

Keep instruction files short and actionable. If an agent needs a special parser format, isolate that syntax in that agent's file type.

## Personas

Persona files define identity, tool boundaries, confirmation requirements, autonomy defaults, and context recovery. Keep the behavioral rules portable even when the file type is vendor-specific.

## Portability Review

- The `description` field uses high-signal discovery terms.
- Tool availability, safety boundaries, and confirmation rules are explicit.
- Vendor-only syntax is isolated.
- Active layers do not contradict each other.
- Parser, tool, and context assumptions are documented.
- The setup has been tried in each target agent.

## Anti-patterns

- Filler exclusions in `Do not use this skill when`.
- Assuming all agents parse frontmatter the same way.
- Letting portable files accumulate vendor-only syntax.
- Leaving precedence implicit when layers stack.
- Copying the same rules into repo defaults, scoped rules, and skills.
