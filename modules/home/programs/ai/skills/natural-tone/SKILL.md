---
name: natural-tone
description: "Edit prose so it reads as human, not AI-generated: replace filler, hedging, marketing voice, and AI tells (em dashes, monotonous openers, padded three-item lists, restated claims, stacked adjectives) with concrete actors, scoped claims, and evidence. Triggers: tightening READMEs, PR descriptions, commit-message bodies, release notes, issue summaries, code comments, Slack or email drafts, or any AI-generated text that sounds robotic, formulaic, hedged, promotional, or vague. Skip when: defining API contracts, or writing terse labels/identifiers where exact syntax matters more than tone."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: writing, editing, prose, documentation
  version: 3
---

# Natural Tone

<purpose>
Rewrite prose so readers can see who does what, what changes, and why it matters. Replace filler, hedging, and generic claims with concrete actions, scope, and evidence.
</purpose>

<scope>
  <use_when>
  - Editing docs, READMEs, PR descriptions, commit messages, release notes, issue summaries, and other narrative text.
  - Rewriting text that sounds vague, hedged, promotional, or formulaic.
  - Tightening technical notes, API docs, and user-facing explanations so claims are easier to verify.
  - Editing code comments or inline documentation where the comment explains intent, behavior, or rationale in prose.
  - Editing AI-generated drafts, model responses, or chatbot output that sounds robotic, formulaic, or vague.
  - Tightening short-form copy: Slack messages, emails, release notes, or social posts.
  </use_when>

  <do_not_use_when>
  - Defining API contracts, schema semantics, or implementation behavior where the main task is design accuracy rather than prose quality.
  - Writing terse labels, identifiers, table cells, diagram labels, or machine-oriented fields where exact syntax matters more than tone or flow.
  </do_not_use_when>
</scope>

<governing_rule>
Name the actor, the action, and the result. If a word does not change the meaning, delete it or replace it with a concrete fact. If the sentence already names actor, action, and result without filler, leave it unchanged. If no edits are needed across the entire input, confirm the text is already optimized and return it as is.

**Why:** filler is not just decorative. It forces the reader to guess what the writer means, and it is the single biggest reason prose reads as machine-generated.
</governing_rule>

<working_method>
1. Read each sentence and check that actor, action, and result are present.
2. Apply the four rule sections below as patterns to spot. Use whichever matches; the rules do not override one another.
3. Before shipping, scan for AI structural tells (see `references/ai-structural-tells.md`).
4. Run the review checklist.
</working_method>

<section name="concrete-over-abstract">
- Replace filler adjectives with explicit scope. "Comprehensive" becomes the list of covered topics; "robust" becomes the concrete guarantee; "seamless" becomes the specific user outcome. **Why:** filler adjectives are labels, not claims. They tell the reader the writer believes the thing is good without naming what makes it good.
- Replace vague verbs with direct actions and name the actor. Prefer "use", "send", "store", "validate", "reject", "render", "return". Avoid verbs that hide the actor, such as "facilitate" or "enable". **Why:** agentless or abstract verbs leave the reader to guess who does what. Naming the actor and a concrete verb removes one guess per sentence.
- Cut hedging and hype; replace generic claims with bounded ones. Delete openers like "It should be noted that" or "This aims to". Replace "dramatically improves" with a measured outcome. Replace "can be beneficial in many scenarios" with the actual constraint or fit. **Why:** unbounded claims cannot be verified or falsified. Bounded claims invite scrutiny, which is what readers trust.

See `references/filler-replacements.md` for the full pattern → replacement list.
</section>

<section name="sentence-mechanics">
- Keep one core claim per sentence. Split chained claims into shorter sentences. Put the important fact first; move caveats later if the sentence still reads cleanly. **Why:** chained claims hide the structure of the argument. One claim per sentence lets the reader follow and challenge each link.
- Use ASCII punctuation. Never use em dashes (—); replace with a period, a comma, or a restructured sentence. Em dashes are a strong signal of machine-generated text.
- Pick the one adjective that earns its keep; replace the others with the concrete attribute they were gesturing at. Prefer plain transitions over filler bridges like "Additionally" when a simpler sentence works. **Why:** stacked adjectives stack vague claims. Picking one forces the writer to decide which property actually matters.
</section>

<section name="rhythm-and-repetition">
- State each claim once. If the reader needs more context, add a new fact, not a paraphrase. Delete restatement openers like "In other words", "To put it simply", or "Essentially". **Why:** paraphrase reads as padding because it adds words without adding information. The reader notices and starts skimming.
- Vary sentence length and structure across consecutive sentences. Follow a long sentence with a short one. Break a list with a direct statement when it sharpens the point. **Why:** uniform sentence length flattens emphasis. Varying length tells the reader which sentences carry the load.
- Limit consecutive same-opener sentences to two. Watch for runs of "This [noun] [verb]s", "The [noun] [verb]s", or "By [verb]-ing"; rewrite at least one using a verb, object, condition, or dependent clause. **Why:** uniform openers are one of the strongest signals of machine-generated text. They appear because the model defaults to the same grammatical pivot when it has nothing structural to vary.
</section>

<section name="audience-and-structure">
- Match context length to what the reader does not already know. Skip the project summary in a PR; skip the HTTP primer in an API doc. Over-explaining shared context signals that the writer does not know the audience.
- State tradeoffs directly. Name the cost and the benefit as separate claims. Either order works; merging them into a single consolation clause does not. **Why:** consolation clauses ("while X, it Y") compress a real tradeoff into a rhetorical move. The reader needs both numbers to make the decision, not a feel-good resolution.
- Use the natural count in lists. List two when the real count is two, five when it is five. Readers notice when an item is filler or when meaningful items are missing.
- Vary paragraph structure across the document. Not every paragraph needs topic sentence, support, summary. Some paragraphs work better starting with evidence, a constraint, or a question. **Why:** uniform paragraph shape is itself a tell. It signals the writer applied a template instead of asking what each paragraph needs.
- Keep register consistent within a section. "Utilize" next to "cool" breaks trust. Shift register between sections if the audience context changes, not mid-thought.
</section>

<section name="technical-terms">
Use technical terms when they reduce ambiguity or align with domain-specific terminology for the intended audience. For mixed audiences, keep the technical term and add a short plain-language gloss in parentheses on first use.

- Keep domain terms such as "idempotent", "eventual consistency", or "domain-specific" when replacing them would make the text less exact.
- Keep protocol names, error classes, measured values, and implementation constraints when they carry real meaning.
- Preserve details that change the behavior, limits, or risks being described.
</section>

<review_checklist>
- [ ] Each claim names an actor and an action.
- [ ] Performance and behavior claims carry evidence, a metric, or a bounded qualifier.
- [ ] Tradeoffs read as separate cost and benefit claims, not consolation clauses.
- [ ] Lists use the natural item count.
- [ ] Register stays consistent within each section.
- [ ] `references/ai-structural-tells.md` scanned; no two or more patterns trip in the same passage. The scan covers em dashes, restatement, uniform sentence length and openers, over-explained shared context, and other pattern-level tells; the items above stay because they require reading for meaning rather than matching a pattern.
</review_checklist>

<bundled_resources>
- `references/examples.md`: twelve before/after worked examples grouped by rule section, with "why it fails" and "why it works" commentary.
- `references/filler-replacements.md`: pattern → replacement bullet list plus edge-case notes.
- `references/ai-structural-tells.md`: thirteen patterns to scan before shipping.
</bundled_resources>
