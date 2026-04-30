# Prompt Patterns

Use this file for detailed prompt-writing patterns that are too bulky to keep in the loaded `SKILL.md`.

## Core Patterns

- Be direct: state the desired output format, constraints, and success criteria before generation starts.
- Explain motivation for non-obvious rules so the model can generalize them.
- Use examples only when they reduce ambiguity; keep them relevant, varied, and separated from instructions.
- Pick one structure style per prompt: markdown sections or structured tags.
- Assign a role only when it sharpens judgment, such as security review, API design, or release-note editing.

## Long Context

When input spans large documents, put documents first and the request last. Wrap documents with source metadata, ask for relevant quotes, then answer from those quotes.

```xml
<documents>
  <document index="1">
    <source>report.md</source>
    <document_content>{{REPORT}}</document_content>
  </document>
</documents>

<instructions>
Find relevant quotes, then answer from them.
</instructions>
```

## Output Control

- Tell the model what to do instead of only what to avoid.
- Prefer structured output schemas when the provider supports them.
- Otherwise use clear tags or explicit field names.
- Match prompt style to desired output style.
- Control verbosity directly: ask for a brief summary after tool use when needed, or say to skip preambles when concision matters.

## Tool Use

- Say `implement`, `change`, or `edit` when execution is wanted.
- Say `recommend` or `analyze` when no edits should be made.
- Use targeted tool rules: `Use search when external information would materially improve the answer`.
- For parallel tools: independent calls may run together only when all parameters are known; dependent calls stay sequential.

## Reasoning

Prefer provider-native reasoning controls when available. Without them, ask for focused reasoning and an explicit verification step.

```text
Before finishing, verify the answer against these criteria: [list criteria].
```

## Anti-patterns

- Vague instructions such as `Make it good`.
- Negations without an alternative.
- ALL-CAPS or repeated `CRITICAL` language on recent models.
- Blanket defaults like `Always use tool X`.
- Long examples that bury the actual rules.
