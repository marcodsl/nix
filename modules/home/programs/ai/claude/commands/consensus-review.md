---
description: Multi-agent code review with auto-applied patches gated by tests
argument-hint: [--base <ref>] [--range A..B] [--staged | --working]
---

You are coordinating a consensus-based review of the **current git diff**. You fan out five specialized reviewer subagents in parallel, dispatch a synthesizer to dedupe + verify groundedness + group patches, then apply each group atomically and gate it behind the full test suite.

Use TodoWrite to track the four phases below. Work through them in order. Do not commit anything unless the user explicitly approves after seeing the final diff.

## Phase 0: Pre-flight

Argument parsing: `$ARGUMENTS` is the raw argument string. Tokenize with simple `--flag value` parsing. Recognized flags:

- `--base <ref>` — explicit base ref (commit, branch, tag).
- `--range <A>..<B>` — explicit two-dot range; takes precedence over `--base`.
- `--staged` — review only staged changes (`git diff --cached`).
- `--working` — review unstaged + staged (`git diff HEAD`); **unsafe mode**.

Defaults if no flag: branch-vs-base.

Run these in order. First failure aborts unless noted.

1. **Repo root**: `git rev-parse --show-toplevel`. Refuse if outside a git repository. `cd` there for the rest of the run.

2. **Resolve diff range** (`RANGE`):
   - If `--range A..B` provided → `RANGE="A..B"`.
   - Else if `--staged` → `RANGE` is implicit (use `git diff --cached`); skip Step 3 and 4 below; instead capture `git diff --cached`.
   - Else if `--working` → `RANGE` is implicit (use `git diff HEAD`); **disables clean-tree check**; capture `git diff HEAD`.
   - Else if `--base <ref>` → `RANGE="<base>..HEAD"`.
   - Else (default) → resolve a base in this priority:
     1. `git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null`
     2. `git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null`
     3. `git show-ref --verify --quiet refs/remotes/origin/main && echo origin/main`
     4. `git show-ref --verify --quiet refs/remotes/origin/master && echo origin/master`
        If none resolve → abort with: "no base ref inferable; pass `--base <ref>` or `--range A..B`."
        Else → `BASE=<resolved>`; `RANGE="$(git merge-base HEAD $BASE)..HEAD"`.

3. **Clean-tree check** (skipped under `--working`; relaxed under `--staged`):
   - Default mode: `git status --porcelain` must be empty. If non-empty, list dirty files and ask the user `[stash | abort | continue-unsafe]`. Wait for an answer.
     - `stash` → `git stash push -u -m "consensus-review-preflight"` and remember to `git stash pop` at the end (announce this in the final report).
     - `abort` → stop.
     - `continue-unsafe` → proceed; warn that rollback may not cleanly distinguish reviewer hunks from pre-existing dirt.
   - `--staged` mode: confirm there are no unstaged modifications to files that are _also_ staged (`git diff --name-only` ∩ `git diff --cached --name-only` must be empty). If violated, abort with: "files have both staged and unstaged changes; commit or stash unstaged hunks first."

4. **Capture diff**:
   - Default / `--base` / `--range`: `git diff --no-color --no-ext-diff $RANGE > /tmp/consensus-review-diff.patch`.
   - `--staged`: `git diff --cached --no-color --no-ext-diff > /tmp/consensus-review-diff.patch`.
   - `--working`: `git diff HEAD --no-color --no-ext-diff > /tmp/consensus-review-diff.patch`.
     Set `DIFF_PATH=/tmp/consensus-review-diff.patch`.
     Compute `TOUCHED_FILES`: `git diff --name-only $RANGE` (or `--cached` / vs `HEAD` per mode).
     If the diff is empty (`! [ -s "$DIFF_PATH" ]`) → abort with: "no changes to review."

5. **Detect test command** (pick the **first** match):
   - `flake.nix` present → `nix flake check`. Per repo CLAUDE.md: if existing scripts or commits show `--no-pure-eval` is used, preserve it.
   - `Cargo.toml` → `cargo test`.
   - `pyproject.toml` + `uv.lock` → `uv run pytest`.
   - `pyproject.toml` or `pytest.ini` or `tests/` → `pytest`.
   - `package.json` with a `test` script → `pnpm test` if `pnpm-lock.yaml`, `yarn test` if `yarn.lock`, else `npm test`.
   - `go.mod` → `go test ./...`.
   - Otherwise → ask the user for a test command. Do not invent one.

6. **Baseline test run**: run the test command once. Must pass. Record duration as `BASELINE_SEC`. If it fails → abort: "red baseline; nothing to gate against." If it takes > 5 min, warn the user and ask whether to continue.

7. **Record start SHA**: `BASE_SHA=$(git rev-parse HEAD)`. Used in Phase 3 for drift checks and final reporting.

## Phase 1: Fan out 5 reviewer subagents in parallel

Dispatch all 5 in a **single message** with 5 `Agent` tool calls. Each call uses one of these `subagent_type` values:

- `security-reviewer`
- `simplicity-reviewer`
- `type-correctness-reviewer`
- `test-coverage-reviewer`
- `api-contract-reviewer`

Do NOT set `run_in_background: true` — keep them synchronous so you can collect all five outputs in one round.

Each dispatch prompt must include exactly:

