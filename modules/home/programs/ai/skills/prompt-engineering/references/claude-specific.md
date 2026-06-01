# Claude-specific Patterns

This file covers prompt-engineering guidance from the Anthropic best-practices page that is specific to Claude latest models (Opus 4.8, Opus 4.7, Opus 4.6, Sonnet 4.6, Haiku 4.5) and does not generalize across other agent apps. Opus 4.8 is the lead model; behaviors are attributed to the specific versions they apply to. Use these patterns alongside the portable guidance in `prompt-patterns.md`.

Opus 4.8 performs well out of the box on existing Opus 4.7 prompts; the patterns below cover the behaviors that most often need tuning on upgrade.

<section name="effort-and-thinking">
Claude latest models expose an `effort` parameter that trades intelligence against token spend and latency.

- `max`: maximum effort. Diminishing returns and risk of overthinking; reserve for the hardest intelligence-demanding tasks.
- `xhigh`: best default for coding and agentic use cases.
- `high`: balanced. Recommended minimum for intelligence-sensitive workloads.
- `medium`: cost-sensitive workloads that can trade some intelligence for token savings.
- `low`: short, scoped, latency-sensitive workloads only.

Opus 4.8 respects effort levels strictly, especially at the low end. At `low` and `medium` it scopes its work to what was asked rather than going above and beyond, which is good for latency and cost but risks under-thinking on moderately complex tasks at `low`. Effort is likely more important for this model than for any prior Opus, so experiment with it actively when you upgrade. If reasoning looks shallow on a complex problem, raise effort to `high` or `xhigh` before prompting around it. If you must keep `low` for latency:

```text
This task involves multi-step reasoning. Think carefully through the problem before responding.
```

Pair high effort with a generous `max_tokens` budget (start at 64k) so the model has room to think and act across subagents and tool calls.

Adaptive thinking (`thinking: {type: "adaptive"}`) is the recommended thinking mode. On Opus 4.8, thinking is off unless you explicitly set it; adaptive then lets the model decide when and how much to think based on effort and query complexity. The deprecated `budget_tokens` path on extended thinking still works on Opus 4.6 and Sonnet 4.6 but should be migrated to effort.

If the model thinks more than you want with large or complex system prompts:

```text
Thinking adds latency and should only be used when it will meaningfully improve answer quality, typically for problems that require multi-step reasoning. When in doubt, respond directly.
```
</section>

<section name="response-length-and-verbosity">
Opus 4.8 calibrates response length to how complex it judges the task to be, rather than defaulting to a fixed verbosity. Expect shorter answers on simple lookups and much longer ones on open-ended analysis. If your product depends on a specific style or verbosity, tune the prompt. To decrease verbosity:

```text
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

Positive examples showing the appropriate level of concision tend to be more effective than negative instructions that tell the model what not to do.
</section>

<section name="tool-use-triggering">
Opus 4.8 tends to favor reasoning over tool calls, which produces better results in most cases. Increasing the effort setting is the main lever to increase tool usage: `high` or `xhigh` show substantially more tool use in agentic search and coding. Where you want more tool use, also instruct the model explicitly about when and how to use a given tool. For example, if it is not using your web search tools, describe clearly why and how it should.
</section>

<section name="thinking-tags">
Use `<thinking>` and `<answer>` tags to separate reasoning from final output. This pattern is most useful in two cases:

1. Few-shot examples that demonstrate the reasoning style you want the model to imitate. Include `<thinking>` blocks inside each example and the model will generalize the shape into its own adaptive thinking blocks.
2. Manual chain-of-thought when adaptive thinking is disabled.

When extended thinking is disabled, Claude Opus 4.5 is particularly sensitive to the word "think" and its variants, which can cause unintended thinking-mode triggering. Prefer "consider", "evaluate", "reason through", or "work through" in those cases.
</section>

<section name="literal-instruction-following">
Opus 4.8 interprets prompts literally and explicitly, particularly at lower effort levels. It does not silently generalize an instruction from one item to another, and it does not infer requests you did not make. The upside is precision and less thrash; it performs well for carefully tuned API prompts, structured extraction, and pipelines where predictable behavior matters. If you want broad application, state the scope explicitly:

```text
Apply this formatting to every section, not just the first one.
```
</section>

<section name="tone-and-writing-style">
Opus 4.8 tends toward a direct, opinionated style with minimal validation-forward phrasing and sparing emoji use. Prose style on long-form writing may shift relative to earlier models. If your product relies on a specific voice, re-evaluate style prompts against the new baseline. For a warmer, more conversational voice:

```text
Use a warm, collaborative tone. Acknowledge the user's framing before answering.
```
</section>

<section name="dial-back-aggression">
Claude 4.5 and 4.6 are more responsive to system prompts than earlier models. Prompts tuned to prevent undertriggering on tools or skills can now overtrigger. Replace aggressive emphasis with neutral phrasing.

**Less effective on recent models:**

```text
CRITICAL: You MUST use the search tool when answering any question.
```

**More effective:**

```text
Use the search tool when external information would materially improve the answer.
```
</section>

<section name="prefill-migration">
Prefilled assistant responses on the last turn are no longer supported on Claude 4.6+ models; requests with a prefill return a 400 error. Replace each pattern with the corresponding alternative.

- Forcing JSON or other output shape: use Structured Outputs, or instruct the model to conform to the schema (recent models follow schemas reliably).
- Skipping preambles: add `Respond directly without preamble.` to the system prompt; or use Structured Outputs; or strip the preamble in post-processing.
- Steering around bad refusals: prompt clearly in the user message; recent models are much better at appropriate refusals.
- Continuations after interruption: move the continuation into a user message containing the truncated text.
- Context hydration: inject the refresh into a user-turn message, or hydrate via tool calls during context compaction.
</section>

<section name="user-facing-progress">
Opus 4.8 provides more regular, higher-quality progress updates throughout long agentic traces without scaffolding. If your prompt forces interim status messages ("after every 3 tool calls, summarize progress"), remove it; the natural updates are better.

If you need a specific update format, describe it explicitly and provide one or two examples.
</section>

<section name="frontend-aesthetics">
Opus 4.8 has strong design instincts with a persistent default house style: warm cream/off-white backgrounds (~`#F4F1EA`), serif display type (Georgia, Fraunces, Playfair), italic word-accents, and a terracotta/amber accent. It reads well for editorial, hospitality, and portfolio briefs but feels off for dashboards, dev tools, fintech, healthcare, or enterprise apps, and it shows up in slide decks as well as web UIs. Generic instructions like "don't use cream" or "make it clean" tend to swap one fixed palette for another rather than producing variety.

