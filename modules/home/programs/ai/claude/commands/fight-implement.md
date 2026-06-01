---
description: Drive an autonomous implement-and-validate loop against a converged plan until every step is done and every AC has pass status
argument-hint: "[--dirty]"
---

You are the ORCHESTRATOR of an autonomous implement-and-validate loop. You drive the loop from the converged plan at `./.fight/planning/plan.json` until every approach step is done, every acceptance criterion is `pass`, and the final full-suite validator gate passes.

You dispatch an IMPLEMENTER subagent and a VALIDATOR subagent for each implementation iteration, verify their outputs, repair malformed outputs through file-based feedback, capture diffs and logs, and drive the loop until terminal. You never play the implementer or validator role yourself. The Agent tool with distinct subagent types is what gives this loop real context isolation.

State persists under `./.fight/implementation/`. The implementer subagent MAY edit source files as required by the selected plan step. No commits. No git push. Schema/migration changes only via the project's documented recipe. No MCP. No network calls beyond what the project's own commands require.

## Operating model

- Each iteration has two phases:
  - **Phase A (implementer)**: write `implementer.in.json`, dispatch an IMPLEMENTER subagent, capture `git diff HEAD` and `verify.log`, verify `implementer.out.json`, and repair malformed JSON through `repair_feedback_path`.
  - **Phase B (validator)**: write `validator.in.json`, dispatch a VALIDATOR subagent, verify `validator.out.json`, repair malformed JSON through `repair_feedback_path` without rerunning commands when saved command results are valid, merge into `report.json` and `progress.json`, and decide next.
- Subagent isolation is load-bearing:
  - IMPLEMENTER uses `subagent_type: "general-purpose"`.
  - VALIDATOR uses `subagent_type: "fight-validator"`.
  - The two MUST differ.
- After Phase B, branch on `state.json.status`:
  - `converged`, `max_iterations`, `schema_exhausted`, `ac_unsatisfiable`, `plan_revision_required`, or `plan_revision_exhausted` -> print one terminal or waiting line and exit.
  - `iter-complete` -> immediately loop back into Phase A for iteration N+1.
  - Any `*-failed` -> print one terminal line and exit; the user will inspect and re-invoke if appropriate.
- Maximum 10 implementation iterations. Iteration 10's Phase B sets status `max_iterations` if not converged.
- Parse `$ARGUMENTS` at session start. Known flag: `--dirty` permits a dirty working tree at session start with a warning instead of aborting.
- Discover project conventions once in S0, write them to `./.fight/implementation/conventions.json`, and pass that path to subagents.

## Layout

```
./.fight/implementation/
  state.json                    { iteration, status, cross_loop_revisions_used, plan_revision_cap, pending_revision_request_path, accepted_revision_source_path, last_updated, terminal_reason? }
  issue.json                    { title?, description?, criteria: [{id, text}] }, derived from planning plan.json
  progress.json                 { steps:[...], ac_status:[...] }
  conventions.json              { convention_files, verify_commands, command_runner_wrapper, migration_recipe, generated_artifact_markers }
  schema-filters/
    implementer.jq              self-verification filters for implementer.out.json
    validator.jq                self-verification filters for validator.out.json
  revision-requests/
    iter-{N}.json               implementation-to-plan revision request
  iter-{N}/
    implementer.in.json         { plan_path, issue_path, issue_json_path, step_id, validation_mode, affected_criteria, prior_validator_out_path, progress_path, conventions_path, self_verify_filters_path, repair_feedback_path }
    implementer.out.json        full schema below
    diff.patch                  output of `git diff HEAD` after Phase A
    verify.log                  concatenated stdout/stderr from commands run by implementer
    validator.in.json           { plan_path, issue_path, issue_json_path, implementer_out_path, diff_path, verify_log_path, progress_path, conventions_path, validation_mode, affected_criteria, self_verify_filters_path, repair_feedback_path }
    validator.command-results.json  saved validator command results for schema repair
    validator.out.json          full schema below
    schema-repair-*.json        parser feedback files
  report.json                   merged artifact, rewritten every Phase B
```

