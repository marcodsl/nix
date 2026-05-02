---
name: natural-tone
description: "Write direct, human prose that replaces filler with concrete facts. Use when: editing docs, READMEs, technical notes, commit messages, PR descriptions, or tightening vague, hedged, promotional, or formulaic text."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: writing, editing, prose, documentation
---

# Natural Tone

## Purpose

Use this skill to rewrite prose so readers can see who does what, what changes, and why it matters. Replace filler, hedging, and generic claims with concrete actions, scope, and evidence.

## Scope

### Use this skill when

- Editing docs, READMEs, PR descriptions, commit messages, release notes, issue summaries, and other narrative text.
- Rewriting text that sounds vague, hedged, promotional, or formulaic.
- Tightening technical notes, API docs, and user-facing explanations so claims are easier to verify.

### Do not use this skill when

- Designing prompts, agent instructions, or system-instruction architecture. Use `prompt-engineering` for prompt structure and agent behavior. Use this skill to tighten the prose inside those artifacts.
- Defining API contracts, schema semantics, or implementation behavior where the main task is design accuracy rather than prose quality.
- Writing terse labels, identifiers, or machine-oriented fields where exact syntax matters more than tone or flow.

## Governing rule

Name the actor, the action, and the result. If a word does not change the meaning, delete it or replace it with a concrete fact.

## Core policy rules

1. Replace filler adjectives with explicit scope.

- Replace "comprehensive" with what is covered.
- Replace "robust" with the concrete guarantee or behavior.
- Replace "seamless" with the actual user impact.

2. Replace vague verbs with direct actions.

- Prefer "use", "send", "store", "validate", "reject", "render", or "return".
- Avoid verbs that hide the actor, such as "facilitate" or "enable", unless you also name who does what.

3. Remove hedging and hype.

- Delete openers like "It should be noted that" or "This aims to".
- Replace claims like "dramatically improves" with measured outcomes or bounded statements.

4. Keep one core claim per sentence.

- Split chained claims into shorter sentences.
- Put important facts first.
- Move caveats later if the sentence still reads cleanly.

5. Keep prose mechanically clean.

- Use ASCII punctuation.
- Avoid em dashes and trailing semicolons in prose.
- Avoid stacked adjectives before a noun.
- Prefer plain transitions over filler bridges like "Additionally" when a simpler sentence works.

6. State each claim once.

- Say it once. If the reader needs more context, add a new fact, not a paraphrase.
- Delete "In other words", "To put it simply", and "Essentially" when they introduce a restatement.

7. Replace generic hedging with a bounded claim or an explicit stance.

- "This can be beneficial in many scenarios" hides the scope. Write "This is a reasonable default for teams under 10 engineers" or name the actual constraint.
- Trust the reader to ask. Address objections when the reader raises them, not preemptively.

8. Vary sentence rhythm and structure.

- Follow a long sentence with a short one.
- Break a list with a direct statement when it sharpens the point.
- Drop into a question when it focuses the reader better than a declaration.
- Avoid repeating the same clause pattern across consecutive sentences.

9. Diversify sentence openers.

- Limit consecutive same-opener sentences to two. Rewrite at least one using a verb, object, condition, or dependent clause.
- Watch for runs of "This [noun] [verb]s", "The [noun] [verb]s", or "By [verb]-ing". Rewrite at least one.
- Start with the verb, the object, a condition, or a dependent clause when it reads more naturally.

10. Match context length to what the reader does not already know.

- If the reader is reviewing a PR, they know the repo. Skip the project summary.
- If the reader is in an API doc, they know HTTP. Don't explain what a status code is.
- Over-explaining shared context signals that the writer doesn't know the audience.

11. State tradeoffs directly.

- State the cost and the benefit as separate claims. Either order works. Merging them into one hedged sentence does not.

12. Use the natural count in lists.

- If the real count is two, list two. If it is five, list five.
- Use the natural count. Readers notice when the third item is filler or when meaningful items are missing.

