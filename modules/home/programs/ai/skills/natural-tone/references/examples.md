# Natural Tone: worked examples

Twelve before/after pairs, grouped by the rule section in `SKILL.md` they
illustrate. Each `<example>` carries a `<bad>` version (the prose to fix),
a `<good>` version (the fix), and an `<analysis>` block explaining why
the first fails and the second works.

## Concrete over abstract

<examples>
  <example name="Filler adjectives">
    <bad>This README provides a comprehensive overview of the setup process.</bad>
    <good>This README covers installation, configuration, and the first run command.</good>
    <analysis>
    Why the first fails: "comprehensive" hides the scope instead of naming it.
    Why the second works: it tells the reader exactly what the document covers.
    </analysis>
  </example>

  <example name="Vague verbs">
    <bad>The service enables reliable communication between components.</bad>
    <good>The service queues events, retries failed deliveries, and stores a dead-letter record after the final retry.</good>
    <analysis>
    Why the first fails: "enables" and "reliable" describe the result without showing how the system behaves.
    Why the second works: it names the concrete actions that make the behavior reliable.
    </analysis>
  </example>

  <example name="Empty capability labels">
    <bad>Capabilities: Provides robust validation and high-quality reporting.</bad>
    <good>Validates required fields before saving and writes one error summary per failed import.</good>
    <analysis>
    Why the first fails: "robust" and "high-quality" are labels, not behaviors.
    Why the second works: it tells the reader what the feature does and when it does it.
    </analysis>
  </example>

  <example name="Generic hedging vs. bounded claim (technical)">
    <bad>This approach can be beneficial in many scenarios and may help improve overall efficiency.</bad>
    <good>This approach cuts one network round-trip per request. It works well for read-heavy endpoints but adds staleness risk on writes.</good>
    <analysis>
    Why the first fails: "many scenarios" and "may help" avoid naming where it works and where it breaks.
    Why the second works: it states the gain, the fit, and the tradeoff.
    </analysis>
  </example>

  <example name="Generic hedging vs. bounded claim (non-technical)">
    <bad>Switching vendors could potentially lead to cost savings in certain situations.</bad>
    <good>Switching to Vendor B saves $1,200/month on the current plan. The savings disappear above 50 seats because Vendor B charges per user.</good>
    <analysis>
    Why the first fails: "potentially" and "certain situations" avoid naming the condition.
    Why the second works: it gives the saving, the threshold, and the reason the saving stops.
    </analysis>
  </example>
</examples>

## Sentence mechanics

<examples>
  <example name="Hype without evidence">
    <bad>It should be noted that this dramatically improves performance across all scenarios.</bad>
    <good>This change removes one repeated database query from the request path. In local profiling, median response time dropped from 140 ms to 95 ms.</good>
    <analysis>
    Why the first fails: hedging and hype replace evidence.
    Why the second works: it gives a measured result and splits the claim across two short, focused sentences.
    </analysis>
  </example>

  <example name="Technical precision">
    <bad>The API returns a user-friendly error when validation fails.</bad>
    <good>The API returns HTTP 400 with a field-level error list when validation fails.</good>
    <analysis>
    Why the first fails: "user-friendly" says almost nothing about the actual response.
    Why the second works: it names the status code and the structure the caller can expect.
    </analysis>
  </example>
</examples>

## Rhythm and repetition

<examples>
  <example name="Redundant restatement (technical)">
    <bad>The cache reduces latency by storing responses locally. In other words, it keeps a copy of the data close to the caller so requests don't have to travel to the origin server.</bad>
    <good>The cache stores responses locally. Reads hit the cache first and fall back to the origin server on a miss.</good>
    <analysis>
    Why the first fails: the second sentence restates the first in different words instead of adding information.
    Why the second works: each sentence carries a distinct fact. The reader learns the lookup order, not just a paraphrase.
    </analysis>
  </example>

  <example name="Redundant restatement (non-technical)">
    <bad>The new policy reduces turnaround time. Essentially, requests are processed faster because fewer approvals are needed.</bad>
    <good>The new policy removes one approval step. Average turnaround dropped from five days to three.</good>
    <analysis>
    Why the first fails: "Essentially" introduces a restatement that adds no new information.
    Why the second works: the second sentence adds a measured result instead of rephrasing the first.
    </analysis>
  </example>

  <example name="Monotonous sentence openers">
    <bad>The system validates input. The system rejects malformed requests. The system logs each rejection. The system returns a 400 status code.</bad>
    <good>Input is validated on arrival. Malformed requests are rejected and logged. The caller gets a 400 with a field-level error list.</good>
    <analysis>
    Why the first fails: four consecutive sentences start with "The system". The structure is robotic.
    Why the second works: it varies the subject and merges related actions, which reads like a person wrote it.
    </analysis>
  </example>
</examples>

## Audience and structure

<examples>
  <example name="Padded list">
    <bad>Benefits include: faster builds, lower memory usage, and improved developer experience.</bad>
    <good>Builds finish in half the time. Peak memory dropped from 4 GB to 2.1 GB.</good>
    <analysis>
    Why the first fails: "improved developer experience" is padding to reach three items. It adds no testable claim.
    Why the second works: it lists the two real benefits with evidence and drops the filler third item.
    </analysis>
  </example>

  <example name="Consolation-clause concession">
    <bad>While this migration has some inherent complexity, it ultimately provides a more maintainable architecture.</bad>
    <good>The migration touches 14 files and takes roughly two days. After it lands, adding a new provider is a single-file change.</good>
    <analysis>
    Why the first fails: "some inherent complexity" hides the actual cost, and "ultimately provides" hides the actual gain.
    Why the second works: it names the cost (14 files, two days) and the payoff (single-file change) as separate, verifiable facts.
    </analysis>
  </example>
</examples>