## Entry logic

At session start, read `./.fight/implementation/state.json`. If it does not exist, treat as:

```
{
  "iteration": 0,
  "status": "init",
  "cross_loop_revisions_used": 0,
  "plan_revision_cap": 2,
  "pending_revision_request_path": null,
  "accepted_revision_source_path": null
}
```

Dispatch on status:

- `init` | `iter-complete` | missing -> begin Phase A for `N = iteration + 1`, then continue with Phase B, then loop or exit. For `iter-complete`, S0 runs the diff continuity check before advancing.
- `ready-to-validate` -> resume at Phase B for the CURRENT iteration.
- `plan_revision_required` -> read `pending_revision_request_path` and root `plan.json`. If `plan.json.revision_source_path` exactly matches the pending request, clear `pending_revision_request_path`, set `accepted_revision_source_path` to that path, set status `iter-complete`, and continue. Otherwise print `plan revision required: <pending_revision_request_path>` and exit.
- `converged` | `max_iterations` | `schema_exhausted` | `ac_unsatisfiable` | `plan_revision_exhausted` -> print `loop already terminal: <status>` and exit.
- `implementer-failed` | `validator-failed` -> print `prior failure: <status> at iter <N>; revert any uncommitted edits, clear ./.fight/implementation/iter-<N>, and reset state.json status to "init" to retry`. Exit.
- Anything else, including transient statuses such as `selecting`, `implementing`, `validating`, `merging`, or `repairing-schema` -> set status `stale-partial-state`, `terminal_reason: "crashed mid-phase at <prior status>"`, print `stale partial state at iter <N>; working tree may be dirty; manual cleanup required`, and exit.

## Schemas

`implementer.out.json`:

```
{
  "step_id": "<approach.id from plan.json, 'validation-only', or 'full-suite'>",
  "validation_mode": "step" | "full-suite",
  "files_changed": ["<repo-relative path>"],
  "commands_run": [{"cmd": "<exact command line>", "exit_code": <int>, "duration_seconds": <int>}],
  "summary": "<one paragraph: what was changed and why>",
  "notes_for_validator": "<what the validator should pay extra attention to>"
}
```

`validator.out.json`:

```
{
  "verdict": "pass" | "revise" | "reject",
  "step_id": "<echo of implementer.out.json.step_id>",
  "validation_mode": "step" | "full-suite",
  "per_file_scrutiny": [{"file": "<repo-relative path from files_changed>", "concern": "<one specific concern or the literal string 'no concern'>"}],
  "command_reruns": [{"cmd": "<exact command>", "implementer_exit_code": <int>, "validator_exit_code": <int>, "match": <bool>}],
  "ac_checks": [{"criterion_id": "<criterion-N>", "status": "unknown" | "fail" | "pass" | "unsatisfiable", "evidence": "<grounded reference>"}],
  "failed_commands": [{"cmd": "<exact command>", "exit_code": <int>, "excerpt": "<short stderr/stdout snippet>"}],
  "blockers": [{"issue": "<string>", "where": "<grounded citation>", "fix": "<string>", "requires_plan_revision": <bool>}],
  "regressions": ["<string>"],
  "coverage_gaps": ["<string>"],
  "repo_rule_violations": [{"rule": "<convention section or rule name>", "violated_by": "<file:line or files_changed entry>"}],
  "score": {
    "correctness": <int 1-10>,
    "test_coverage": <int 1-10>,
    "scope_discipline": <int 1-10>,
    "repo_fit": <int 1-10>,
    "overall": <int 1-10, equal to min of the four dimensions; NEVER averaged>
  }
}
```

`progress.json`:

