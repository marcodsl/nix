# Prompt Patterns

Use this file for detailed prompt-writing patterns that are too bulky to keep in the loaded `SKILL.md`.

## Be clear and direct

Models respond best to explicit instructions. Say exactly what you want instead of hoping the model infers it.

- State the desired output format and constraints up front.
- Use numbered lists or bullet points when order or completeness matters.
- If you want extra effort, say so explicitly.

Bad: `Create an analytics dashboard`

Good: `Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully featured implementation.`

## Provide context and motivation

Explain why a behavior matters, not just what to do. Models generalize from the reasoning.

Bad: `Never use ellipses.`

Good: `Your response will be read aloud by a text-to-speech engine, so never use ellipses because the engine will not know how to pronounce them.`

## Use examples when they reduce ambiguity

Examples are the strongest format-control mechanism when consistency matters. Include only enough examples to establish the pattern.

Make examples:

- Relevant to the real task.
- Diverse enough to cover edge cases.
- Clearly separated from the main instructions.

Structured-tag pattern:

```xml
<examples>
  <example>
    <input>...</input>
    <output>...</output>
  </example>
</examples>
```

Markdown pattern:

```text
### Example 1
Input: ...
Output: ...
```

## Use one structure style consistently

XML-style tags help models parse complex prompts without ambiguity. Markdown sections work equally well on many models. Pick one style per prompt or file and stay consistent.

Useful tag names:

- `<instructions>`
- `<context>`
- `<input>`
- `<documents>`
- `<quotes>`

## Assign a role only when it sharpens behavior

A single sentence can focus tone and judgment:

```text
You are a senior security engineer reviewing code for vulnerabilities.
```

Use role prompts to sharpen decision criteria, not to add fluff.

## Long-context prompt pattern

When the input is large or spans multiple documents:

1. Put long documents at the top and the request plus instructions at the bottom.
2. Wrap each document in structured tags with metadata.
3. Ask the model to quote relevant passages before answering.
4. Tell it to answer from those quotes rather than from memory.

Example:

```xml
<documents>
  <document index="1">
    <source>report_2024.pdf</source>
    <document_content>{{REPORT}}</document_content>
  </document>
</documents>

<instructions>
Find quotes from the documents that are relevant to the question. Place them in
<quotes> tags. Then answer based on those quotes.
</instructions>
```

## Output and formatting

Tell the model what to do, not only what to avoid.

Bad: `Do not use markdown in your response.`

Good: `Write your response as flowing prose paragraphs.`

Choose the most reliable format control that the target provider supports:

1. Structured output schemas when decode-time constraints are available.
2. Structured tags such as `<analysis>` or `<answer>`.
3. Explicit prose instructions naming the output fields or sections.

Match prompt style to output style. If you write the prompt in markdown, the model is more likely to answer in markdown.

## Control verbosity deliberately

If you want more detail after tool use:

```text
After completing a task that involves tool use, provide a brief summary of what you changed and why.
```

If you want less:

```text
Be concise. Skip preambles and verbal summaries. Get to the point.
```

## Tool-use phrasing

Models distinguish between suggestions and actions.

Bad: `Can you suggest some changes to improve this function?`

Good: `Change this function to improve its performance.`

To bias toward execution:

```xml
<default_to_action>
Implement changes rather than only suggesting them. If the user's intent is unclear,
infer the most likely action and proceed, using tools to discover missing details
instead of guessing.
</default_to_action>
```

To bias toward recommendations instead:

```xml
<do_not_act_before_instructions>
Do not make changes unless clearly instructed. When intent is ambiguous, provide
recommendations rather than taking action.
</do_not_act_before_instructions>
```

For tool rules, prefer targeted conditions over blanket defaults:

Bad: `CRITICAL: ALWAYS use the search tool before answering ANY question.`

Good: `Use the search tool when external information would materially improve the answer.`

If the agent can parallelize tools, say so directly:

```xml
<use_parallel_tool_calls>
If multiple tool calls are independent and all required parameters are already known,
make them in parallel. If one call depends on another, run them sequentially.
</use_parallel_tool_calls>
```

## Reasoning controls

General guidance often works better than overprescribed step lists.

Prefer provider-native reasoning controls when the target platform exposes them. When they do not exist, ask for focused reasoning plus verification.

Verification pattern:

```text
Before finishing, verify your answer against these criteria: [list criteria].
```

Focus pattern:

```text
Choose an approach and commit to it. Avoid revisiting decisions unless new
information directly contradicts your reasoning.
```

## Prompt anti-patterns

- Vague instructions such as `Make it good`.
- Negations without an alternative.
- ALL-CAPS or repeated `CRITICAL` language on recent models.
- Blanket defaults like `Always use tool X`.
- Long examples that bury the actual rules.
