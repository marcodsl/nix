---
name: prompt-engineering
description: "Write and review prompts for LLM APIs and coding agent customization files. Use when: editing system prompts, agent instructions/rules, .instructions.md, SKILL.md, .agent.md, .prompt.md, .mdc, and configuring coding agent apps."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [prompts, agents, instructions]
---

# Prompt Engineering

Rules for writing prompts that work well across LLM providers and for authoring coding-agent customization files.

## Scope

### Use this skill when

- Writing or editing system prompts, agent instructions, or LLM API prompts.
- Authoring or reviewing coding-agent customization files (.instructions.md, SKILL.md, .agent.md, .prompt.md, .mdc).
- Structuring few-shot examples, tool-use guidance, or reasoning controls for any model provider.

### Do not use this skill when

- The task is tightening prose tone or removing filler without changing prompt structure. Use `natural-tone` for prose quality inside prompts.
- The task is a code design, architecture, or review decision. Use `coding-guidelines` for tradeoff analysis.
- The task is writing end-user documentation where prompt structure and agent behavior are not the focus.

## Coding agent vs model

Both are useful, but they solve different problems at different layers.

| Layer        | What it is                                                                                                 | Best use                                                                |
| ------------ | ---------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Model (LLM)  | The reasoning and generation engine that produces text/code                                                | Reasoning quality, output format, domain accuracy, consistency          |
| Coding agent | The orchestration runtime around one or more models (tools, memory, approvals, context loading, workflows) | Execution behavior, tool usage, safety boundaries, multi-step task flow |

Use model-level prompts to improve answer quality. Use agent-level instructions to control how work is executed.

The same model can behave differently across agent apps, and the same agent app can behave differently when you switch models.

## Core principles

### Be clear and direct

Models respond best to explicit instructions. Say exactly what you want instead of hoping the model infers it.

Test: show the prompt to someone with no context on the task. If they'd be confused, the model will be too.

- State the desired output format and constraints up front.
- Use numbered lists or bullet points when order or completeness matters.
- If you want extra effort, say so explicitly.

Bad: `Create an analytics dashboard` Good: `Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.`

### Provide context and motivation

Explain _why_ a behavior matters, not just _what_ to do. Models generalize from the reasoning.

Bad: `NEVER use ellipses` Good: `Your response will be read aloud by a text-to-speech engine, so never use ellipses since the engine won't know how to pronounce them.`

### Use examples (few-shot prompting)

Examples are the most reliable way to control output format, tone, and structure. Include 3-5 examples when consistency matters.

Make examples:

- **Relevant**: mirror the actual use case.
- **Diverse**: cover edge cases so the model doesn't latch onto a single pattern.
- **Structured**: wrap in `<example>` tags (or `<examples>` for a set) so the model distinguishes them from instructions.

```xml
<examples>
  <example>
    <input>...</input>
    <output>...</output>
  </example>
  <example>
    <input>...</input>
    <output>...</output>
  </example>
</examples>
```

If the target model handles XML poorly, use markdown headers or fenced blocks instead:

```
### Example 1
Input: ...
Output: ...
```

### Structure prompts with tags

XML tags help models parse complex prompts without ambiguity. Wrap each type of content in its own tag: `<instructions>`, `<context>`, `<input>`, `<documents>`.

- Use consistent, descriptive tag names.
- Nest tags when content has hierarchy (`<documents>` > `<document index="1">` > `<document_content>`).

XML tags work well on most models. Markdown sections (`###`, `---`) are equally effective on some. Pick one style and stay consistent within a prompt.

### Assign a role

A single sentence in the system prompt focuses the model's behavior and tone:

```
You are a senior security engineer reviewing code for vulnerabilities.
```

All major model families support system prompts. Use them.

### Handle long context

When the input exceeds ~20k tokens:

1. Put long documents at the top, query and instructions at the bottom. This can improve response quality by up to 30% on complex multi-document inputs.
2. Wrap each document in structured tags with metadata:

```xml
<documents>
  <document index="1">
    <source>report_2024.pdf</source>
    <document_content>{{REPORT}}</document_content>
  </document>
</documents>
```