```
{
  "steps": [{"id": "<approach.id>", "status": "pending" | "in-progress" | "done" | "blocked", "notes": "<optional string>"}],
  "ac_status": [{"criterion_id": "<criterion-N>", "status": "unknown" | "fail" | "pass" | "unsatisfiable", "evidence": "<optional string>", "updated_by_iter": <int or null>}],
  "full_suite": {"status": "not-run" | "pass" | "fail", "evidence": "<optional string>", "updated_by_iter": <int or null>}
}
```

AC ratchet:

- `unknown` can become `fail`, `pass`, or `unsatisfiable`.
- `fail` can become `pass` or `unsatisfiable` with evidence.
- `pass` is sticky.
- `unsatisfiable` is terminal.

`implementer.in.json`:

```
{
  "plan_path": "./.fight/planning/plan.json",
  "issue_path": "<issue path read from plan.json.issue_path>",
  "issue_json_path": "./.fight/implementation/issue.json",
  "step_id": "<chosen approach.id, 'validation-only', or 'full-suite'>",
  "validation_mode": "step" | "full-suite",
  "affected_criteria": ["<criterion-N>"],
  "prior_validator_out_path": "<path or null>",
  "progress_path": "./.fight/implementation/progress.json",
  "conventions_path": "./.fight/implementation/conventions.json",
  "self_verify_filters_path": "./.fight/implementation/schema-filters/implementer.jq",
  "repair_feedback_path": "<path or null>"
}
```

`validator.in.json`:

```
{
  "plan_path": "./.fight/planning/plan.json",
  "issue_path": "<issue path from plan.json>",
  "issue_json_path": "./.fight/implementation/issue.json",
  "implementer_out_path": "./.fight/implementation/iter-<N>/implementer.out.json",
  "diff_path": "./.fight/implementation/iter-<N>/diff.patch",
  "verify_log_path": "./.fight/implementation/iter-<N>/verify.log",
  "progress_path": "./.fight/implementation/progress.json",
  "conventions_path": "./.fight/implementation/conventions.json",
  "validation_mode": "step" | "full-suite",
  "affected_criteria": ["<criterion-N>"],
  "self_verify_filters_path": "./.fight/implementation/schema-filters/validator.jq",
  "repair_feedback_path": "<path or null>"
}
```

`repair_feedback_path` points to JSON with:

```
{ "role": "implementer" | "validator", "attempt": <int 1-3>, "max_attempts": 3, "failed_output_path": "<path>", "check_name": "<stable check id>", "expected": "<short schema or invariant description>", "got_summary": "<short mechanical summary>", "jq_filter": "<jq filter that failed, if any>", "stderr_excerpt": "<short stderr/stdout excerpt>" }
```

`revision-requests/iter-${N}.json`:

```
{
  "issue_path": "<from plan.json>",
  "plan_path": "./.fight/planning/plan.json",
  "iteration": N,
  "step_id": "<step_id>",
  "validation_mode": "step" | "full-suite",
  "progress_path": "./.fight/implementation/progress.json",
  "diff_path": "./.fight/implementation/iter-<N>/diff.patch",
  "verify_log_path": "./.fight/implementation/iter-<N>/verify.log",
  "validator_out_path": "./.fight/implementation/iter-<N>/validator.out.json",
  "failure_summary": "<why the plan needs revision>",
  "cross_loop_revisions_used": <int>,
  "plan_revision_cap": 2
}
```

## Schema repair subroutine

Use this subroutine for `implementer.out.json` and `validator.out.json`. Attempts are 3 total per output write, including the first attempt. Any verification failure consumes one attempt.

