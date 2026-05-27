---
name: d2-diagrams
description: "Write and review D2 diagrams so they compile and read clearly: pick layout engine, shape, container nesting, and styling intentionally. Triggers: `.d2` files, `d2 fmt`, `d2lang.com`, choosing between `dagre`/`elk`/`tala`, `sql_table` ER diagrams, `sequence_diagram`, `@file` imports, `vars`/theme overrides, converting ASCII or Mermaid to D2. Skip when: the project's documented tool is Mermaid, PlantUML, Graphviz, or hand-drawn SVG and migration is not the task, or the work is theming the D2 renderer rather than authoring diagram source."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: d2, d2lang, diagrams, dataviz, architecture-diagrams, sequence-diagrams, er-diagrams
  version: 3
---

# D2 Diagrams

<purpose>
Author or review `.d2` files where idiomatic structure beats merely-compiling syntax. Pick the layout engine and shape vocabulary that surface the diagram's intent, keep styling subordinate to comprehension, and validate by formatting and compiling before declaring done.
</purpose>

<scope>
  <use_when>
  - Writing a new `.d2` file for an architecture, sequence, ER, class, or flow diagram.
  - Reviewing an existing `.d2` file for layout, label, or styling problems.
  - Converting an ASCII sketch or a Mermaid diagram to D2.
  - Choosing between dagre, elk, and tala.
  - Building shared diagram sets with `vars`, theme overrides, or `@file` imports.
  </use_when>

  <do_not_use_when>
  - The project's documented diagramming tool is Mermaid, PlantUML, Graphviz, or hand-drawn SVG and the task is not to migrate.
  - The task is theming the D2 renderer or building a D2 toolchain integration rather than authoring source.
  </do_not_use_when>
</scope>

<governing_rule>
A diagram exists to communicate one specific thing. Pick the shape, container, engine, and styling that make that thing visible, and do nothing else.
</governing_rule>

<working_method>
1. Investigate the surrounding diagram surface: read existing `.d2` files, reuse `vars`, theme overrides, engine pin, and key conventions. If a comment or CI step pins the engine, respect it. If shared definitions exist (`@actors.d2`, `@palette.d2`), import them.
2. Pick the layout engine deliberately. State the engine in a header comment when the file depends on a non-default engine. Never use tala-only syntax under dagre or elk.
3. Pick the shape vocabulary. The default shape is `rectangle`; never write `shape: rectangle`.
4. Keep styling subordinate to comprehension.
5. Format and compile before declaring done.
</working_method>

<section name="layout-engines">
- dagre (default): flowcharts, small architecture diagrams, anything that fits a single hierarchical pass.
- elk: deep nested containers (more than two levels) or many parallel edges that dagre tangles. Supports container width/height and renders nesting cleanly.
- tala: only when the diagram needs a tala-only feature: `near` for fixed-position legends/titles, `grid-rows`/`grid-columns`, exact-row connections on `sql_table`, or per-shape `direction`. Tala is proprietary and may be unavailable. Declare the engine in a header comment when the choice is load-bearing.
</section>

<section name="shapes">
- Default is `rectangle`. Never write `shape: rectangle`.
- Use `sql_table` for ER diagrams, `sequence_diagram` for interaction flows, `class` for OO structure, `image` to embed an external icon.
- Reach for specialty shapes (`cloud`, `cylinder`, `queue`, `person`, `step`, `document`, `package`, `hexagon`) only when the metaphor materially aids reading. Do not decorate with shape variety.
- `circle` and `square` preserve 1:1 aspect ratio; long labels grow them in both dimensions. Prefer `oval` or `rectangle` when the label exceeds a word or two.
</section>

<section name="containers">
- Start flat. Introduce a container only when inner nodes share a real boundary or nesting visibly reduces edge crossings.
- Cap nesting at three levels.
- Use block syntax `parent: { child1; child2 }` for many children at once. Use dot notation `parent.child` for one-off external references. Never mix the two for the same parent.
- Use `_` to reference the parent from inside a block (`child -> _.sibling`).
- Set an explicit `label:` when the container key is a path-style identifier; otherwise the long key leaks into the rendered label.
</section>

<section name="connections-and-labels">
- Label every connection that crosses a container boundary, carries a non-default protocol, or sits inside a `sequence_diagram`. Bare arrows are acceptable only when there is one connection type and context makes it obvious.
- Pick the arrow that carries the right semantics: `->` for directed flow, `<->` for genuinely bidirectional channels, `--` for undirected, `<-` only when reverse reads better. Do not use `<->` for uncertainty.
- Customize arrowheads (`source-arrowhead`, `target-arrowhead`) only when the default does not convey the relationship (`cf-many` on an FK row, `triangle` for inheritance).
- When the endpoint is a deeply nested key, set an explicit `label:` so the rendering hides the dotted path.
</section>

