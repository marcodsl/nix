# MCP Memory Server

Use the MCP memory server to preserve durable context that improves future work. Treat it as a supplement to current repository evidence and direct user instructions, not as a source of truth that overrides them.

## When to read memory

Read memory when prior context could change the work you do now. Typical cases:

- user preferences that affect output style or workflow
- stable project conventions that are not obvious from one file
- recurring people, systems, or services that show up across tasks
- long-lived goals or constraints that may shape implementation decisions

Prefer targeted retrieval.

- Use `search_nodes` when you need to find relevant entities by name, type, or observation text.
- Use `open_nodes` when you already know which entities you want to inspect.
- Use `read_graph` only when broad graph inspection is justified.

Do not fetch memory by default on every turn. Retrieve only when the expected value is higher than the added noise.

## What to store

Store facts that are durable, reusable, and likely to matter in later sessions.

- user preferences, habits, and communication constraints
- stable project conventions or repository-specific rules
- recurring collaborators, teams, organizations, or systems
- long-lived goals, responsibilities, and relationships

Do not store:

- secrets, credentials, tokens, keys, or private material
- one-off task state, scratch notes, or temporary debugging details
- volatile facts that are likely to change soon
- information that is too vague to help future decisions

If a fact would not be worth reading again later, do not write it to memory.

## How to model facts

The server stores a knowledge graph with entities, relations, and observations.

- Create entities for people, teams, repositories, services, projects, and significant recurring events.
- Store one fact per observation. Keep observations atomic so they can be added or removed independently.
- Write relations in active voice, such as `works_on`, `owns`, `prefers`, or `depends_on`.
- Reuse consistent entity names so later retrieval stays precise.

When new durable context arrives:

- Use `create_entities` for new nodes.
- Use `create_relations` for durable links between nodes.
- Use `add_observations` for new facts on existing entities.

Use delete operations sparingly. `delete_entities`, `delete_relations`, and `delete_observations` are for correcting stale or wrong memory, not routine cleanup.

## Decision rule

Before writing memory, ask two questions:

1. Will this still matter in a future session?
2. Would retrieving it later improve the quality or speed of the work?

If either answer is no, skip the write.

## Priority order

When deciding what to capture, prefer:

1. stable user preferences and constraints
2. durable repository or project conventions
3. recurring entities and their relationships
4. long-lived goals that shape future work

Use memory to carry forward durable context. Use the repo, tests, and current user instructions to decide what is true right now.