3. Ask the model to quote relevant passages before answering. This grounds the response in the source material and reduces hallucination:

```
Find quotes from the documents that are relevant to the question. Place them in <quotes> tags. Then answer based on those quotes.
```

## Output and formatting

### Tell the model what to do, not what to avoid

Bad: `Do not use markdown in your response` Good: `Write your response as flowing prose paragraphs.`

Bad: `Don't use bullet points` Good: `Incorporate items naturally into sentences instead of listing them.`

### Use format constraints

Options from most to least portable:

1. **Structured output schemas** (JSON Schema): many providers support constraining model output to a schema at decode time.
2. **XML tag indicators**: `Write the analysis in <analysis> tags.` Works on most models.
3. **Explicit format instructions**: `Respond with a JSON object containing "name" and "score" fields.`

### Match prompt style to output style

The formatting you use in the prompt influences the response. If you write your prompt in markdown, the model tends to respond in markdown. If you want plain prose, write the prompt in plain prose.

### Control verbosity

Recent models default to concise output. They may skip summaries after tool calls and jump to the next action. If you want more detail:

```
After completing a task that involves tool use, provide a brief summary of what you did.
```

If you want less:

```
Be concise. Skip preambles and verbal summaries. Get to the point.
```

## Tool use

### Be explicit about actions vs suggestions

Models distinguish between describing what could be done and actually doing it:

Bad (model will only suggest): `Can you suggest some changes to improve this function?` Good (model will act): `Change this function to improve its performance.`

To make a model proactive by default:

```xml
<default_to_action>
Implement changes rather than only suggesting them. If the user's intent is unclear, infer the most likely action and proceed, using tools to discover missing details instead of guessing.
</default_to_action>
```

To make a model conservative by default:

```xml
<do_not_act_before_instructions>
Do not make changes unless clearly instructed. When intent is ambiguous, provide recommendations rather than taking action.
</do_not_act_before_instructions>
```

### Parallel tool calling

Most model families support calling multiple tools in one turn. Guide this behavior explicitly:

```xml
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between them, make all independent calls in parallel. For example, when reading 3 files, call all 3 reads at once. If a call depends on a previous result, run it sequentially. Never guess missing parameters.
</use_parallel_tool_calls>
```

### Dial back aggressive prompting on recent models

Older prompts used language like "CRITICAL: You MUST use this tool when..." because earlier models undertriggered. Recent models are more responsive to system prompts and will overtrigger on that language. Soften it:

Bad: `CRITICAL: You MUST ALWAYS use the search tool before answering ANY question.` Good: `Use the search tool when external information would improve your answer.`

## Thinking and reasoning

### General guidance beats prescriptive steps

A prompt like "think thoroughly about this problem" often produces better reasoning than a hand-written step-by-step plan. The model's internal reasoning frequently exceeds what a human would prescribe.

### Self-verification

Append a check step to catch errors, especially for code and math:

```
Before finishing, verify your answer against these criteria: [list criteria].
```

### Prevent overthinking

If the model spends too many tokens deliberating:

```
Choose an approach and commit to it. Avoid revisiting decisions unless you encounter information that directly contradicts your reasoning.
```

### Provider reasoning controls

Some providers offer built-in reasoning or "thinking" modes that let the model deliberate internally before producing a response. Common patterns:

- **Adaptive reasoning**: the model decides when and how much to reason, controlled by an effort or budget parameter.
- **Fixed-budget reasoning**: the caller sets a token budget for internal deliberation.
- **Built-in reasoning tokens**: some model families include reasoning tokens by default with no prompt-side configuration needed.

When the provider supports these controls, prefer them over prompt-side chain-of-thought. Adaptive modes that let the model decide its own reasoning depth tend to outperform fixed budgets in evaluations.

When built-in reasoning is unavailable or disabled, fall back to prompting the model to reason in its output:

```
Think through this step by step. Put your reasoning in <thinking> tags and your final answer in <answer> tags.
```

Some models behave differently around reasoning-related keywords ("think", "reason") when their built-in reasoning is off. If the model seems to stall or over-deliberate, try alternative phrasing like "consider", "evaluate", or "reason through".

