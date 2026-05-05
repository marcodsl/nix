# D2 Syntax Cheatsheet

On-demand reference for the D2 (`d2lang.com`) language. Use it when the SKILL.md rules do not give enough surface for the diagram you are authoring.

## Object declaration

```d2
# Just a key — renders as a rectangle with the key as label
api

# Key with explicit label
api: API Server

# Key with shape and label via block
db: {
  shape: cylinder
  label: PostgreSQL
}
```

Keys are case-insensitive. Quote keys that contain spaces, dots, or reserved punctuation: `"my key": ...`.

## Connections

- `a -> b` — directed
- `a <- b` — directed reverse
- `a <-> b` — bidirectional
- `a -- b` — undirected
- `a -> b -> c -> d` — chained
- `a -> b: label text` — with label
- `a -> a: retry` — self-loop

Arrowheads (set on the connection block; arrowheads are objects with their own `shape`):

```d2
api -> db: query {
  source-arrowhead.shape: cf-many
  target-arrowhead.shape: cf-one
}
```

Available arrowhead shapes: `triangle`, `arrow`, `diamond`, `filled-diamond`, `circle`, `filled-circle`, `box`, `cf-one`, `cf-many`, `cf-one-required`, `cf-many-required`, `cross`.

## Containers

```d2
# Block syntax
cluster: {
  api
  db: { shape: cylinder }
  api -> db
}

# Dot notation
cluster.cache: { shape: cylinder }
cluster.api -> cluster.cache

# Reference parent from inside a block
cluster: {
  api -> _.outside
}
outside
```

Pick one syntax per parent and stick to it within a file.

## Shape catalog

Geometric: `rectangle` (default), `square`, `circle`, `oval`, `diamond`, `parallelogram`, `hexagon`, `triangle`.

Containers and infrastructure: `cylinder`, `queue`, `package`, `step`, `callout`, `stored_data`, `cloud`.

People and documents: `person`, `c4-person`, `document`, `page`, `note`, `folder`.

Specialty (drive distinctive layout):

- `sql_table` — ER table; children are rows.
- `sequence_diagram` — actors and messages with vertical lifelines.
- `class` — UML class with members.
- `image` — pure image node, requires `icon:`.
- `text` — plain label, no border.

Use specialty shapes when the diagram class genuinely matches; do not pick `cloud` or `person` decoratively.

## Style keys

Set on `shape.style` or `connection.style`:

- Color and fill: `fill`, `fill-pattern` (`dots`, `lines`, `grain`, `paper`, `none`), `stroke`, `stroke-width` (1–15), `stroke-dash` (0–10).
- Border: `border-radius` (0–20), `double-border` (bool).
- Text: `font` (currently `mono`), `font-size` (8–100), `font-color`, `bold`, `italic`, `underline`, `text-transform` (`uppercase`, `lowercase`, `title`, `none`).
- Effects: `opacity` (0–1), `shadow` (bool), `3d` (rectangles/squares only), `multiple` (bool, draws as a stack), `animated` (bool, animates connections), `filled` (bool, controls fill on shapes that default to outline).

Root-level styling for the whole diagram:

```d2
style: {
  fill: "#F8F8F8"
  stroke: "#333"
  stroke-width: 2
}
```

## Variables

```d2
vars: {
  brand: "#4F46E5"
  tier-fill: "#E0E7FF"
}

api.style.fill: ${tier-fill}
api.style.stroke: ${brand}
```

Reference variables with `${name}`. Variables are resolved at parse time.

## Theme overrides

Override the active theme's palette at file level:

```d2
theme-overrides: {
  B1: "#4F46E5"
  B2: "#818CF8"
  AA2: "#1E1B4B"
}

dark-theme-overrides: {
  B1: "#A5B4FC"
  B2: "#6366F1"
}
```

Common keys: `B1`–`B6` (base palette), `AA2`, `AA4`, `AA5` (accent), `AB4`, `AB5` (alt accent), `N1`–`N7` (neutral grays).

## Imports

```d2
# Assign import to a key
shared: @palette.d2

# Spread import into the current scope (only inside a map)
...@actors.d2

# Partial import via dot path
managers: @people.managers
```

Paths resolve relative to the importing file. `.d2` extension is optional; the formatter strips it.

