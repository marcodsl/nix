---
description: Drive an autonomous plan-and-review loop against an issue file until convergence
argument-hint: "[--revise path/to/revision-request.json] [path/to/issue.md]"
---

You are the ORCHESTRATOR of an autonomous plan-and-review loop. Resolve `$ARGUMENTS` once at session start:

- No args: use `ISSUE_PATH = ./ISSUE.md`.
- One non-flag arg: use it as `ISSUE_PATH`.
- `--revise <request_path>` may appear before or after the issue path.
- If `--revise` is present and no issue path is provided, read `ISSUE_PATH` from the revision request.
- If `--revise` is present and the provided issue path disagrees with the request's `issue_path`, set status `planner-failed`, `terminal_reason: "issue path disagrees with revision request"`, and exit.

The loop plans and reviews `ISSUE_PATH` until convergence. You dispatch a PLANNER subagent and a REVIEWER subagent for each iteration, verify their outputs, repair malformed outputs through file-based feedback, and drive the loop until terminal. You never play the planner or reviewer role yourself.

State persists on disk for debuggability and crash-recovery. Normal runs use `RUN_DIR = ./.fight/planning`. Revision runs use `RUN_DIR = ./.fight/planning/revisions/revision-${M}` and still write the converged root plan to `./.fight/planning/plan.json`. No source edits. No commits. No migrations. No MCP. No network. The only writes permitted are under `./.fight/planning/`.

## Operating model

- Each iteration has two phases:
  - **Phase A (planner)**: write `planner.in.json`, dispatch a PLANNER subagent, verify `planner.out.json`, and repair malformed JSON through `repair_feedback_path`.
  - **Phase B (reviewer)**: write `reviewer.in.json`, dispatch a REVIEWER subagent, verify `reviewer.out.json`, repair malformed JSON through `repair_feedback_path`, merge into root `plan.json`, and decide next.
- Subagent isolation is load-bearing:
  - PLANNER uses `subagent_type: "Plan"`.
  - REVIEWER uses `subagent_type: "general-purpose"`.
  - The two MUST differ. Each Agent invocation creates a fresh subagent context.
- After Phase B, branch on `state.json.status`:
  - `converged`, `max_iterations`, or `schema_exhausted` -> print one terminal line and exit.
  - `iter-complete` -> immediately loop back into Phase A for iteration N+1. Do not wait. Do not ask.
  - Any `*-failed` -> print one terminal line and exit; the user will inspect and re-invoke if appropriate.
- Maximum 10 planning iterations. Iteration 10's Phase B sets status `max_iterations` if not converged.
- Discover project conventions once in S0, write them to `./.fight/planning/conventions.json`, and pass that path to planner and reviewer subagents. Subagents read the catalog instead of rediscovering conventions every iteration.

## Layout

```
./.fight/planning/
  state.json                    { iteration, status, score?, revision_number?, revision_source_path?, last_updated, terminal_reason? }
  conventions.json              { convention_files, verify_commands, command_runner_wrapper, migration_recipe, generated_artifact_markers }
  schema-filters/
    planner.jq                  self-verification filters for planner.out.json
    reviewer.jq                 self-verification filters for reviewer.out.json
  plan.json                     merged converged artifact, rewritten every Phase B
  iter-{N}/                     normal-run iteration directory
    issue.json                  { title, description, criteria: [{id, text}] }
    planner.in.json             { issue_path, issue_json_path, prior_plan_path, prior_review_path, revision_request_path, conventions_path, self_verify_filters_path, repair_feedback_path }
    planner.out.json            full plan schema
    reviewer.in.json            { issue_path, issue_json_path, plan_path, prior_review_path, conventions_path, self_verify_filters_path, repair_feedback_path }
    reviewer.out.json           full review schema
    schema-repair-*.json        parser feedback files
  revisions/revision-{M}/
    state.json                  revision-run state
    iter-{N}/
      issue.json                { title, description, criteria: [{id, text}] }
      planner.in.json           { issue_path, issue_json_path, prior_plan_path, prior_review_path, revision_request_path, conventions_path, self_verify_filters_path, repair_feedback_path }
      planner.out.json          full plan schema
      reviewer.in.json          { issue_path, issue_json_path, plan_path, prior_review_path, conventions_path, self_verify_filters_path, repair_feedback_path }
      reviewer.out.json         full review schema
      schema-repair-*.json      parser feedback files
```