## Agentic systems

### State tracking

For long-running tasks across multiple turns or context windows:

- Use structured formats (JSON) for status data like test results or task lists.
- Use plain text for progress notes and session summaries.
- Use git commits as checkpoints that persist across context windows.
- Track progress incrementally. Focus on a few things at a time.

```json
// tests.json
{
  "tests": [
    { "id": 1, "name": "auth_flow", "status": "passing" },
    { "id": 2, "name": "user_mgmt", "status": "failing" }
  ]
}
```

```text
// progress.txt
Session 3:
- Fixed token validation
- Updated user model edge cases
- Next: investigate user_mgmt test failures (#2)
```

### Context window management

Models can run out of context during long tasks. If the harness supports compaction or external memory:

```
Your context window will be compacted as it approaches its limit, so do not stop tasks early due to token budget. Save progress and state to memory before compaction occurs. Complete tasks fully.
```

For fresh context windows after compaction, tell the model how to recover state:

```
Review progress.txt, tests.json, and recent git log. Run a smoke test before continuing.
```

### Autonomy and safety

Without guidance, models may take irreversible actions (deleting files, force-pushing, posting to external services). Add guardrails:

```
Take local, reversible actions freely (edit files, run tests). For destructive or externally-visible actions, ask the user first.

Actions that need confirmation:
- Deleting files, branches, or database tables
- git push --force, git reset --hard
- Posting to external services, commenting on PRs/issues
```

### Subagent orchestration

Some models delegate to subagents without being told to. If this happens too aggressively:

```
Use subagents for parallel tasks, isolated workstreams, or tasks that don't need shared state. For single-file edits, sequential operations, or tasks where you need context across steps, work directly.
```

### Minimize hallucination

```xml
<investigate_before_answering>
Never speculate about code you have not opened. If the user references a file, read it before answering. Investigate relevant files before making claims about the codebase.
</investigate_before_answering>
```

### Prevent overengineering

```
Only make changes that are directly requested or clearly necessary.

- Don't add features, refactoring, or abstractions beyond what was asked.
- Don't add docstrings or comments to code you didn't change.
- Don't add error handling for scenarios that can't happen.
- Don't create helpers or utilities for one-time operations.
```

### General solutions over test-passing hacks

Models sometimes hard-code values to pass specific test cases. Prevent this:

```
Implement general-purpose solutions that work for all valid inputs, not just the test cases. Do not hard-code values. If a test seems wrong, flag it rather than working around it.
```

## Coding agent customization

Treat coding-agent guidance as a portability problem first, and a vendor-specific optimization problem second.

### Start with a portable baseline

Use plain markdown rules, imperative language, and explicit success criteria. This baseline works across most coding agents.

### Add agent-specific syntax only when needed

Use agent-specific syntax (for example structured rule files or agent-native JSON settings) only when the target agent needs it for a capability you cannot express portably.

### Design for capability variance

Different coding agents expose different tool sets, context behavior, and instruction precedence. State tool and safety expectations explicitly instead of assuming every agent behaves like your primary one.

### Common customization file types

| File type                 | Scope                     | Purpose                                                                       |
| ------------------------- | ------------------------- | ----------------------------------------------------------------------------- |
| Repo-wide instructions    | Whole repository          | Default behavioral rules for the agent across the project                     |
| Scoped instructions       | Directory or file pattern | Rules that apply only to matching files, often via frontmatter like `applyTo` |
| Skill files               | On-demand                 | Domain workflow expertise loaded by skill discovery                           |
| Agent persona files       | On-demand                 | Agent identity, tool boundaries, and behavioral defaults                      |
| Prompt templates          | Reusable                  | Parameterized prompts for repeatable tasks                                    |
| Agent-specific rule files | Repo or user              | Structured rule files in vendor-specific formats                              |
| Runtime config            | Runtime/system            | Model/tool wiring, policy, and execution settings                             |
| Plain markdown rules      | Repo-wide                 | Shared guidance that works regardless of parser differences                   |

### Writing skill files