13. Vary paragraph structure.

- Not every paragraph needs a topic sentence followed by support followed by a summary.
- Some paragraphs work better starting with evidence, a constraint, or a question.
- Uniform paragraph shape across a document is a readability problem even when individual sentences are good.

14. Keep register consistent within a section.

- Keep formal and informal tone separate. "Utilize" next to "cool" breaks trust.
- Pick a register that fits the audience and hold it. Shift between sections if the audience context changes, not mid-thought.

## Technical terms and exceptions

Use technical terms when they improve precision for the intended audience.

- Keep domain terms such as "idempotent", "eventual consistency", or "domain-specific" when replacing them would make the text less exact.
- Keep protocol names, error classes, measured values, and implementation constraints when they carry real meaning.
- Preserve details that change the behavior, limits, or risks being described.

## Common filler and replacements

| Filler pattern                                   | Replace with                                                  |
| ------------------------------------------------ | ------------------------------------------------------------- |
| "leverage" or "utilize"                          | "use"                                                         |
| "facilitate communication"                       | the concrete action, such as "send messages between services" |
| "seamless"                                       | the actual user impact                                        |
| "high-quality"                                   | the quality signal, metric, or guarantee                      |
| "comprehensive"                                  | the exact scope or covered components                         |
| "scalable"                                       | the workload, limit, or growth behavior                       |
| "Furthermore" / "Moreover" / "It's worth noting" | delete, or start the next sentence directly                   |
| "This ensures that" / "This allows for"          | name what actually happens                                    |
| "In other words" / "To put it simply"            | delete the restatement                                        |
| "In terms of"                                    | name the dimension directly, such as "latency" or "cost"      |
| "While X has limitations, it provides..."        | state the cost and the benefit as separate claims             |
| "By [verb]-ing..., we can..." (repeated)         | vary the opener; start with the result or a condition         |

## Examples

### Example 1: Filler adjectives

Bad: "This README provides a comprehensive overview of the setup process."

Good: "This README covers installation, configuration, and the first run command."

Why it fails: "comprehensive" hides the scope instead of naming it.

Why it works: it tells the reader exactly what the document covers.

### Example 2: Vague verbs

Bad: "The service enables reliable communication between components."

Good: "The service queues events, retries failed deliveries, and stores a dead-letter record after the final retry."

Why it fails: "enables" and "reliable" describe the result without showing how the system behaves.

Why it works: it names the concrete actions that make the behavior reliable.

### Example 3: Empty capability labels

Bad: "Capabilities: Provides robust validation and high-quality reporting."

Good: "Validates required fields before saving and writes one error summary per failed import."

Why it fails: "robust" and "high-quality" are labels, not behaviors.

Why it works: it tells the reader what the feature does and when it does it.

### Example 4: Hype without evidence

Bad: "It should be noted that this dramatically improves performance across all scenarios."

Good: "This change removes one repeated database query from the request path. In local profiling, median response time dropped from 140 ms to 95 ms."

Why it fails: hedging and hype replace evidence.

Why it works: it gives a measured result and context.

### Example 5: Technical precision

Bad: "The API returns a user-friendly error when validation fails."

Good: "The API returns HTTP 400 with a field-level error list when validation fails."

Why it fails: "user-friendly" says almost nothing about the actual response.

Why it works: it names the status code and the structure the caller can expect.

### Example 6: Redundant restatement (technical)

Bad: "The cache reduces latency by storing responses locally. In other words, it keeps a copy of the data close to the caller so requests don't have to travel to the origin server."

Good: "The cache stores responses locally. Reads hit the cache first and fall back to the origin server on a miss."

Why it fails: the second sentence restates the first in different words instead of adding information.

Why it works: each sentence carries a distinct fact. The reader learns the lookup order, not just a paraphrase.

### Example 7: Redundant restatement (non-technical)

Bad: "The new policy reduces turnaround time. Essentially, requests are processed faster because fewer approvals are needed."

Good: "The new policy removes one approval step. Average turnaround dropped from five days to three."

