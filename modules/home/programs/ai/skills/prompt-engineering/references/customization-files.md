# Customization Files

Use this file for detailed guidance about skills, instruction files, agent personas, and cross-agent portability.

## Model vs coding agent

| Layer                     | What it controls                                                               | Best use                          |
| :------------------------ | :----------------------------------------------------------------------------- | :-------------------------------- |
| Model prompt              | Reasoning quality, output format, domain grounding, consistency                | Improve the content of the answer |
| Coding-agent instructions | Tool use, safety boundaries, approvals, context handling, multi-step workflows | Improve how the work is executed  |

The same model can behave differently across agent apps, and the same agent app can behave differently when you switch models.

## Start with a portable baseline

Treat coding-agent guidance as a portability problem first and a vendor optimization problem second.

- Start with plain markdown rules, imperative language, and explicit success criteria.
- Add vendor-specific syntax only when the target agent needs it for a capability that the portable baseline cannot express clearly.
- Keep vendor-specific details in vendor-specific files so the portable rules stay readable.

## Keep precedence explicit

Customization layers can stack:

1. Repo-wide defaults
2. Scoped instructions
3. Skills
4. Persona files
5. Runtime config

When multiple layers can apply at once:

- Say which layer wins when rules conflict.
- Avoid duplicating the same instruction across layers.
- Keep scoped files narrow so unrelated contexts do not load by default.

## Common customization file types

| File type                 | Scope                     | Purpose                                        |
| :------------------------ | :------------------------ | :--------------------------------------------- |
| Repo-wide instructions    | Whole repository          | Default behavioral rules across the project    |
| Scoped instructions       | Directory or file pattern | Rules that apply only to matching files        |
| Skill files               | On-demand                 | Domain workflow expertise loaded by discovery  |
| Agent persona files       | On-demand                 | Identity, tool boundaries, behavioral defaults |
| Prompt templates          | Reusable                  | Parameterized prompts for repeatable tasks     |
| Agent-specific rule files | Repo or user              | Vendor-specific structured rules               |
| Runtime config            | Runtime/system            | Model, tool, and policy wiring                 |

## Writing skill files

YAML frontmatter requires `name` and `description`.

- `metadata` is the discovery surface. Keep `description` compact and specific to likely user requests.
- The `SKILL.md` body is the loaded workflow surface. Write instructions in imperative mood.
- Bundled resources are on-demand detail. Move long examples, tables, schemas, or helper contracts into `references/`, `scripts/`, or `assets/`.

Bad:

`This skill helps you write better APIs by providing guidelines...`

Good:

`Use plural nouns for collection endpoints. Return 201 for successful POST requests.`

Treat routing sections as routing controls:

- `Use this skill when` should name concrete triggers.
- `Do not use this skill when` should only block realistic misroutes or name true non-use cases.
- Do not pad exclusions with mirror-image inverses or low-probability alternate skills.

## Writing instruction files portably

Use neutral markdown first, then layer agent-specific syntax only where needed.

Scoped instruction pattern:

```yaml
---
applyTo: "src/**/*.test.ts"
---
```

Keep instruction files short and actionable. If a target agent needs a special parser format, isolate that syntax in the file type that agent expects instead of leaking it into the portable baseline.

## Writing agent persona files

Persona files should define:

- The agent's identity
- Tool boundaries
- Confirmation requirements
- Autonomy defaults
- Context recovery expectations

Place persona rules in whatever file type the target agent expects, but keep the behavioral rules themselves portable whenever possible.

## Portability review

Check these before you ship a customization bundle:

- The `description` field uses high-signal discovery terms.
- The file states tool availability, safety boundaries, and confirmation rules explicitly.
- Vendor-only syntax is isolated.
- Multiple active layers do not contradict each other.
- Assumptions about parser behavior, tool interfaces, and context handling are documented instead of implied.
- The setup has been tried in each target agent instead of inferred from one successful run.

## Anti-patterns

- Filler exclusions in `Do not use this skill when`.
- Assuming all agents parse frontmatter or metadata the same way.
- Letting portable files accumulate vendor-only syntax.
- Leaving precedence implicit when multiple instruction layers stack.
- Copying the same rules into repo defaults, scoped rules, and skills.
