# Prompt Patterns

Use this file for detailed prompt-writing patterns that are too bulky to keep in the loaded `SKILL.md`.

<pattern name="be-clear-and-direct">
Treat the model like a brilliant new employee: precise and capable, but lacking context on your norms and intent. The more precisely you explain what you want, the better the result.

Golden rule: show your prompt to a colleague with minimal task context and ask them to follow it. If they get stuck or confused, the model will too.

- State the desired output format and constraints up front.
- Use numbered lists or bullet points when order or completeness matters.
- If you want "above and beyond" behavior, ask for it explicitly. The model does not infer it from vague phrasing.

**Less effective:**

```text
Create an analytics dashboard
```

**More effective:**

```text
Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```
</pattern>

<pattern name="provide-context-and-motivation">
Explain why a behavior matters, not just what to do. The model generalizes from the reasoning, so giving the motivation produces broader, more reliable behavior than stating the rule alone.

**Less effective:**

```text
Never use ellipses.
```

**More effective:**

```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses because the engine will not know how to pronounce them.
```
</pattern>

<pattern name="use-examples">
Examples (few-shot or multishot prompting) are the most reliable single lever for steering output format, tone, and structure. A handful of well-crafted examples often outperforms paragraphs of prose.

- 3 to 5 examples is a good starting point. Let coverage of edge cases override the number; stop adding examples once the desired pattern is consistent.
- Make examples relevant: mirror the real task closely.
- Make examples diverse enough to cover edge cases. Avoid accidental patterns the model could overfit to.
- Wrap each example in `<example>` tags, and group multiple examples under an `<examples>` parent so the model can separate them from instructions.

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
</pattern>

<pattern name="consistent-structure">
XML-style tags help the model parse complex prompts unambiguously, especially when a prompt mixes instructions, context, examples, and variable inputs. Markdown sections work for short, single-purpose prompts; for multi-section prompts and skill files, prefer XML.

- Use consistent, descriptive tag names across a prompt and across related prompts.
- Nest tags when content has a natural hierarchy (for example, each `<document>` inside `<documents>`).
- Pick one style per file or prompt and stay consistent.

Useful tag names:

- `<instructions>`
- `<context>`
- `<input>`
- `<documents>`
- `<quotes>`

Most major agent apps (Claude, Codex, Copilot, OpenCode) parse the body as text and ignore unknown tags, so XML structuring is portable.
</pattern>

<pattern name="role-assignment">
A single sentence can focus tone and judgment:

```text
You are a senior security engineer reviewing code for vulnerabilities.
```

Use role prompts to sharpen decision criteria, not to add fluff.
</pattern>

<pattern name="long-context">
When the input is large or spans multiple documents:

1. Put long documents at the top and the request plus instructions at the bottom. In tests, placing the query at the end has produced up to 30% better response quality, especially with complex multi-document inputs.
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
</pattern>

<pattern name="output-and-formatting">
Tell the model what to do, not only what to avoid.

**Less effective:**

```text
Do not use markdown in your response.
```

**More effective:**

```text
Write your response as flowing prose paragraphs.
```

Choose the most reliable format control that the target provider supports:

1. Decode-time structured-output schemas, where the provider supports them, outperform prose constraints for JSON, YAML, or classification labels.
2. Structured tags such as `<analysis>` or `<answer>` when schemas are not available.
3. Explicit prose instructions naming the output fields or sections.

Match prompt style to output style. If you write the prompt in markdown, the model is more likely to answer in markdown.

To skip introductory preambles:

```text
Respond directly without preamble. Do not start with phrases like "Here is...", "Based on...", or "Sure, let me...".
```
</pattern>

<pattern name="control-verbosity">
If you want more detail after tool use:

```text
After completing a task that involves tool use, provide a brief summary of what you changed and why.
```

If you want less:

```text
Be concise. Skip preambles and verbal summaries. Get to the point.
```

Positive examples of the desired concision outperform negative instructions. Show one or two short answers that match the target style instead of writing "do not be verbose".
</pattern>

<pattern name="tool-use-phrasing">
Models distinguish between suggestions and actions.