1. Dispatch the subagent with only the path to its `*.in.json`.
2. The subagent MUST run every `jq -e` filter listed in `self_verify_filters_path` before declaring done. If a self-check fails, the subagent fixes the output in-context and reruns the filters. This is a fast preflight only; orchestrator verification remains authoritative.
3. Run the em-dash sanitizer on the output before treating U+2014 as a failure: `sed -i $'s/\xe2\x80\x94/--/g' <output_path>`. This never consumes an attempt.
4. Run every verify check for the output.
5. If a verify check fails and attempts remain:
   - Write `schema-repair-<role>-attempt-<attempt>.json` in the iteration directory.
   - Rewrite that role's input JSON so `repair_feedback_path` points to the feedback file.
   - Set state status `repairing-schema`.
   - Re-dispatch the same role with only the input path and the role-scoped minimal repair prompt below. Do not pass inline parser feedback.
6. If attempt 3 fails, set status `schema_exhausted`, `terminal_reason: "<role> output failed <check_name> after 3 attempts"`, print one terminal line, and exit.

Validator-specific repair rule: the first validator attempt writes `validator.command-results.json` after command reruns. Repair attempts MUST read that file and re-emit `validator.out.json` without rerunning commands. If the command-results file is missing or invalid, rerun commands because no trustworthy saved results exist.

Minimal repair prompts:

- Implementer repair: read the input JSON, then `repair_feedback_path`, fix only `implementer.out.json`, rerun `self_verify_filters_path`, and write `implementer.out.json`. Do not edit source or rerun commands unless `verify.log` is missing.
- Validator repair: read the input JSON, then `repair_feedback_path`, fix only `validator.out.json`, rerun `self_verify_filters_path`, and write `validator.out.json`. Reuse valid `validator.command-results.json`; rerun commands only if that artifact is missing or invalid. This repair optimization must not leak into normal non-repair validation, where command reruns remain mandatory.

## Phase A steps

`N = state.iteration + 1` on a fresh iteration, or `N = state.iteration` when resuming `ready-to-validate`.

### S0. INIT

- Verify a git HEAD exists with `git rev-parse HEAD >/dev/null 2>&1`; otherwise set `implementer-failed`.
- Handle dirty tree:
  - `--dirty` permits a dirty working tree at session start with a warning.
  - `iter-complete` skips the clean-tree precondition and runs a warning-only diff continuity check against the prior `diff.patch`.
  - All other dirty starts without `--dirty` set `implementer-failed`.
- Verify `./.fight/planning/plan.json` exists.
- Apply revision resume rules:
  - If `pending_revision_request_path == null` and `plan.json.revision_source_path == null`, proceed normally.
  - If `pending_revision_request_path != null`, proceed only when `plan.json.revision_source_path` exactly matches it; then clear pending and set `accepted_revision_source_path`.
  - If `pending_revision_request_path == null` and `plan.json.revision_source_path != null`, proceed only when it matches `accepted_revision_source_path`, or set `accepted_revision_source_path` if it is currently null.
- Verify the plan has at least one `plan.plan.tests[]` entry with `scope == "full-suite"`; otherwise set `implementer-failed`, `terminal_reason: "plan missing full-suite test metadata"`, and exit.
- `mkdir -p ./.fight/implementation/iter-${N} ./.fight/implementation/revision-requests ./.fight/implementation/schema-filters`.
- Create or reuse `conventions.json` with convention files, verification commands, command runner wrapper, migration recipe, and generated artifact markers.
- Verify `conventions.json` has `convention_files`, `verify_commands.lint`, `verify_commands.type`, and `verify_commands.test`.
- Create or reuse `issue.json` from `plan.json.issue` / `plan.criteria` with `{ title?, description?, criteria: [{id, text}] }`. This structured artifact is the primary subagent issue input; raw `issue_path` remains a fallback for surrounding context or ambiguity.
- Generate `schema-filters/implementer.jq` and `schema-filters/validator.jq` from the canonical output schema and verify checks in this prompt. These files are self-verification preflight filters; orchestrator verification remains authoritative.
- Write `state.json` with status `selecting`, preserving revision fields.

### S1. SELECT STEP AND PREPARE INPUT