## Globs

```d2
# Style every direct child shape
*.style.fill: "#FAFAFA"

# Recursive style for all descendants
**.style.stroke-width: 2

# Filter — only cylinders get this fill
*: {
  &shape: cylinder
  style.fill: "#E0E7FF"
}

# Negated filter — non-leaf shapes
*: {
  !&leaf: true
  style.fill: "#F4F4F5"
}

# Edge glob — style every connection in the file
(* -> *)[*]: {
  style.stroke-width: 2
}
```

Filter predicates use the `&` prefix inside the glob's map: `&shape`, `&connected`, `&leaf`, attribute matches like `&style.fill: "#FFF"`. Negate with `!&`.

## Sequence diagrams

```d2
flow: {
  shape: sequence_diagram

  alice
  bob
  store

  alice -> bob: hello
  bob -> store: lookup(id)
  store -> bob: row
  bob -> alice: greeting

  retry: {
    bob -> store: lookup(id)
    store -> bob: row
  }

  branch: {
    "if cached": {
      bob -> alice: cached value
    }
    "else": {
      bob -> store: lookup(id)
      store -> bob: row
      bob -> alice: fresh value
    }
  }
}
```

Definition order is render order. Nested blocks render as fragments (`alt`, `loop`, `opt`); the block key becomes the fragment label. Quote keys with spaces or punctuation.

## SQL tables

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  email: varchar(255) {constraint: unique}
  created_at: timestamp
}

posts: {
  shape: sql_table
  id: int {constraint: primary_key}
  user_id: int {constraint: foreign_key}
  title: varchar(255)
}

users.id -> posts.user_id
```

`constraint` value can be a single keyword or a list: `{constraint: [primary_key; unique]}`. Recognized constraints render as PK / FK / UNQ badges.

## Class diagrams

```d2
Animal: {
  shape: class

  +name: string
  +age: int
  -secret: string
  #protectedField: bool
  ~packageField: bool

  +speak(): void
  +move(distance\: int): void
}

Dog: {
  shape: class
  +breed: string
  +bark(): void
}

Dog -> Animal: { target-arrowhead.shape: triangle }
```

Visibility: `+` public, `-` private, `#` protected, `~` package.

## Markdown, code, and LaTeX labels

```d2
notes: |md
# Heading

- Bullet one
- Bullet two

**Bold** and *italic*.
|

example: |`ts
interface User {
  id: string
  email: string
}
`|

formula: |latex
E = mc^2
|
```

Code blocks support most Chroma languages (`ts`, `js`, `py`, `go`, `rs`, `sql`, `bash`, ...). LaTeX renders via MathJax in SVG/PDF only.

## Icons and images

```d2
lambda: {
  label: Lambda
  icon: https://icons.terrastruct.com/aws/Compute/AWS-Lambda.svg
}

logo: {
  shape: image
  icon: ./assets/logo.png
}
```

Icons attach to a shape; `shape: image` makes the icon the entire node.

## Direction and grids

```d2
# File-level direction (dagre/elk)
direction: right

# Per-shape direction (tala only)
container: {
  direction: down
  a -> b
}

# Grid layout (tala only)
grid: {
  grid-rows: 2
  grid-columns: 3
  cell1; cell2; cell3
  cell4; cell5; cell6
}
```

`direction` accepts `right` (default), `down`, `left`, `up`.

## Comments

```d2
# Line comment
"""
Block comment
spanning multiple lines.
"""
```

## CLI essentials

- `d2 input.d2 output.svg` — compile.
- `d2 --watch input.d2 output.svg` — live preview.
- `d2 --layout=elk input.d2 out.svg` — pick engine; `dagre` (default), `elk`, `tala`.
- `d2 --theme N input.d2 out.svg` — theme; `d2 --theme list` to enumerate.
- `d2 --dark-theme N input.d2 out.svg` — dark-mode theme.
- `d2 --sketch input.d2 out.svg` — sketch render.
- `d2 --pad N input.d2 out.svg` — output padding.
- `d2 fmt input.d2` — autoformat in place.
- `d2 fmt --check input.d2` — exit non-zero if formatting would change.

Environment: `D2_LAYOUT`, `D2_THEME` set defaults.