<section name="styling">
- Cap distinct visual treatments at three; each must carry semantic meaning (external/internal, primary/secondary, etc.).
- Move shared style values into `vars` or `theme-overrides` when the same value appears three or more times. Never inline the same `style` block twice.
- Do not set `font-size` per shape; adjust globally via `theme-overrides`.
- Use `style.opacity`, `style.stroke-dash`, and `style.fill-pattern` sparingly.
- Reserve `style.animated`, `style.3d`, and `style.shadow` for cases where the effect adds information.
</section>

<section name="vars-imports-globs">
- Introduce `vars` when a value (color, label fragment, URL) repeats three or more times. Inline one-off values.
- Use `@file` imports for shared actor definitions, color palettes, or icon URLs. Do not split a single self-contained diagram for symmetry.
- Pair recursive `**` globs with a filter (`*: { &shape: cylinder; style.fill: ... }`) or an explicit scope. Bare `**` at file root is forbidden.
- Name the intent in a comment when filters like `&connected` or `&leaf` are non-obvious.
</section>

<section name="labels">
- Use heredoc `label: |md ... |` only when the label needs multi-line content, links, or formatting.
- Triple-backtick code blocks render as syntax-highlighted code.
- LaTeX renders via MathJax in SVG but not PNG. Output must be SVG (or PDF) when LaTeX is present.
- Non-Latin characters and emoji are supported without escaping.
</section>

<section name="sequence-diagrams">
- Definition order is render order. Declare actors top-to-bottom in intended visual order.
- Connections inside a `sequence_diagram` must reference shapes defined inside that block; pointing outside silently creates a new actor (almost always a bug).
- Use nested blocks for groups (`alt`, `else`, `loop`, `opt`); the block label becomes the fragment label.
- Self-messages (`alice -> alice: ...`) render as a self-loop; keep them meaningful, not decorative.
</section>

<section name="sql-tables">
- `sql_table` rows: `id: int {primary_key: true}`, `email: varchar(255) {unique: true}`. Connect rows directly: `users.id -> posts.user_id`.
- Under tala, connections land on the exact row; under dagre and elk, on the table edge. Use tala when row-level precision matters.
- Quote SQL reserved words used as identifiers: `"order": int`.
</section>

<section name="anti-patterns">
- Redundant `shape: rectangle` declarations.
- Dotted-path keys leaking into rendered labels because no explicit `label:` was set.
- Sequence-diagram connections silently spawning new actors via undeclared paths.
- Bare arrows where the connection type is non-obvious or the diagram has multiple connection semantics.
- Five or more distinct fill colors with no semantic mapping.
- Repeated inline `style` blocks that belong in `vars` or theme overrides.
- Mixed dot- and block-notation for the same parent in one file.
- Recursive `**` globs at file root with no filter.
- Containers nested four or more levels deep.
- Specialty shapes (`cloud`, `cylinder`, `person`) used decoratively.
- Tala-only syntax (`near`, `grid-rows`, `grid-columns`) under dagre or elk.
- `|...|` markdown labels around single-line plain text.
- PNG output for a diagram that contains LaTeX.
</section>

<section name="verification">
1. Format: `d2 fmt <file>.d2`. The formatter is the source of truth.
2. Compile: `d2 <file>.d2 /tmp/<file>.svg`. The diagram must render without warnings.
3. Visual sanity: open the rendered output and confirm layout, label legibility, and edge routing match intent.
4. Engine confirmation: when a non-default engine is required, confirm the file or its build context declares it.

If `d2` is not on PATH:
1. If `devenv.nix` exists: `devenv -O packages:pkgs "d2" shell -- d2 <file>.d2 /tmp/out.svg`.
2. Otherwise: `nix run nixpkgs#d2 -- <file>.d2 /tmp/out.svg`.
</section>

<review_checklist>
- `d2 fmt` reports no changes.
- The file compiles without warnings to the target format.
- The layout engine is appropriate; tala-only features are not used under dagre or elk.
- Every cross-boundary or non-obvious connection carries an explicit label.
- No `shape: rectangle` declarations remain.
- Container nesting is at most three levels and each level maps to a real boundary.
- Distinct visual treatments are bounded (≤3) and each has semantic meaning.
- Sequence-diagram actors are declared in render order; no accidental external connections.
- Repeated values live in `vars` or theme overrides; globs use filters or explicit scopes.
- Output format matches the content (SVG when LaTeX is present).
</review_checklist>

<bundled_resources>
- `references/syntax-cheatsheet.md` — full shape catalog, style keys, glob filters, variable and import forms, sequence-diagram and `sql_table` shorthand, class visibility markers.
- `references/pattern-templates.md` — four compile-tested templates (architecture under dagre, sequence with `alt`, ER with `sql_table` under tala, tala grid topology), each annotated with the choices it makes.
</bundled_resources>
