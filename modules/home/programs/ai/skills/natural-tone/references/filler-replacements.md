# Natural Tone: filler patterns and replacements

Quick reference for the most common filler patterns and what to put in their
place. The replacement column names the move, not a fixed string; pick the
concrete fact, action, or measurement that fits the sentence.

- "leverage" / "utilize" → "use"
- "facilitate communication" → the concrete action, e.g. "send messages between services"
- "seamless" → the actual user impact
- "high-quality" → the quality signal, metric, or guarantee
- "comprehensive" → the exact scope or covered components
- "scalable" → the workload, limit, or growth behavior
- "robust" → the concrete guarantee or behavior
- "Furthermore" / "Moreover" / "It's worth noting" → delete, or start the next sentence directly
- "This ensures that" / "This allows for" → name what actually happens
- "In other words" / "To put it simply" / "Essentially" → delete the restatement
- "In terms of" → name the dimension directly, e.g. "latency" or "cost"
- "While X has limitations, it provides..." → state cost and benefit as separate claims
- "By [verb]-ing..., we can..." (repeated) → vary the opener; start with the result or a condition
- em dash (—) mid-sentence or as clause bridge → period, comma, or restructured sentence

## Edge cases

- Keep "comprehensive" or "scalable" when the rest of the sentence already
  names the scope or workload they qualify. The fix is for cases where the
  adjective stands alone as the only claim.
- "Enable" is fine when the actor is named and the action is concrete
  ("the proxy enables clients to reuse a single TLS session"). Replace it
  when it hides the actor ("the new design enables better performance").
- Some hedges carry real meaning. "may" is correct for genuinely uncertain
  outcomes; "can" is correct for capability statements. The rule targets
  hedges that hide a missing claim, not hedges that report real uncertainty.