**Less effective (model may only suggest):**

```text
Can you suggest some changes to improve this function?
```

**More effective (model will make the changes):**

```text
Change this function to improve its performance.
```

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

**Less effective:**

```text
CRITICAL: ALWAYS use the search tool before answering ANY question.
```

**More effective:**

```text
Use the search tool when external information would materially improve the answer.
```

Recent models follow instructions faithfully and can overtrigger on aggressive emphasis. Replace `CRITICAL: You MUST use tool X when ...` with `Use tool X when ...`. The directive survives without the shouting.

If the agent can parallelize tools, say so directly:

```xml
<use_parallel_tool_calls>
If multiple tool calls are independent and all required parameters are already known,
make them in parallel. If one call depends on another, run them sequentially.
</use_parallel_tool_calls>
```
</pattern>

<pattern name="reasoning-controls">
General guidance often works better than overprescribed step lists.

Prefer provider-native reasoning controls (for example, Claude adaptive thinking, OpenAI reasoning effort) when the target platform exposes them. When they do not exist, ask for focused reasoning plus verification.

Manual chain-of-thought, used when adaptive thinking is unavailable, separates reasoning from the answer with tags:

```xml
<thinking>
Work through the problem step by step here.
</thinking>

<answer>
Final answer goes here.
</answer>
```

Few-shot examples that include `<thinking>` blocks teach the model the reasoning shape you want it to imitate.

Verification pattern:

```text
Before finishing, verify your answer against these criteria: [list criteria].
```

Focus pattern:

```text
Choose an approach and commit to it. Avoid revisiting decisions unless new
information directly contradicts your reasoning.
```
</pattern>

<pattern name="ground-investigation">
To reduce hallucination in agentic tasks, require the model to open and read referenced files or data before answering. Speculation is the single biggest source of confidently wrong output in coding agents.

```xml
<investigate_before_answering>
Never speculate about code or data you have not opened. If the user references a
specific file, you MUST read it before answering. Investigate and read relevant
files BEFORE answering questions about the codebase or dataset. Never make claims
about code or data before investigating unless you are certain of the correct
answer; give grounded, hallucination-free answers.
</investigate_before_answering>
```
</pattern>

<pattern name="autonomy-and-safety">
When an agent can take destructive or hard-to-reverse actions, prompt it to weigh blast radius and reversibility before acting.

```text
Consider the reversibility and potential impact of your actions. Take local,
reversible actions like editing files or running tests freely. For actions that
are hard to reverse, affect shared systems, or could be destructive, ask the user
before proceeding.

Examples of actions that warrant confirmation:
- Destructive operations: deleting files or branches, dropping database tables,
  rm -rf.
- Hard-to-reverse operations: git push --force, git reset --hard, amending
  published commits, modifying CI or production config.
- Operations visible to others: pushing code, commenting on PRs or issues,
  sending messages, modifying shared infrastructure.

When you hit an obstacle, do not use destructive actions as a shortcut. Do not
bypass safety checks (for example, --no-verify) or discard unfamiliar files that
may be in-progress work.
```
</pattern>

<pattern name="state-tracking">
For tasks that span multiple context windows or long-horizon sessions, prompt the model to externalize state so it survives context resets.

- Track structured data (test results, task status) in a JSON file with a stable schema.
- Track freeform progress in a plain-text notes file.
- Use git as the source of truth for code state and checkpoints.
- Tell the model to make incremental progress on a few things at a time rather than attempting everything at once.

If the harness supports context compaction or refresh:

```text
Your context window may be automatically compacted or refreshed as it approaches its limit. Before that happens, save your current progress and the next concrete step to a notes file. Do not stop work early because the budget is running low; complete the current unit of work, persist state, and continue after the refresh.
```
</pattern>

<anti_patterns>
- Vague instructions such as `Make it good`.
- Negations without an alternative.
- ALL-CAPS or repeated `CRITICAL` language on recent models, which can cause overtriggering.
- Blanket defaults like `Always use tool X`.
- Long examples that bury the actual rules.
- Speculation without first investigating the referenced code, files, or data.
</anti_patterns>
