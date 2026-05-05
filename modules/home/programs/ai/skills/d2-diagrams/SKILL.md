---
name: d2-diagrams
description: "Write and review D2 diagrams with the right layout engine, shape choice, and styling discipline so diagrams compile and read clearly. Use when: authoring or editing `.d2` files, converting ASCII or Mermaid to D2, choosing between dagre/elk/tala, or building shared diagram sets with variables and imports."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: d2, d2lang, diagrams, dataviz, architecture-diagrams, sequence-diagrams, er-diagrams
---

# D2 Diagrams

Rules for writing and reviewing D2 (`d2lang.com`) source so diagrams compile, read clearly, and pick the shape, container, and layout engine that match the communication goal.

## Purpose

Use this skill to author or review `.d2` files where idiomatic structure beats merely-compiling syntax. Pick the layout engine and shape vocabulary that surface the diagram's intent, keep styling subordinate to comprehension, and validate by formatting and compiling before declaring done.

## Scope

### Use this skill when

- Writing a new `.d2` file for an architecture, sequence, ER, class, or flow diagram.
- Reviewing an existing `.d2` file for layout, label, or styling problems.
- Converting an ASCII sketch or a Mermaid diagram to D2.
- Choosing between dagre, elk, and tala for a given diagram.
- Building shared diagram sets with `vars`, theme overrides, or `@file` imports.

### Do not use this skill when

- The project's documented diagramming tool is Mermaid, PlantUML, Graphviz, or hand-drawn SVG and the task is not to migrate.
- The task is theming the D2 renderer or building a D2 toolchain integration rather than authoring diagram source.
- A narrower domain skill already governs the file (e.g. a project-specific architecture-doc skill) and the request does not call for D2-specific judgment.

## Governing rule

A diagram exists to communicate one specific thing. Pick the shape, container, engine, and styling that make that thing visible, and do nothing else.

## Investigation before changes

Read the surrounding diagram surface before authoring or editing.

1. List existing `.d2` files in the repo and read at least one. Reuse its `vars`, theme overrides, engine pin, and key conventions instead of inventing parallel ones.
2. If a comment, build script, or CI step pins the layout engine (`d2 --layout=elk`, `D2_LAYOUT=tala`, etc.), respect it. Do not silently change engines.
3. If shared definitions exist (`@actors.d2`, `@palette.d2`, etc.), import them rather than redefining their contents.

## Layout engine selection

Pick the engine deliberately and only switch engines when the diagram requires it.

- **dagre** (default): flowcharts, small architecture diagrams, anything that fits a single hierarchical pass. Fast and ubiquitous.
- **elk**: deep nested containers (more than two levels) or many parallel edges that dagre tangles; supports container width/height and renders nested structures more cleanly.
- **tala**: only when the diagram requires a tala-only feature — `near` for fixed-position legends/titles, `grid-rows`/`grid-columns` for grid layouts, exact-row connections on `sql_table`, or per-shape `direction`. Tala is proprietary and may be unavailable; if the diagram needs it, declare the engine in a header comment so the choice is load-bearing and visible.

State the engine in a comment at the top of any file that depends on a non-default engine. Do not use tala-only syntax under dagre or elk.

## Shape selection

- The default shape is `rectangle`. Never write `shape: rectangle`.
- Use `sql_table` for entity-relationship diagrams, `sequence_diagram` for interaction flows, `class` for OO structure diagrams, `image` to embed an external icon as a standalone node.
- Reach for specialty shapes (`cloud`, `cylinder`, `queue`, `person`, `step`, `document`, `package`, `hexagon`) only when the shape's metaphor materially aids reading. Do not decorate with shape variety.
- `circle` and `square` preserve a 1:1 aspect ratio; long labels make them grow in both dimensions. Prefer `oval` or `rectangle` when the label is more than one or two words.

## Containers and structure

- Start flat. Introduce a container only when (a) the inner nodes share a real boundary (subsystem, namespace, deployment unit, network zone) or (b) nesting visibly reduces edge crossings.
- Cap nesting at three levels. Beyond that, layout engines place poorly and readers lose the boundary cues.
- Use block syntax `parent: { child1; child2 }` when defining many children at once. Use dot notation `parent.child` for one-off references from outside the block. Do not mix the two for the same parent in the same file.
- Use `_` to reference the parent container from inside a block when a connection must cross out: `child -> _.sibling`.
- Set an explicit `label:` on a container when its key is a path-style identifier; otherwise the long key leaks into the rendered label.

## Connections and labels

- Label every connection that (a) crosses a container boundary, (b) carries a non-default protocol or medium, or (c) sits inside a `sequence_diagram`. Bare arrows (`a -> b`) are acceptable only when the diagram has one connection type and the surrounding context makes it obvious.
- Pick the arrow that carries the right semantics: `->` for directed flow, `<->` for genuinely bidirectional channels, `--` for undirected relationships, `<-` only when reverse direction reads better than restating the source. Do not use `<->` as shorthand for "I'm not sure."
- Customize arrowheads (`source-arrowhead`, `target-arrowhead`) only when the default does not convey the relationship — for example `cf-many` on an FK row, or `triangle` for inheritance.
- When a connection's endpoint is a deeply nested key, assign an explicit `label:` so the rendering does not show the dotted path.

## Styling discipline