```
Review the captured git diff according to your charter.

repo_root: <absolute repo root>
diff_path: /tmp/consensus-review-diff.patch
touched_files:
  - <path1>
  - <path2>
  - ...

Return JSON only, matching your output schema.
```

If a subagent returns malformed JSON, retry it once with the same prompt. If it fails again, treat it as `{ "agent": "<persona>", "findings": [], "failed": true }` and continue with the rest. Record which agents failed.

## Phase 2: Dispatch the synthesizer

Single `Agent` call with `subagent_type: "review-synthesizer"`. Prompt:

```
Synthesize a consensus apply plan from the five reviewer outputs.

repo_root: <absolute repo root>
diff_path: /tmp/consensus-review-diff.patch
reviewer_outputs:
  - <reviewer 1 JSON, verbatim>
  - <reviewer 2 JSON, verbatim>
  - <reviewer 3 JSON, verbatim>
  - <reviewer 4 JSON, verbatim>
  - <reviewer 5 JSON, verbatim>

Return APPLY_PLAN JSON only.
```

Parse the returned APPLY_PLAN. If parse fails, retry once. If still failing → abort the run; report what each reviewer found and ask the user to handle synthesis manually.

## Phase 3: Apply / test / gate (group-atomic)

Process `APPLY_PLAN.groups` in the order the synthesizer returned. Maintain a rolling "good state" of landed groups. For each group:

1. **Pre-apply drift check**: confirm the working tree still matches the post-previous-group state. Specifically: there should be no changes to files outside the cumulative landed set since the last successful land. If unexpected files have been modified or appeared as untracked, **stop the loop** and report — do not overwrite.

2. **Dry-run check**: for each patch in the group (in synthesizer's intra-group order), run `git apply --check` against the current working tree. If any patch fails → mark the entire group **REJECTED (apply-fail)** and continue to the next group. Do not partially apply a group.

3. **Apply**: for each patch in the group, in ascending start-line order, run `git apply`.

4. **Test**: run the detected test command. Capture both timing and the last 50 lines of output (in case of failure).

5. **Gate**:
   - **Pass** → group **LANDED**. Record findings under `applied[]`. Move to next group.
   - **Fail** → reverse the group: for each patch in **reverse** of intra-group order, write the patch text to a tmp file and run `git apply -R <tmpfile>`.
     - If reverse succeeds for all patches → group **DEFERRED (test-fail)**. Capture a 20-line excerpt of test output for the report.
     - If reverse fails for any patch (rare; usually means cross-group conflict): take a `git stash push -u -m "consensus-review-rollback-<group_id>"`, then `git checkout -- <touched files>` to the last good state SHA + previously-landed-patches-only state. If you cannot cleanly recover the rolling-good state, **stop the loop** and report — do not continue with broken state.

6. **Slow test guard**: if a single test run exceeds `1.5 * BASELINE_SEC`, note it but continue. If it exceeds 5 min, ask the user whether to keep gating with the full suite or switch to a narrower target.

Never use `--no-verify`, `--force`, `--no-gpg-sign`, or skip tests.

## Phase 4: Report and hand off

Produce a markdown report with these sections, in order:

### Run summary

- Range reviewed (`RANGE` or equivalent).
- Mode (default / `--staged` / `--working`).
- Test command + baseline duration.
- Reviewers that succeeded vs. failed.

### Agreement matrix

Table from `APPLY_PLAN.agreement_matrix`: rows = unique buckets (`file:line`), columns = the 5 personas, cells = severity flagged or `—`. Sort by descending agent count, then descending max severity.

### Applied

For each landed group: `group_id`, files, agents who flagged, severity, one-line description per patch, and the synthesizer's `qualification_rationale`.

### Rejected (synthesizer)

- **Ungrounded** (from `rejected_ungrounded[]`): one row per finding, with citation, what was actually at the cited range, and the persona that produced it.

### Rejected (orchestrator)

- **Apply-fail**: groups that failed `git apply --check` against their target state.

### Deferred

- From `deferred[]`: per-group, with reason (`intra-group-conflict` | `cross-file-impact` | `not-enough-consensus`).
- From Phase 3: per-group, reason `test-fail`, with a 20-line test-output excerpt.

### Failed reviewers

List from `agent_failed[]` if any. Note that their findings are absent from the consensus.

### Final diff

Run `git diff $BASE_SHA..HEAD` (or `git diff` if you didn't commit anything, which is the expected case) and include the full diff verbatim.

### Next step

> Review the diff above. Reply `commit` to commit it, or name hunks to drop. **Stop.** Do not commit.

If you stashed in Phase 0, remind the user to `git stash pop` after they decide.

## Hard constraints

- Do not commit, push, or amend anything until the user explicitly approves.
- Do not bypass tests, hooks, or signing (`--no-verify`, `--force`, `-c commit.gpgsign=false` all banned).
- Do not invent file:line locations — every finding must be grounded; the synthesizer rejects hallucinations and you surface those rejections in the report.
- Do not surface raw subagent transcripts; only structured findings + the synthesizer's plan + your final report.
- If the working tree drifts unexpectedly between phases (untracked files appear, files outside the cumulative landed set get modified), stop and report rather than overwriting.
- Working tree must start clean in default mode. `--staged` and `--working` relax or disable this; document the mode in the run summary.
- Never delete `/tmp/consensus-review-diff.patch` until Phase 4 finishes (the synthesizer may need to re-read it).