YAML frontmatter requires `name` and `description`. The description is your discovery surface, so include specific trigger phrases for the requests you expect:

```yaml
---
name: api-design
description: "Design REST and GraphQL APIs. Use when: creating endpoints, reviewing API contracts, writing OpenAPI specs."
---
```

The body contains the actual instructions. Write them as rules the model should follow, not explanations of what the skill is. Use imperative mood.

Bad: `This skill helps you write better APIs by providing guidelines...` Good: `Use plural nouns for collection endpoints. Return 201 for successful POST requests.`

### Writing instruction files portably

Use neutral markdown first, then layer agent-specific syntax only where necessary. Scope instructions to specific files or directories when your agent supports path-level rules.

Portable pattern:

```yaml
---
applyTo: "src/**/*.test.ts"
---
```

Keep instructions short and actionable. Isolate vendor-specific syntax in vendor-specific files so portable files stay readable across agents.

### Writing agent persona files

Define the agent's identity, allowed tools, and behavioral constraints. Some agents use the `description` field in frontmatter for discovery; others use different mechanisms. Place persona controls in whatever file type the target agent expects.

### General rules for all customization files

- Keep instructions actionable. Every sentence should tell the model to do (or not do) something specific.
- Use structured tags (`<instructions>`, `<rules>`) to separate sections when the file is long.
- Test instructions by using them. If the model ignores a rule, the instruction is probably too vague or buried in too much text.
- Keep precedence explicit when instructions stack (repo defaults, scoped instructions, skills, and agent personas) so rules do not conflict.
- Avoid redundancy with other active customization files. Instructions stack, so duplicates waste context.

### Portability notes

- Tune prompts for output quality first: role clarity, explicit constraints, examples, and verification criteria.
- Prefer portable patterns (clear markdown, structured examples, explicit format requirements) before provider-specific features.
- Use provider-specific controls (for example thinking budgets or structured output modes) only when they produce measurable benefits.
- XML tags are a strong fit for complex instructions on most models. Markdown headers work equally well on others. Pick one style per file.
- Use `description` fields as high-signal discovery triggers; vague descriptions are easy to miss.
- Keep scoped instruction files tight so unrelated contexts do not load by default.
- Assume multiple instruction layers are active and resolve precedence conflicts explicitly.
- Document assumptions about tool availability, confirmation behavior, and safety boundaries explicitly.
- Expect differences in parser behavior, prompt layering, and tool interfaces across agents.
- Validate behavior in each target agent instead of assuming compatibility from one successful run.

## Anti-patterns

These are common mistakes. Avoid them.

**Vague instructions**: "Make it good" or "Be helpful" gives the model nothing to act on. Say what "good" means: format, length, audience, constraints.

**Negation without alternative**: "Don't use bullet points" leaves the model guessing. Say what to do instead: "Write items as sentences within paragraphs."

**Over-prompting tools**: Adding "ALWAYS use tool X before answering" causes overtriggering on recent models. Use targeted conditions: "Use tool X when the question requires external data."

**Aggressive emphasis**: ALL-CAPS, "CRITICAL", "YOU MUST", exclamation marks. Older models needed this; recent ones follow normal instructions and overtrigger on aggressive language.

**Blanket defaults**: "Always use the search tool" or "Default to using [tool]." Replace with conditional guidance: "Use [tool] when it would improve your understanding of the problem."

**Assuming identical frontmatter parsing**: Do not assume all coding agents parse YAML frontmatter, tags, or file metadata identically.

**Leaking vendor-only syntax into portable files**: Keep portable instruction files neutral; move vendor-specific syntax to vendor-specific files.

**Conflicting instructions**: Multiple active customization files can produce contradictory behavior. Audit load order and remove conflicts.

## Validation checklist

- Confirm discovery terms in `description` match likely user requests.
- Confirm frontmatter parses correctly in the target environment.
- Confirm portable files avoid vendor-only syntax.
- Confirm vendor-specific files are isolated and clearly named.
- Confirm stacked instruction layers have explicit precedence and no conflicts.
- Confirm expected behavior in each target agent with at least one real prompt trial.