Two reliable counters:

1. Specify a concrete alternative palette, typography system, and layout rules. The model follows explicit specs precisely. For example: "Use a cold monochrome palette (`#E9ECEC`, `#C9D2D4`, `#8C9A9E`, `#44545B`, `#11171B`), a square angular sans-serif with wide letter-spacing, 4px corner radius, and generous whitespace."
2. Have the model propose 4 distinct visual directions (background hex, accent hex, typeface, one-line rationale) before building, then implement only the chosen direction. This produces meaningfully different runs and replaces the role that `temperature` once played for design variety.

Opus 4.8 needs less frontend prompting than previous models to avoid the generic "AI slop" aesthetic, so a short snippet is enough:

```xml
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white or dark backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character. Use unique fonts, cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```
</section>

<section name="code-review-harnesses">
Opus 4.8 is meaningfully better at finding bugs than prior models, with both higher recall and precision in internal evals. Harnesses tuned for earlier models may show measured recall regressions because the model follows severity filters faithfully: when a prompt says "only report high-severity issues" or "don't nitpick", it investigates just as thoroughly but reports fewer low-severity findings. This is a harness effect, not a capability regression. Move filtering out of the finding stage:

```text
Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage; a separate verification step will do that. Your goal here is coverage: it is better to surface a finding that later gets filtered out than to silently drop a real bug. For each finding, include your confidence level and an estimated severity so a downstream filter can rank them.
```

If you want single-pass filtering, define the bar concretely instead of with qualitative terms like "important": for example, "Report bugs that could cause incorrect behavior, a test failure, or a misleading result; only omit nits like pure style or naming preferences."
</section>

<section name="interactive-coding">
Opus 4.8 is more autonomous than prior models and uses more tokens in interactive, multi-turn coding settings because it reasons more after each user turn. To maximize both performance and token efficiency, specify the task, intent, and relevant constraints upfront in the first turn, prefer `xhigh` or `high` effort, add autonomous features like an auto mode, and reduce the number of required human interactions. Ambiguous prompts conveyed progressively over many turns tend to reduce token efficiency and sometimes performance.
</section>

<section name="model-identification">
For products that need the model to identify itself, add a short system-prompt line:

```text
The assistant is Claude, created by Anthropic. The current model is Claude Opus 4.8.
```

If the app needs the exact API model string:

```text
When an LLM is needed, default to Claude Opus 4.8 unless the user requests otherwise. The exact model string is claude-opus-4-8.
```
</section>

<section name="overengineering-guard">
Claude Opus 4.5 and Opus 4.6 tend to overengineer by adding files, abstractions, or flexibility that was not requested. Pin scope explicitly:

```text
Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused:

- Scope: do not add features, refactor code, or make improvements beyond what was asked. A bug fix does not need surrounding code cleaned up. A simple feature does not need extra configurability.
- Documentation: do not add docstrings, comments, or type annotations to code you did not change. Only add comments where the logic is not self-evident.
- Defensive coding: do not add error handling, fallbacks, or validation for scenarios that cannot happen. Trust internal code and framework guarantees. Validate only at system boundaries (user input, external APIs).
- Abstractions: do not create helpers, utilities, or abstractions for one-time operations. Do not design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task.
```
</section>

<section name="subagent-control">
Opus 4.8 tends to spawn fewer subagents by default, but the behavior is steerable. Give it explicit guidance about when subagents are desirable.

To scope subagents down:

```text
Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams that do not need to share state. For simple tasks, sequential operations, single-file edits, or tasks where you need to maintain context across steps, work directly rather than delegating.
```

To get more subagent fan-out:

```text
Spawn multiple subagents in the same turn when fanning out across items or reading multiple files. Do not spawn a subagent for work you can complete directly in a single response.
```
</section>

<section name="context-awareness">
Claude 4.5 and 4.6 models track their remaining context window. In harnesses that compact context or persist state to files (like Claude Code), tell the model so it does not stop early:

```text
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working from where you left off. Do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state before the context window refreshes. Complete tasks fully, even if the end of your budget is approaching.
```
</section>

<provenance>
Patterns above are condensed from the Anthropic prompting best-practices page: `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices.md`.
</provenance>