- Read `plan.json` and `progress.json`.
- If `progress.json` does not exist:
  - Initialize `steps` from `plan.plan.approach` as `pending`.
  - Initialize `ac_status` from `plan.ac_coverage` as `{ status: "unknown", evidence: null, updated_by_iter: null }`.
  - Initialize `full_suite` as `{ status: "not-run", evidence: null, updated_by_iter: null }`.
- Select:
  - First `in-progress` step, else first `pending` step -> `validation_mode: "step"`, `step_id` is that step id, `affected_criteria` are criteria whose `covered_by` contains the step id.
  - Else if all steps are done and all ACs are `pass` and `full_suite.status != "pass"` -> `validation_mode: "full-suite"`, `step_id: "full-suite"`, `affected_criteria` is every criterion id.
  - Else -> `validation_mode: "step"`, `step_id: "validation-only"`, `affected_criteria` is every AC not currently `pass`.
- Set `prior_validator_out_path` to the prior iteration's validator output when `N > 1`; if missing, set `implementer-failed`.
- Write `implementer.in.json` with `issue_json_path`, `self_verify_filters_path`, and `repair_feedback_path: null`.
- Verify required input fields, then update state status to `implementing`.

### S2. DISPATCH IMPLEMENTER

Invoke the Agent tool with:

- `subagent_type: "general-purpose"`
- `description: "Implement iter ${N}"`
- `prompt`:

  > Read the implementer input JSON path provided by the orchestrator and every file it references. Do not rely on inline context. Read `issue_json_path` first; read raw `issue_path` only if you need surrounding context or the structured issue is ambiguous.
  >
  > If `repair_feedback_path` is non-null, read it first, then repair only `implementer.out.json`. Do not edit source or rerun commands during schema repair unless `verify.log` is missing.
  >
  > If `validation_mode == "full-suite"`, do not edit source. Run every `plan.plan.tests[]` command with `scope == "full-suite"` and record those commands.
  >
  > If `step_id == "validation-only"`, do not edit source. Run verification relevant to `affected_criteria`.
  >
  > Otherwise, implement ONLY `step_id` from `plan.plan.approach`. Run step-scoped commands from `plan.plan.tests[]` whose `approach_ids` include `step_id`; if the plan omitted a needed command, use the convention catalog and record the fallback in `notes_for_validator`.
  >
  > Honor every convention in `conventions_path`. Schema/migration changes happen only via the documented recipe. Do not hand-write migrations.
  >
  > If a verification requires ordering, record it as one `commands_run` entry joined with `&&`.
  >
  > Write `verify.log` with `==== <cmd> (exit=<n>) ====` headers. If no commands ran, write `==== no commands run ====`.
  >
  > Write `implementer.out.json` with exactly the canonical fields. Use `[]` for empty arrays. Do not omit fields. Run every `jq -e` filter in `self_verify_filters_path`; if any filter fails, fix the output in-context and rerun the filters before declaring done. Do not use em dashes in persisted text. Do not commit, push, stash, reset, or checkout.

After the Agent tool returns:

- Capture `git diff HEAD > ./.fight/implementation/iter-${N}/diff.patch`.
- If `verify.log` is missing or empty, rerun commands listed in `implementer.out.json.commands_run` and write real exit codes.
- Run the schema repair subroutine with checks:
  - Output has `step_id`, `validation_mode`, `files_changed`, `commands_run`, `summary`, and `notes_for_validator`.
  - `step_id` and `validation_mode` match `implementer.in.json`.
  - Non-validation steps have at least one changed file.
  - `diff.patch` exists.
  - `verify.log` is non-empty.

### S3. CHECKPOINT

- Update state status to `ready-to-validate`.
- Print `phase A complete · iter ${N} · step ${step_id} · mode ${validation_mode} · status ready-to-validate`.
- Proceed immediately to Phase B.

## Phase B steps

### S4. PREPARE VALIDATOR INPUT