- Cap distinct visual treatments at three. More than three colors or fill-patterns becomes noise; each treatment must carry a semantic meaning (external/internal/highlighted, primary/secondary/disabled, etc.).
- Move shared style values into `vars` or `theme-overrides` when the same value appears three or more times. Never inline the same `style` block twice.
- Do not set `font-size` per shape. Adjust globally via `theme-overrides` or accept defaults.
- Use `style.opacity`, `style.stroke-dash`, and `style.fill-pattern` sparingly — each is a strong signal and loses meaning if applied indiscriminately.
- Reserve `style.animated`, `style.3d`, and `style.shadow` for cases where the effect adds information rather than decoration.

## Variables, imports, globs

- Introduce `vars` when a value (color, label fragment, URL) repeats three or more times in one file. For one-off values, inline them.
- Use `@file` imports when a diagram set shares actor definitions, color palettes, or icon URLs across files. Do not split a single self-contained diagram across files for symmetry's sake.
- Globs are for rule-like styling, not for hiding edits. Always pair a recursive `**` glob with a filter (`*: { &shape: cylinder; style.fill: ... }`) or an explicit container scope. Bare `**` at file root is forbidden.
- Filters like `&connected` and `&leaf` are powerful — name the intent in a comment when the filter is non-obvious.

## Markdown and code labels

- Use heredoc `label: |md ... |` only when the label genuinely needs multi-line content, links, or formatting. For a single line of plain text, set `label: ` directly.
- Triple-backtick code blocks render as syntax-highlighted code; use them for snippets, not for prose paragraphs.
- LaTeX renders via MathJax in SVG output but not in PNG. If the diagram contains LaTeX, the output target must be SVG (or PDF).
- Non-Latin characters and emoji are supported in labels without escaping.

## Sequence diagrams

- Definition order is render order. Declare actors top-to-bottom in the order they should appear visually.
- Connections inside a `sequence_diagram` block must reference shapes defined inside that block. Pointing to an outside actor silently creates a new actor with the dotted-path name — almost always a bug.
- Use nested blocks for groups (`alt`, `else`, `loop`, `opt`); the block label becomes the fragment label.
- A self-message (`alice -> alice: ...`) renders as a self-loop; keep these meaningful, not decorative.

## SQL tables

- Use `sql_table` for ER diagrams. Each child is a row: `id: int {primary_key: true}`, `email: varchar(255) {unique: true}`. Connect rows directly: `users.id -> posts.user_id`.
- Under tala, connections land on the exact row; under dagre and elk, they land on the table edge. Use tala for ER diagrams when row-level connection precision matters.
- Quote SQL reserved words used as identifiers: `"order": int`.

## Patterns to correct

- Redundant `shape: rectangle` declarations.
- Long dotted-path keys leaking into rendered labels because no explicit `label:` was set.
- Connections inside a `sequence_diagram` block silently spawning new actors via undeclared paths.
- Bare arrows where the connection type is non-obvious or where the diagram has multiple connection semantics.
- Five or more distinct fill colors with no semantic mapping.
- Repeated inline `style` blocks that should live in `vars` or theme overrides.
- Dot-notation and block-notation mixed for the same parent in the same file.
- Recursive globs (`**`) at file root with no filter.
- Containers nested four or more levels deep.
- Sequence-diagram actors declared out of intended render order.
- Specialty shapes (`cloud`, `cylinder`, `person`) used decoratively rather than for their metaphor.
- Tala-only syntax (`near`, `grid-rows`, `grid-columns`) under dagre or elk.
- `|...|` markdown labels around single-line text that needed no formatting.
- PNG output chosen for a diagram that contains LaTeX.

## Verification defaults

Treat D2 work as incomplete until the file formats and compiles cleanly.

1. **Format**: run `d2 fmt <file>.d2`. The formatter is the source of truth for whitespace, key ordering, and import-extension normalization. Do not hand-format around its choices.
2. **Compile**: run `d2 <file>.d2 /tmp/<file>.svg` (or the project's chosen output path and format). The diagram must render without warnings.
3. **Visual sanity**: open the rendered output and confirm that the layout, label legibility, and edge routing match the intent. Compilation is necessary but not sufficient.
4. **Engine confirmation**: if a non-default engine is required, confirm the file declares it (header comment, build script, or `D2_LAYOUT` env) so the diagram does not silently render under the wrong engine elsewhere.

If `d2` is not on PATH, pick the runner by what the working directory provides:

1. If `devenv.nix` exists, use `devenv -O packages:pkgs "d2" shell -- d2 <file>.d2 /tmp/out.svg`.
2. Otherwise, fall back to `nix run nixpkgs#d2 -- <file>.d2 /tmp/out.svg`.

## Verification checklist

- [ ] `d2 fmt` reports no changes (or its changes have been applied and re-reviewed).
- [ ] The file compiles without warnings to the target format.
- [ ] The layout engine is appropriate for the diagram class; tala-only features are not used under dagre or elk.
- [ ] Every cross-boundary or non-obvious connection carries an explicit label.
- [ ] No `shape: rectangle` declarations remain.
- [ ] Container nesting is at most three levels and each level corresponds to a real boundary.
- [ ] Distinct visual treatments are bounded (≤3) and each carries a semantic meaning.
- [ ] Sequence-diagram actors are declared in render order; no connection points outside the block by accident.
- [ ] Repeated values are extracted into `vars` or theme overrides; globs use filters or explicit scopes.
- [ ] Output format matches the diagram's content (SVG when LaTeX is present).

## Bundled resources

Read these on demand when the loaded rules are not enough:

- `references/syntax-cheatsheet.md` — full shape catalog, style-key list, glob filters, variable and import forms, sequence-diagram and `sql_table` shorthand, class visibility markers.
- `references/pattern-templates.md` — four compile-tested templates (architecture under dagre, sequence with `alt`, ER with `sql_table` under tala, tala grid topology), each annotated with the choices it makes.