Why it fails: "Essentially" introduces a restatement that adds no new information.

Why it works: the second sentence adds a measured result instead of rephrasing the first.

### Example 8: Generic hedging vs. bounded claim (technical)

Bad: "This approach can be beneficial in many scenarios and may help improve overall efficiency."

Good: "This approach cuts one network round-trip per request. It works well for read-heavy endpoints but adds staleness risk on writes."

Why it fails: "many scenarios" and "may help" avoid naming where it works and where it breaks.

Why it works: it states the gain, the fit, and the tradeoff.

### Example 9: Generic hedging vs. bounded claim (non-technical)

Bad: "Switching vendors could potentially lead to cost savings in certain situations."

Good: "Switching to Vendor B saves $1,200/month on the current plan. The savings disappear above 50 seats because Vendor B charges per user."

Why it fails: "potentially" and "certain situations" avoid naming the condition.

Why it works: it gives the saving, the threshold, and the reason the saving stops.

### Example 10: Monotonous sentence openers

Bad: "The system validates input. The system rejects malformed requests. The system logs each rejection. The system returns a 400 status code."

Good: "Input is validated on arrival. Malformed requests are rejected and logged. The caller gets a 400 with a field-level error list."

Why it fails: four consecutive sentences start with "The system". The structure is robotic.

Why it works: it varies the subject and merges related actions, which reads like a person wrote it.

### Example 11: Padded list

Bad: "Benefits include: faster builds, lower memory usage, and improved developer experience."

Good: "Builds finish in half the time. Peak memory dropped from 4 GB to 2.1 GB."

Why it fails: "improved developer experience" is padding to reach three items. It adds no testable claim.

Why it works: it lists the two real benefits with evidence and drops the filler third item.

### Example 12: Consolation-clause concession

Bad: "While this migration has some inherent complexity, it ultimately provides a more maintainable architecture."

Good: "The migration touches 14 files and takes roughly two days. After it lands, adding a new provider is a single-file change."

Why it fails: "some inherent complexity" hides the actual cost, and "ultimately provides" hides the actual gain.

Why it works: it names the cost (14 files, two days) and the payoff (single-file change) as separate, verifiable facts.

## AI structural tells

Scan for these patterns before shipping. Each one signals machine-generated text.

1. Three or more consecutive sentences starting with "The" or "This".
2. Every paragraph follows topic-sentence / support / summary.
3. Lists always have exactly three items.
4. Concessions use "While X, it Y" structure.
5. Transitions are always "Additionally", "Furthermore", or "Moreover".
6. Every claim is hedged with "can", "may", or "potentially".
7. Register shifts mid-paragraph (formal next to colloquial).
8. Sentences are roughly the same length throughout.
9. The text restates a point in different words right after making it.
10. Context is explained that the target reader already knows.
11. Adjectives stack before nouns: "a robust, scalable, enterprise-grade solution".
12. The conclusion mirrors the introduction almost word for word.

## Verification checklist

- [ ] Each claim names an actor and an action.
- [ ] Filler terms are removed or replaced with specific facts.
- [ ] Performance claims include evidence, a metric, or a bounded qualifier.
- [ ] Technical jargon is kept only when it improves precision for the target audience.
- [ ] Sentences are short, direct, and focused on one main claim.
- [ ] Prose uses ASCII punctuation and avoids em dashes and trailing semicolons.
- [ ] No sentence restates a previous claim in different words.
- [ ] Hedged claims are replaced with bounded qualifiers or explicit stances.
- [ ] Sentence length and structure vary across consecutive sentences.
- [ ] No more than two consecutive sentences share the same opener word or structure.
- [ ] Context explanations are proportional to what the reader does not already know.
- [ ] Tradeoffs are stated as separate cost and benefit claims, not merged into consolation clauses.
- [ ] Lists use the natural item count, not padded or trimmed to three.
- [ ] Paragraph structure varies across the document.
- [ ] Register stays consistent within each section.