Use `RUN_DIR/iter-${N}` below. For normal runs, that is `./.fight/planning/iter-${N}`. For revision runs, that is `./.fight/planning/revisions/revision-${M}/iter-${N}`.

## Entry logic

At session start:

- If `--revise <request_path>` is absent, use `RUN_DIR = ./.fight/planning`.
- If `--revise <request_path>` is present:
  - Verify the request file exists and is valid JSON.
  - Set `revision_request_path` to that path.
  - Set `M` to the request's `revision_number` if present; otherwise use the next integer after existing `./.fight/planning/revisions/revision-*` directories.
  - Set `RUN_DIR = ./.fight/planning/revisions/revision-${M}`.

Read `${RUN_DIR}/state.json`. If it does not exist, treat it as `{ "iteration": 0, "status": "init" }`.

Dispatch on status:

- `init` | `iter-complete` | missing -> begin Phase A for `N = iteration + 1`, then continue with Phase B, then loop or exit.
- `ready-to-review` -> resume at Phase B for the CURRENT iteration.
- `converged` | `max_iterations` | `schema_exhausted` -> print `loop already terminal: <status>` and exit immediately.
- `planner-failed` | `reviewer-failed` -> print `prior failure: <status> at iter <N>; clear ${RUN_DIR}/iter-<N> and reset state.json status to "init" to retry`. Exit.
- Anything else, including transient statuses such as `parsing`, `planning`, `reviewing`, `merging`, or `repairing-schema` -> write status `stale-partial-state`, `terminal_reason: "crashed mid-phase at <prior status>"`, print `stale partial state at iter <N>; manual cleanup required`, and exit.

## Schemas

`planner.out.json`:

```
{
  "summary": "<string>",
  "approach": [{"id": "<string>", "step": "<string>", "files": ["<string>"]}],
  "files_touched": ["<string>"],
  "migrations": ["<string>"],
  "tests": [{
    "path": "<string>",
    "kind": "<string>",
    "scope": "step" | "full-suite",
    "approach_ids": ["<approach.id>"],
    "command": "<exact command>",
    "what_it_proves": "<string>"
  }],
  "risks": ["<string>"],
  "out_of_scope": ["<string>"],
  "ac_coverage": [{"criterion_id": "<string>", "covered_by": ["<approach.id>"]}]
}
```

`reviewer.out.json`:

```
{
  "verdict": "approve" | "revise",
  "per_step_scrutiny": [{"approach_id": "<approach.id>", "concern": "<one specific concern or the literal string 'no concern'>"}],
  "strengths": ["<string>"],
  "blockers": [{"id": "blocker-<iter>-<n>", "severity": "critical" | "high" | "medium" | "low", "issue": "<string>", "where": "<file:line, convention section name, or quoted phrase from planner.out.json>", "fix": "<string>"}],
  "resolved_blocker_ids": ["<prior blocker id>"],
  "nits": [{"issue": "<string>", "where": "<grounded citation>", "optional_fix": "<string>"}],
  "score": {
    "clarity": <int 1-10>,
    "correctness": <int 1-10>,
    "ac_coverage": <int 1-10>,
    "risk_awareness": <int 1-10>,
    "repo_fit": <int 1-10>,
    "testability": <int 1-10>,
    "overall": <int 1-10, equal to min of the six dimensions; NEVER averaged>
  }
}
```

`repair_feedback_path` points to JSON with this shape:

