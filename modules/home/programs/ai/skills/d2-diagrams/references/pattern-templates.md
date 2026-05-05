# D2 Pattern Templates

Compile-tested templates for the four diagram classes most often asked of D2. Each template is followed by a short note on the choices it makes — engine, shape vocabulary, container depth, label discipline. Copy and adapt rather than reinvent.

## 1. Three-tier architecture (dagre)

```d2
# layout: dagre

vars: {
  external-fill: "#FEF3C7"
  internal-fill: "#E0E7FF"
  data-fill: "#DCFCE7"
}

direction: down

users: Users
cdn: CDN
api: API
worker: Worker
db: {
  shape: cylinder
  label: PostgreSQL
}
queue: {
  shape: queue
  label: Redis Stream
}

users -> cdn: HTTPS
cdn -> api: HTTPS
api -> db: SQL
api -> queue: enqueue
worker -> queue: dequeue
worker -> db: SQL

users.style.fill: ${external-fill}
cdn.style.fill: ${external-fill}
api.style.fill: ${internal-fill}
worker.style.fill: ${internal-fill}
db.style.fill: ${data-fill}
queue.style.fill: ${data-fill}
```

Notes: dagre handles the single-pass top-to-bottom layout cleanly. Three semantic colors map to the three tiers (external, internal, data); shared in `vars` so a palette change is one edit. Specialty shapes (`cylinder`, `queue`) appear only where the metaphor adds reading value. Every connection carries a label so the protocol or operation is explicit.

## 2. Sequence diagram with `alt` branch

```d2
checkout: {
  shape: sequence_diagram

  user: User
  web: Web App
  api: API
  cache: Cache
  db: Database

  user -> web: click checkout
  web -> api: POST /checkout
  api -> cache: get cart(user_id)

  cart_branch: {
    "if cache hit": {
      cache -> api: cart
    }
    "else": {
      cache -> api: miss
      api -> db: SELECT cart
      db -> api: cart
      api -> cache: SET cart
    }
  }

  api -> db: INSERT order
  db -> api: order_id
  api -> web: 200 OK
  web -> user: confirmation
}
```

Notes: actors are declared in the visual order they should appear left-to-right. The nested `cart_branch` block renders as an `alt` fragment with `if`/`else` arms. Every message is labeled — bare arrows are not acceptable in sequence diagrams. No styling: the diagram class already carries strong visual structure.

## 3. ER schema with `sql_table` (elk)

```d2
# layout: elk

direction: right

users: {
  shape: sql_table

  id: int {constraint: primary_key}
  email: varchar(255) {constraint: unique}
  created_at: timestamp
}

orders: {
  shape: sql_table

  id: int {constraint: primary_key}
  user_id: int {constraint: foreign_key}
  total_cents: int
  created_at: timestamp
}

order_items: {
  shape: sql_table

  id: int {constraint: primary_key}
  order_id: int {constraint: foreign_key}
  product_id: int {constraint: foreign_key}
  quantity: int
}

products: {
  shape: sql_table

  id: int {constraint: primary_key}
  sku: varchar(64) {constraint: unique}
  name: varchar(255)
  price_cents: int
}

users.id -> orders.user_id: {
  source-arrowhead.shape: cf-one
  target-arrowhead.shape: cf-many
}

orders.id -> order_items.order_id: {
  source-arrowhead.shape: cf-one
  target-arrowhead.shape: cf-many
}

products.id -> order_items.product_id: {
  source-arrowhead.shape: cf-one
  target-arrowhead.shape: cf-many
}
```

Notes: elk lays out the four tables and their FK edges more cleanly than dagre when the diagram has four-plus tables with crossing relations. Arrowheads use `cf-one`/`cf-many` to make cardinality explicit at both ends — the diagram should be readable without an external legend. Constraint badges (PK, FK, UNQ) come from the `{constraint: ...}` annotation, not from labels.

## 4. Nested microservices topology (elk)

```d2
# layout: elk

direction: down

edge: Edge {
  load_balancer: Load Balancer
  cdn: CDN
}

services: Services {
  auth: Auth
  catalog: Catalog
  orders: Orders
  payments: Payments
}

data: Data {
  postgres: {
    shape: cylinder
    label: PostgreSQL
  }
  redis: {
    shape: cylinder
    label: Redis
  }
  events: {
    shape: queue
    label: Kafka
  }
}

edge.load_balancer -> services.auth
edge.load_balancer -> services.catalog
edge.load_balancer -> services.orders
edge.cdn -> services.catalog: cache miss

services.auth -> data.redis: session
services.auth -> data.postgres: users
services.catalog -> data.postgres: products
services.orders -> data.postgres: orders
services.orders -> services.payments: charge
services.orders -> data.events: order_created
services.payments -> data.events: payment_processed
```

Notes: elk handles the three-deep container nesting (root → tier → service) without the edge tangle dagre tends to produce in this shape. Containers carry real boundaries (network edge, business services, data plane); without those boundaries, the diagram would be a flat hairball. Cross-tier connections all carry labels because they cross container boundaries; intra-tier edges (none here) would be allowed to go bare.

## Choosing among these templates

- Linear flow with a clear hierarchy: template 1 (dagre).
- Time-ordered interaction between named participants: template 2 (sequence_diagram).
- Tables and foreign keys: template 3 (elk + sql_table).
- More than two container levels or many parallel cross-tier edges: template 4 (elk).

If the diagram needs a fixed-position legend (`near`), grid layout (`grid-rows`/`grid-columns`), or row-precise sql_table connections, switch to tala and declare the engine in a header comment so the choice is load-bearing.
