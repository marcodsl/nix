---
description: Reflect on the current session — what went wrong, what worked, what's worth remembering — and propose additions to project memory (CLAUDE.md / AGENTS.md / GEMINI.md, preferring private/override variants like `CLAUDE.local.md` or `AGENTS.override.md`) or to the user-level auto-memory.
---

You are running `/retro`. The point of this command is to let lessons from the current session "echo" into durable memory so the next session in this project starts smarter.

Work through the phases below in order. Do not modify any files until Phase 4, and not until the user has explicitly approved.

## Phase 0 — Detect target file

Look in the current working directory (the project root) for a project-scoped memory file. Check in this precedence (private/override variants first within each ecosystem):

1. `CLAUDE.local.md` — Claude private.
2. `CLAUDE.md` — Claude public.
3. `AGENTS.override.md` — Codex documented override.
4. `AGENTS.md` — Codex public.
5. `GEMINI.md` — Gemini CLI public.

Pick the first one that exists as the **candidate target**. If several exist, prefer the highest-precedence one and note the others in your proposal so the user can override.

If none exist, record "no project-memory file" and continue. You will offer alternatives in Phase 3 rather than creating a file silently.

## Phase 1 — Reflect on the session

Review the current conversation transcript and produce a structured reflection with three buckets:

- **What went wrong** — dead-ends, wrong assumptions, failed commands, friction the user had to correct.
- **What worked** — approaches the user validated, commands or patterns that succeeded, judgment calls that paid off (watch for quiet confirmations as well as explicit praise).
- **Worth remembering** — project conventions, non-obvious gotchas, key file paths or commands, constraints surfaced during the session.

Apply the same exclusion rules the global auto-memory system uses (see `~/.claude/CLAUDE.md`):

- Skip anything derivable from current code, file paths, or git history.
- Skip debug recipes or specific fixes (the fix is in the commit; the commit message explains it).
- Skip ephemeral task state and in-progress work.

Duplicate-suppression against the candidate target file happens in Phase 2, once you have actually read it. Do not try to anticipate it here.

Phrase each kept item as a short rule or fact, followed by two short lines:

- **Why:** the underlying reason (constraint, prior incident, strong preference) so future readers can judge edge cases.
- **How to apply:** when and where this guidance kicks in.

This mirrors the structure used by the existing feedback/project auto-memories so output stays consistent across the two systems.

## Phase 2 — Read the existing target (if any)

If Phase 0 found a candidate target, read it. Drop any Phase 1 findings already covered there — even partially. Do not paraphrase existing content back in.

If Phase 0 found nothing, skip this phase.

## Phase 3 — Present the proposal

Surface to the user, in this order:

1. **Target file**: the detected candidate (with a note if multiple files exist and you picked one), or the "no project-memory file" finding.
2. **Reflection summary**: the three buckets from Phase 1, with empty buckets shown as empty (a clean session is signal, not failure).
3. **Proposed additions**: show the lines to append, anchored under the section heading they would land in, with one or two surrounding lines for orientation. If the file does not yet exist, show the full proposed content inside a fenced markdown code block. Each entry uses the rule → **Why:** → **How to apply:** structure from Phase 1.
4. **Optional auto-memory route**: for findings that are about the user or cross-project rather than this project specifically, propose saving them to `~/.claude/projects/<project-slug>/memory/` instead, citing the memory type (`user` / `feedback` / `project` / `reference`). Resolve `<project-slug>` by listing `~/.claude/projects/` and matching the entry that corresponds to the current working directory (the convention is the absolute path with `/` and `.` replaced by `-`, e.g. `/home/marco/.config/nixos` becomes `-home-marco--config-nixos`).

If no project-memory file exists in the project, do **not** create one silently. Offer three options:

- Create `CLAUDE.md` at the project root.
- Save the salient findings to auto-memory only (no project file).
- Skip persistence entirely for this session.

Then stop and wait for the user.

## Phase 4 — Apply after approval

Only after the user has explicitly approved (or selected one of the options above):

- Append to (or `Edit`-merge into an existing section of) the chosen target file.
- And/or write auto-memory entries using the standard format (per-memory file with `name` / `description` / `metadata.type` frontmatter, plus a one-line pointer added to `MEMORY.md`).

Never bypass this approval gate. Never edit files in Phases 0–3. Never write to the global `~/.claude/CLAUDE.md` from this command — it is project-scoped.

## Hard constraints

- The command operates entirely on what is already in context. No web search, no codebase indexing, no spawned subagents.
- Honor the global auto-memory exclusion rules — derivable facts (code patterns, file paths, git history, debug recipes) do not go into either project memory or auto-memory.
- Present-then-approve is the whole flow. If the user wants a write-immediately variant, that is a different command.