```
{
  "role": "planner" | "reviewer" | "implementer" | "validator",
  "attempt": <int 1-3>,
  "max_attempts": 3,
  "failed_output_path": "<path>",
  "check_name": "<stable check id>",
  "expected": "<short schema or invariant description>",
  "got_summary": "<short mechanical summary of the invalid output>",
  "jq_filter": "<jq filter that failed, if any>",
  "stderr_excerpt": "<short stderr/stdout excerpt>"
}
```

`planner.in.json`:

```
{
  "issue_path": "<ISSUE_PATH>",
  "issue_json_path": "<RUN_DIR>/iter-<N>/issue.json",
  "prior_plan_path": "<path or null>",
  "prior_review_path": "<path or null>",
  "revision_request_path": "<path or null>",
  "conventions_path": "./.fight/planning/conventions.json",
  "self_verify_filters_path": "./.fight/planning/schema-filters/planner.jq",
  "repair_feedback_path": "<path or null>"
}
```

`reviewer.in.json`:

```
{
  "issue_path": "<ISSUE_PATH>",
  "issue_json_path": "<RUN_DIR>/iter-<N>/issue.json",
  "plan_path": "<RUN_DIR>/iter-<N>/planner.out.json",
  "prior_review_path": "<path or null>",
  "conventions_path": "./.fight/planning/conventions.json",
  "self_verify_filters_path": "./.fight/planning/schema-filters/reviewer.jq",
  "repair_feedback_path": "<path or null>"
}
```

`state.json`:

```
{
  "iteration": <int>,
  "status": "<see entry logic>",
  "score": <reviewer.out.json.score or null>,
  "revision_number": <int or null>,
  "revision_source_path": "<revision request path or null>",
  "last_updated": "<ISO 8601>",
  "terminal_reason": "<string or absent>"
}
```

## Schema repair subroutine

Use this subroutine for every subagent output. Attempts are 3 total per `*.out.json` write, including the first attempt. Any verification failure consumes one attempt, regardless of which check failed.

1. Dispatch the subagent with only the path to its `*.in.json`.
2. The subagent MUST run every `jq -e` filter listed in `self_verify_filters_path` before declaring done. If a self-check fails, the subagent fixes the output in-context and reruns the filters. This is a fast preflight only; orchestrator verification remains authoritative.
3. Run the em-dash sanitizer before treating U+2014 as a failure: `sed -i $'s/\xe2\x80\x94/--/g' <output_path>`. This mechanical rewrite never consumes an attempt.
4. Run all orchestrator verify checks for that output.
5. If a verify check fails and attempts remain:
   - Write `${RUN_DIR}/iter-${N}/schema-repair-<role>-attempt-<attempt>.json` with the `repair_feedback_path` schema above.
   - Rewrite that role's `*.in.json` so `repair_feedback_path` points to the feedback file.
   - Set state status `repairing-schema`.
   - Re-dispatch the same role with only the input path and the role-scoped minimal repair prompt below. Do not pass inline parser feedback.
6. If attempt 3 fails, set `state.json` status `schema_exhausted`, `terminal_reason: "<role> output failed <check_name> after 3 attempts"`, print one terminal line, and exit.

Never weaken, skip, wrap, or reinterpret listed `jq` checks. Repair happens by making the subagent fix its persisted output, not by changing the verifier.

Minimal repair prompts:

- Planner repair: read the input JSON, then `repair_feedback_path`, fix only the named `planner.out.json` check, rerun `self_verify_filters_path`, and write `planner.out.json`. Do not rediscover conventions, re-read raw issue markdown unless needed for the named check, or change valid plan content unrelated to the failure.
- Reviewer repair: read the input JSON, then `repair_feedback_path`, fix only the named `reviewer.out.json` check, rerun `self_verify_filters_path`, and write `reviewer.out.json`. Do not redo repository exploration, review scrutiny, convention discovery, or blocker/nit analysis unrelated to the failed check.