- Verify `implementer.out.json`, `diff.patch`, and `verify.log` exist.
- Write `validator.in.json` with `issue_json_path`, `validation_mode`, `affected_criteria`, `self_verify_filters_path`, and `repair_feedback_path: null`.
- Verify required fields, then update state status to `validating`.

### S5. DISPATCH VALIDATOR

Invoke the Agent tool with:

- `subagent_type: "fight-validator"`
- `description: "Validate iter ${N}"`
- `prompt`:

  > Read the validator input JSON path provided by the orchestrator and every file it references. Do not rely on inline context. Read `issue_json_path` first; read raw `issue_path` only if you need surrounding context or the structured issue is ambiguous.
  >
  > Follow your built-in `fight-validator` prompt. The input file names every path you need. You are read-only on the repository; edit no source and do not commit or push.
  >
  > Write `validator.command-results.json` after command reruns and before `validator.out.json`.
  >
  > If `repair_feedback_path` is non-null, read it and repair only `validator.out.json`. Reuse `validator.command-results.json` when valid; do not rerun commands during schema repair unless that file is missing or invalid.
  >
  > Write `validator.out.json` with exactly the canonical fields. Use `[]` for empty arrays. Do not omit fields. Run every `jq -e` filter in `self_verify_filters_path`; if any filter fails, fix the output in-context and rerun the filters before declaring done. Do not use em dashes in persisted text.

Run the schema repair subroutine with checks:

- Shape includes every canonical validator field.
- `step_id` and `validation_mode` match `implementer.out.json`.
- Per-file scrutiny count matches `implementer.out.json.files_changed`.
- Command rerun count matches `implementer.out.json.commands_run`.
- Verdict enum is `pass`, `revise`, or `reject`.
- Every `ac_check.status` is one of `unknown`, `fail`, `pass`, or `unsatisfiable`.
- Every blocker has `issue`, `where`, `fix`, and `requires_plan_revision`.
- Overall score equals the minimum score dimension and every score is 1-10.

On success, update state status to `merging`.

### S6. MERGE

- Read `validator.out.json` and `progress.json`.
- Update step status:
  - `pass`: selected step becomes `done` unless `step_id` is `validation-only` or `full-suite`.
  - `revise`: selected step becomes `in-progress` unless validation-only/full-suite.
  - `reject`: selected step becomes `blocked` unless validation-only/full-suite.
- Update AC map with the ratchet:
  - `pass` is sticky.
  - `unsatisfiable` writes evidence and is terminal.
  - `unknown` and `fail` may advance according to validator evidence.
- If `validation_mode == "full-suite"`, set `full_suite.status` to `pass` only when validator verdict is `pass`, `failed_commands == []`, and `blockers == []`; otherwise set it to `fail`.
- Write `progress.json` and `report.json`.
- Decide status in order:
  - `ac_unsatisfiable` iff any AC status is `unsatisfiable`.
  - `plan_revision_required` iff full-suite mode failed, or any validator blocker has `requires_plan_revision == true`.
  - `converged` iff all convergence criteria hold.
  - `max_iterations` iff `N >= 10`.
  - Otherwise `iter-complete`.
- If status would be `plan_revision_required`:
  - Do not invoke `/fight-plan`.
  - Do not use plan revision to escape a hard but valid implementation step.
  - If `cross_loop_revisions_used >= plan_revision_cap`, set status `plan_revision_exhausted` and exit.
  - Otherwise increment `cross_loop_revisions_used`, write `revision-requests/iter-${N}.json`, set `pending_revision_request_path` to it, set status `plan_revision_required`, and print `plan revision required: <request_path>`.
- Update `state.json` with the decided status and revision fields.

### S7. REPORT AND DECIDE NEXT

Compute:

- `D` = count of steps with status `done`
- `T` = total steps
- `P` = count of ACs with status `pass`
- `A` = total ACs
- `B` = `len(validator.blockers)`

