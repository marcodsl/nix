---
name: let-fate-decide
description: "Draw 4 Tarot cards with real crypto-random entropy to break a tie when prompts are vague or casually delegated, then map the spread to a concrete next step. Triggers: 'let fate decide', 'YOLO', 'whatever', 'up to you', 'idk', 'surprise me', 'dealer's choice', 'I trust you', 'doesn't matter', 'wing it', 'heart of the cards', 'it's time to duel', or when you are about to arbitrarily pick between 2+ reasonable approaches. Skip when: the user gave clear instructions, or the task is safety-critical (security, data integrity, prod deploy)."
allowed-tools: Bash Read Grep Glob
license: CC-BY-SA-4.0
metadata:
  author: trailofbits
  source: https://github.com/trailofbits/skills/tree/main/plugins/let-fate-decide/skills/let-fate-decide
  tags: arbitration, randomness, tarot, decision-making, playful
  version: 3
---

# Let Fate Decide

<purpose>
Inject real entropy into a casual or ambiguous decision by drawing a 4-card Tarot spread and mapping the interpretation to a concrete next step.
</purpose>

<scope>
  <use_when>
  - Vague prompts where multiple reasonable approaches exist.
  - Explicit invocations: "I'm feeling lucky", "let fate decide", "dealer's choice", "surprise me", "whatever you think", "YOLO".
  - Casual delegation: "whatever", "up to you", "your call", "idk", "just do something", "wing it", "I trust you", "doesn't matter", "any approach works", "you pick".
  - Yu-Gi-Oh energy: "Heart of the cards", "you've activated my trap card", "it's time to duel".
  - Shrug-like brevity: very short prompts that fully delegate without expressing a preference.
  - Redraw requests ("try again", "draw again") when no system changes occurred — draw new cards, do not re-run the same approach.
  - Tie-breaking: when about to arbitrarily pick between 2+ valid approaches.
  </use_when>

  <do_not_use_when>
  - The user has given clear, specific instructions.
  - The task has a single obvious correct approach.
  - Safety-critical decisions (security, data integrity, production deployments).
  - The user explicitly asks not to use Tarot.
  </do_not_use_when>
</scope>

<governing_rule>
The draw must come from real entropy. Never fake a draw or simulate randomness; if the script fails, tell the user. Cards inform direction; they never override user requirements, safety, or correctness.
</governing_rule>

<working_method>
1. Run the drawing script:
   ```bash
   uv run --no-config ~/.claude/skills/let-fate-decide/scripts/draw_cards.py
   ```
2. Read each drawn card's meaning file (paths returned by the script, relative to `~/.claude/skills/let-fate-decide/`). Read all four in parallel when possible.
3. Synthesize the spread using `references/INTERPRETATION_GUIDE.md`.
4. Output the interpretation alongside the tool call that implements the chosen option. Never end a turn with interpretation as text only.
</working_method>

<section name="spread">
Four positions:
1. The Context — What is the situation really about?
2. The Challenge — What obstacle or tension exists?
3. The Guidance — What approach should be taken?
4. The Outcome — Where does this path lead?
</section>

<section name="deck-layout">
Card meanings live under `~/.claude/skills/let-fate-decide/cards/`:
- `cards/major/` — 22 Major Arcana (archetypal forces).
- `cards/wands/` — 14 Wands (creativity, action, will).
- `cards/cups/` — 14 Cups (emotion, intuition, relationships).
- `cards/swords/` — 14 Swords (intellect, conflict, truth).
- `cards/pentacles/` — 14 Pentacles (material, practical, craft).
</section>

<section name="interpretation-rules">
- Reversed cards invert or complicate the upright meaning, not "do nothing".
- Major Arcana cards carry more weight than Minor Arcana.
- Read the spread as one story across all four positions; do not interpret cards in isolation.
- Map abstract meanings to concrete technical decisions.
</section>

<section name="error-handling">
- Script crashes: report the error and skip the reading. Do not invent cards.
- Card file missing: interpret from name and suit alone, continue the reading.
- Never simulate entropy from your own "randomness".
</section>

<section name="rationalizations">
Reject these:
- "The cards said to, so I must" — cards inform direction; they do not override safety or correctness.
- "This reading justifies my pre-existing preference" — be honest if the reading challenges your instinct.
- "The reversed card means do nothing" — reversed means a different angle, not inaction.
- "Major Arcana overrides user requirements" — user requirements always take priority.
- "I'll keep drawing until I get what I want" — one draw per decision point; accept the reading.
</section>

<section name="how-it-works">
The script uses Python's `secrets` for cryptographic randomness:
1. Builds a 78-card deck (22 Major + 56 Minor).
2. Fisher-Yates shuffle via `secrets.randbelow()` (no modulo bias).
3. Draws 4 cards from the top.
4. Each card independently has a 50% chance of being reversed.
</section>

<section name="example">
User: "I dunno, just make it work somehow"

Draw:
1. The Magician (upright) — Context: all tools are available.
2. Five of Swords (reversed) — Challenge: let go of a combative approach.
3. The Star (upright) — Guidance: follow the aspirational path.
4. Ten of Pentacles (upright) — Outcome: long-term stability.

Interpretation: You have what you need (Magician). Avoid overengineering or adversarial thinking about edge cases (Five of Swords reversed). Follow the clean, hopeful approach (Star) and build for lasting maintainability (Ten of Pentacles).

Approach: implement the simplest correct solution with clear structure, prioritizing long-term readability over clever optimizations.
</section>

<bundled_resources>
- `references/INTERPRETATION_GUIDE.md` — full interpretation workflow.
- `cards/{major,wands,cups,swords,pentacles}/*.md` — per-card meaning files.
- `scripts/draw_cards.py` — the drawing script.
</bundled_resources>