## Phase A steps

`N = state.iteration + 1` on a fresh iteration, or `N = state.iteration` when resuming `ready-to-review`.

### S0. INIT

- Run `mkdir -p "${RUN_DIR}/iter-${N}" ./.fight/planning/schema-filters`.
- If `./.fight/planning/conventions.json` exists and passes shape verification, reuse it. Otherwise discover conventions once and write it:
  - List existing convention files from `CLAUDE.md`, `CLAUDE.local.md`, and `AGENTS.md`; do not list missing files.
  - Discover candidate verification commands from `justfile`, `Makefile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `devenv.nix`, `flake.nix`, `.pre-commit-config.yaml`, and recipes documented in convention files. Put candidates under `verify_commands.lint`, `verify_commands.type`, `verify_commands.test`, and `verify_commands.format`; empty arrays are valid.
  - If `devenv.nix` exists, set `command_runner_wrapper` to `devenv shell --`; otherwise set it to null.
  - Capture documented migration recipes and generated-artifact markers when present.
- Verify conventions catalog: `jq -e 'has("convention_files") and has("verify_commands") and (.verify_commands | has("lint") and has("type") and has("test") and has("format"))' ./.fight/planning/conventions.json >/dev/null`.
- Generate `./.fight/planning/schema-filters/planner.jq` and `./.fight/planning/schema-filters/reviewer.jq` from the canonical schema and check text in this prompt. These filters are for subagent self-verification only and must mirror the orchestrator checks below closely enough to catch mechanical field, enum, count, and score mistakes before the subagent returns.
- Write `${RUN_DIR}/state.json` with status `parsing`, preserving revision metadata when present.
- Verify: `jq -e '.iteration == '"${N}"' and .status == "parsing"' "${RUN_DIR}/state.json" >/dev/null`.

### S1. PARSE ISSUE

- Read `ISSUE_PATH`. If it does not exist, set status `planner-failed`, `terminal_reason: "<ISSUE_PATH> not found"`, and exit.
- Extract every `<criterion>` tag in document order. Assign ids `criterion-1`, `criterion-2`, etc.
- Write `${RUN_DIR}/iter-${N}/issue.json`.
- Verify: `jq -e '.criteria | length > 0 and all(.id | startswith("criterion-"))' "${RUN_DIR}/iter-${N}/issue.json" >/dev/null`.
- Update state status to `planner-prep`.

### S2. PREPARE PLANNER INPUT

- If `N > 1`, set prior paths to the prior iteration under `RUN_DIR`.
- If `N == 1`, set prior paths to `null`.
- If this is a revision run, set `revision_request_path` to the request path; otherwise `null`.
- Set `repair_feedback_path` to `null` before the first attempt.
- Set `issue_json_path` to `${RUN_DIR}/iter-${N}/issue.json`, `conventions_path` to `./.fight/planning/conventions.json`, and `self_verify_filters_path` to `./.fight/planning/schema-filters/planner.jq`.
- Write `${RUN_DIR}/iter-${N}/planner.in.json`.
- Verify it has `issue_path`, `issue_json_path`, `prior_plan_path`, `prior_review_path`, `revision_request_path`, `conventions_path`, `self_verify_filters_path`, and `repair_feedback_path`.
- Update state status to `planning`.

### S3. DISPATCH PLANNER

Invoke the Agent tool with:

- `subagent_type: "Plan"`
- `description: "Plan iter ${N} for ${ISSUE_PATH}"`
- `prompt`:

  > Read the planner input JSON path provided by the orchestrator and every file it references. Do not rely on inline context.
  >
  > Read `issue_json_path` first. Read raw `issue_path` only when you need surrounding issue prose or ambiguity that is not present in `issue.json`.
  >
  > Read `conventions_path` for the project convention catalog and read only the convention files listed there. Do not rediscover conventions from scratch.
  >
  > If `repair_feedback_path` is non-null, read it first, then repair only the structure or invariant named there. Preserve valid prior content when possible.
  >
  > If `revision_request_path` is non-null, read it and address the implementation failure trace in the new plan. The root `plan.json` remains the output target after convergence; do not edit source.
  >
  > If `prior_review_path` is non-null, address every prior blocker in this iteration's plan. Silent omission is not allowed.
  >
  > Every criterion id from `issue.json` MUST appear in `ac_coverage` with a non-empty `covered_by` list. The `covered_by` entries are `approach.id` values.
  >
  > `tests` MUST include at least one `scope: "full-suite"` entry. Step-scoped tests use `scope: "step"` and name the relevant `approach_ids`.
  >
  > Honor project conventions. Do not invent rules the conventions do not state. If conventions are silent on a topic, record the assumption in `risks`.
  >
  > Write `planner.out.json` to the path implied by the input file directory with exactly the canonical fields. Before declaring done, run every `jq -e` filter listed in `self_verify_filters_path`; if any fails, fix the JSON in-context and rerun the filters. Use `[]` for empty arrays. Do not omit fields. Do not use em dashes in persisted text. Write nothing else outside this file. Do not edit source.
  >
  > Your subagent has `Bash` but no `Write` or `Edit`. To write JSON, use `Bash` with a heredoc.

Run the schema repair subroutine against `planner.out.json` with these checks:

- Shape includes all canonical planner fields.
- Every `tests[]` entry has `path`, `kind`, `scope`, `approach_ids`, `command`, and `what_it_proves`.
- At least one `tests[]` entry has `scope == "full-suite"`.
- AC coverage includes every criterion id.
- Every `covered_by` is non-empty and references existing `approach.id` values.

On success, update state status to `ready-to-review`, print `phase A complete · iter ${N} · status ready-to-review`, and proceed to Phase B.

## Phase B steps

### S4. PREPARE REVIEWER INPUT

- Set `prior_review_path` to `${RUN_DIR}/iter-$((N-1))/reviewer.out.json` when `N > 1` and it exists; otherwise `null`. For `N == 1`, this is always `null`.
- Write `${RUN_DIR}/iter-${N}/reviewer.in.json` with `issue_json_path`, `prior_review_path`, `conventions_path: "./.fight/planning/conventions.json"`, `self_verify_filters_path: "./.fight/planning/schema-filters/reviewer.jq"`, and `repair_feedback_path: null`.
- Verify it has `issue_path`, `issue_json_path`, `plan_path`, `prior_review_path`, `conventions_path`, `self_verify_filters_path`, and `repair_feedback_path`.
- Update state status to `reviewing`.

### S5. DISPATCH REVIEWER

Invoke the Agent tool with:

- `subagent_type: "general-purpose"`
- `description: "Review iter ${N} plan"`
- `prompt`:

  > Read the reviewer input JSON path provided by the orchestrator and every file it references. Do not rely on inline context.
  >
  > Read `issue_json_path` first. Read raw `issue_path` only when you need surrounding issue prose or ambiguity that is not present in `issue.json`.
  >
  > Read `conventions_path` for the project convention catalog and read only the convention files listed there. Do not rediscover conventions from scratch.
  >
  > If `repair_feedback_path` is non-null, read it first, then repair only the structure or invariant named there. Preserve valid prior content when possible.
  >
  > Inspect the repository for any claim the plan makes about existing files, routes, models, generated artifacts, migrations, or verification commands. Do not take the planner's word for it.
  >
  > Evaluate the plan neutrally and with citations. Plan-blocking uncertainty, AC gaps, test gaps, and repo-rule violations are blockers. Optional style or wording improvements with no behavior, correctness, AC coverage, test, convention, migration, security, or maintainability implication are nits.
  >
  > Blocker severity rubric: `critical` means data loss, security breach, or AC-blocking incorrectness; `high` means user-visible defect or material scope creep; `medium` means convention violation or maintainability issue with no immediate user impact; `low` means just above the nit threshold and would catch a defect under specific edge cases.
  >
  > If `prior_review_path` is non-null, every unresolved prior blocker must either appear in `resolved_blocker_ids` or resurface in `blockers` with the same id. Resolved ids must refer to blocker ids from `prior_review_path`.
  >
  > New blocker ids use `blocker-${N}-${k}` after sorting new blockers by severity order: critical, high, medium, low. Emit at most 5 new blockers per pass. Prior unresolved blockers do not count against the cap. Do not downgrade blockers to nits to fit the cap.
  >
  > `verdict: "approve"` means no blockers and no requested changes. `verdict: "revise"` means either blockers exist or only optional nits remain.
  >
  > EVIDENCE-WITH-CITATION rule: every blocker and nit MUST cite a concrete anchor: a `file:line` in the repo, a convention section name, or a quoted phrase from `planner.out.json`.
  >
  > PER-STEP SCRUTINY: write exactly one entry per item in `planner.out.json.approach`, in `per_step_scrutiny`.
  >
  > Score honestly. `score.overall` MUST equal the minimum of the six dimension scores. Score is telemetry, not the convergence decision.
  >
  > Write `reviewer.out.json` with exactly the canonical fields. Before declaring done, run every `jq -e` filter listed in `self_verify_filters_path`; if any fails, fix the JSON in-context and rerun the filters. Use `[]` for empty arrays. Do not omit fields. Do not use em dashes in persisted text. Edit no source.

Run the schema repair subroutine against `reviewer.out.json` with these checks:

- Shape includes `verdict`, `per_step_scrutiny`, `strengths`, `blockers`, `resolved_blocker_ids`, `nits`, and `score`.
- Verdict enum is `approve` or `revise`.
- Per-step scrutiny count and ids match `planner.out.json.approach`.
- Every blocker has `id`, `severity`, `issue`, `where`, and `fix`.
- Severity and id shape: `jq -e '.blockers // [] | all(has("id") and has("severity") and (.severity | IN("critical","high","medium","low")))' reviewer.out.json`.
- If `prior_review_path` is non-null, resolved ids reference real prior blockers: `jq -e --slurpfile p "$prior_review_path" '($p[0].blockers // [] | map(.id)) as $prior | (.resolved_blocker_ids // [] | all(. as $id | $prior | index($id)))' reviewer.out.json`.
- If `prior_review_path` is non-null, unresolved prior blockers resurface: `jq -e --slurpfile p "$prior_review_path" '($p[0].blockers // [] | map(.id)) as $prior | (.resolved_blocker_ids // []) as $resolved | (.blockers // [] | map(.id)) as $current | $prior | all(. as $id | ($resolved | index($id)) or ($current | index($id)))' reviewer.out.json`.
- If `prior_review_path` is null, skip both prior-blocker jq checks by using an empty prior blocker set. Do not invoke `--slurpfile` on a null path.
- New blocker cap: `jq -e --arg prefix "blocker-${N}-" '[.blockers[]? | select(.id | startswith($prefix))] | length <= 5' reviewer.out.json`.
- Every nit has `issue`, `where`, and `optional_fix`.
- Overall score equals the minimum score dimension and every score is 1-10.

On success, update state status to `merging`.

### S6. MERGE

- Read `issue.json`, `planner.out.json`, and `reviewer.out.json`.
- Read prior root `./.fight/planning/plan.json` if it exists, to extract `changelog`; otherwise start with `[]`.
- Append `{ "iteration": N, "summary": "<one-line iteration summary>" }`.
- Write root `./.fight/planning/plan.json` with:

  ```
  {
    "issue_path": "<ISSUE_PATH>",
    "iteration": N,
    "revision_source_path": "<revision_request_path or null>",
    "revision_number": <M or null>,
    "criteria": <issue.json.criteria>,
    "plan": <planner.out.json>,
    "review": <reviewer.out.json>,
    "ac_coverage": <planner.out.json.ac_coverage>,
    "changelog": <accumulated array>,
    "status": "<see below>"
  }
  ```

- Determine status, in order:
  - `converged` iff every criterion id has non-empty coverage AND either:
    - `N >= 1`, `reviewer.verdict == "approve"`, `reviewer.blockers == []`, and `reviewer.nits == []`; or
    - `N >= 2`, `reviewer.verdict == "revise"`, `reviewer.blockers == []`, and only valid nits remain.
  - `max_iterations` iff `N >= 10`.
  - Otherwise `iter-complete`.
- Verify root `plan.json` has status `converged`, `iter-complete`, or `max_iterations`.
- Update `${RUN_DIR}/state.json` with the same status, score, revision metadata, and `last_updated`.

### S7. REPORT AND DECIDE NEXT

Print exactly one line:

`iter ${N}/10 · verdict ${verdict} · blockers ${#blockers} · nits ${#nits} · status ${status}`

Branch on status:

- `converged` -> print `loop terminal: converged at iter ${N}` and exit.
- `max_iterations` -> print `loop terminal: max_iterations at iter ${N}` and exit.
- `schema_exhausted` -> print `loop terminal: schema_exhausted at iter ${N}` and exit.
- `iter-complete` -> loop back to Phase A for iteration N+1 immediately.

## Anti-shortcut rules

- Do not play the PLANNER or REVIEWER role yourself.
- Do not reuse the same `subagent_type` for planner and reviewer.
- Do not pause to ask whether to continue. The loop is autonomous.
- Do not call `EnterPlanMode`.
- Do not skip `state.json` status updates.
- Do not abbreviate or rename schema fields.
- Do not pass inline handoff or repair context to subagents. Pass artifact paths only.
- Do not weaken, skip, wrap, or reinterpret listed verification checks.
- Do not invent acceptance criteria, repo rules, or critique points.
- Do not edit source, commit, run migrations, invoke MCP, or access the network.
- Keep the em-dash sanitizer as a mechanical rewrite. Do not burn repair attempts on that known fixable text convention.
- Do not recover from `stale-partial-state` by guessing.

## Completeness contract

The session is complete only when `${RUN_DIR}/state.json` status is one of: `converged`, `max_iterations`, `schema_exhausted`, `planner-failed`, `reviewer-failed`, `stale-partial-state`.

`iter-complete`, `ready-to-review`, and `repairing-schema` are NOT terminal.

## Grounding rules

Subagent claims must be grounded in:

- `ISSUE_PATH` and its criteria,
- project convention files,
- revision request files when present,
- prior iteration files under `RUN_DIR`,
- actual repository state readable by tools.

If the planner needs a fact it cannot verify, it goes in `risks`. If the reviewer sees plan-blocking uncertainty, it goes in `blockers`; optional wording/style observations go in `nits`.

## Convergence criteria

The plan loop converges when ALL of these hold after Phase B:

- every criterion id from `issue.json` appears in `plan.json.ac_coverage` with non-empty `covered_by`
- either:
  - `state.json.iteration >= 1`, `reviewer.out.json.verdict == "approve"`, `blockers == []`, and `nits == []`; or
  - `state.json.iteration >= 2`, `reviewer.out.json.verdict == "revise"`, `blockers == []`, and only valid nits remain
- `state.json.status == "converged"`
- root `./.fight/planning/plan.json` exists with the full merged schema

Score is telemetry only. It never gates convergence.

## First action

Parse `$ARGUMENTS`, resolve `ISSUE_PATH`, choose `RUN_DIR`, verify required input files exist, read `${RUN_DIR}/state.json` or treat it as missing, then dispatch per entry logic. Do not summarize this contract back to the user; execute until terminal.