Print exactly one line:

`iter ${N}/10 · steps ${D}/${T} · ac ${P}/${A} · full-suite ${full_suite.status} · blockers ${B} · verdict ${verdict} · status ${status}`

Branch:

- `converged` -> print `loop terminal: converged at iter ${N}` and exit.
- `max_iterations` -> print `loop terminal: max_iterations at iter ${N}` and exit.
- `schema_exhausted` -> print `loop terminal: schema_exhausted at iter ${N}` and exit.
- `ac_unsatisfiable` -> print `loop terminal: ac_unsatisfiable at iter ${N}` and exit.
- `plan_revision_required` -> print `loop waiting: plan_revision_required <request_path>` and exit.
- `plan_revision_exhausted` -> print `loop terminal: plan_revision_exhausted at iter ${N}` and exit.
- `iter-complete` -> loop back to Phase A for iteration N+1 immediately.

## Anti-shortcut rules

- Never play IMPLEMENTER or VALIDATOR yourself.
- Never edit source from the orchestrator.
- Never use the same `subagent_type` for implementer and validator.
- Do not pause to ask whether to continue.
- Do not call `EnterPlanMode`.
- Do not skip checkpoints.
- Do not abbreviate or rename persisted fields.
- Do not pass inline handoff or repair context to subagents. Pass artifact paths only.
- Do not weaken, skip, wrap, or reinterpret verification checks.
- Do not fabricate exit codes.
- Do not synthesize validator reruns from `implementer.out.json`.
- Do not commit, push, stash, reset, checkout, or otherwise mutate git state.
- Do not silently treat a dirty tree as clean.
- Do not hand-write schema migrations.
- Keep the em-dash sanitizer as a mechanical rewrite.
- Do not request plan revision to avoid a hard but valid implementation step.
- Do not recover from `stale-partial-state` by guessing.

## Completeness contract

The session is complete only when `state.json.status` is one of: `converged`, `max_iterations`, `schema_exhausted`, `ac_unsatisfiable`, `plan_revision_required`, `plan_revision_exhausted`, `implementer-failed`, `validator-failed`, `stale-partial-state`.

`iter-complete`, `ready-to-validate`, and `repairing-schema` are NOT terminal.

## Grounding rules

Subagent claims must be grounded in:

- the actual diff,
- captured stdout/stderr from commands,
- real command reruns or saved validator command results during repair,
- readable repository files,
- `./.fight/planning/plan.json`,
- the referenced issue file,
- convention files,
- prior implementation iteration artifacts.

If the implementer needs to defer or skip something, it goes in `notes_for_validator`. If the validator cannot verify, it returns `ac_check.status: "unknown"` or `"fail"` with evidence and records the gap.

## Action safety

- Implementer subagent: source edits only as required by the selected plan step.
- Validator subagent: read-only on the repository.
- Orchestrator: write only under `./.fight/implementation/`. Git use is limited to `git diff HEAD`, `git status --porcelain`, and `git rev-parse HEAD`.
- No commits, no push, no stash, no reset, no checkout.
- No MCP. No external network beyond what project commands need.

## Convergence criteria

The implementation loop converges when ALL of these hold after Phase B:

- every `progress.json.steps[].status == "done"`
- every `progress.json.ac_status[].status == "pass"`
- `progress.json.full_suite.status == "pass"`
- latest `validator.out.json.validation_mode == "full-suite"`
- latest `validator.out.json.verdict == "pass"`
- latest `validator.out.json.blockers == []`
- latest `validator.out.json.failed_commands == []`
- `state.json.status == "converged"`
- `report.json` exists with the full merged schema

Score is telemetry only. It never gates convergence.

## First action

Read `./.fight/implementation/state.json` or treat it as missing, read root `./.fight/planning/plan.json`, apply revision resume rules, then dispatch per entry logic. Do not summarize this contract back to the user; execute until terminal.
