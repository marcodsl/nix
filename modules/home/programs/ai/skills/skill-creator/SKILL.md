---
name: skill-creator
description: Create, benchmark, and improve GitHub Copilot CLI skills with typed evals, deterministic grading, and trigger tests.
---

# Skill Creator

Use this skill to create a new Copilot skill or improve an existing one with real executions, saved artifacts, and deterministic-first review.

## Default stance

- Treat real Copilot executions as the source of truth.
- Keep the benchmark loop and the description-trigger loop separate.
- Default benchmark assertions to deterministic rules.
- Use semantic grading only for requirements a rule cannot decide cheaply.
- Preserve an existing skill name unless the user explicitly asks to rename it.
- Meet the user where they are. If they want a first draft, draft first. If they already have runs or feedback, continue from that point instead of restarting the whole loop.

## Explain the skill layout

When the user asks how to structure a skill, explain the three-layer loading model before suggesting file moves. State it in this order: metadata, SKILL.md, bundled resources.

1. Metadata in SKILL.md frontmatter is the discovery surface. Say the word `metadata`. `name` and `description` decide whether Copilot can find the skill.
2. The SKILL.md body is the loaded workflow surface. It should tell Copilot what to do once the skill loads.
3. Bundled resources are on-demand detail. Say `bundled resources` or name `references/`, `scripts/`, and `assets/` explicitly instead of only listing folders.

Use a layout like this when the skill needs supporting assets:

```text
skill-name/
  SKILL.md
  evals/
    evals.json
  references/
  scripts/
  assets/
  eval-viewer/
```

Keep SKILL.md focused. Move examples, schemas, and executable helpers into bundled resources.

## Use the bundled Python helpers by file path

This bundle's executable Python helpers manage their own runtime with a `nix-shell` launcher, `uv run --script`, and inline PEP 723 dependencies.

Use a stable absolute path or a stable environment variable:

```bash
SKILL_CREATOR=/absolute/path/to/skill-creator
TARGET_SKILL=/absolute/path/to/target-skill
```

Do not derive `SKILL_CREATOR` from a temporary benchmark copy or other materialized scratch bundle. Those paths belong to the helper's scratch project, not the source bundle. If the only visible copy is inside a temporary benchmark project, step back and set `SKILL_CREATOR` to the real repo or installed bundle path instead.

Invoke helpers by file path:

```bash
"$SKILL_CREATOR/scripts/quick_validate.py" "$TARGET_SKILL"
```

Do not rely on:

- `python -m scripts...`
- the current working directory already being correct
- manual virtualenv activation

If `nix-shell` or `uv` is not available, say so before you recommend the helper workflow.

## Start from the user's current state

Pick the shortest honest path forward.

- Idea only: capture intent, draft the skill, and ask whether they want eval scaffolding now or after the first version exists.
- Existing skill, no evals: validate the bundle, add realistic evals, and run the first benchmark wave.
- Existing benchmark workspace: continue from grading, aggregation, or review instead of rerunning everything.
- Triggering problem: use the description-trigger loop, not the benchmark loop.
- Install or update request: give a concrete sync workflow and avoid vague "copy the folder" advice.

## Create or revise the skill

Capture five things before you write:

1. What should this skill help Copilot do?
2. When should Copilot load it?
3. What does success look like in a real session?
4. Which references, scripts, or assets should be bundled instead of embedded in SKILL.md?
5. Does the user want a first draft, a benchmark loop, or both?

When you draft SKILL.md:

- keep the description compact and distinctive
- use the body for workflow and decision rules, not keyword stuffing
- add bundled helpers only when they remove repeated work or clarify a contract
- preserve existing names unless the user asks to rename the skill

## Write benchmark evals as typed contracts

Benchmark evals live in `evals/evals.json`. They are separate from description-trigger eval sets.

Each benchmark eval should include:

- a realistic `prompt`
- optional `files`
- an `expected_output` summary
- a `grading_mode`: `deterministic`, `hybrid`, or `semantic`
- a `baseline_strategy`: `prompt_only` or `snapshot`
- typed `assertions` with stable `assertion_id` values

Supported deterministic assertion types:

- `contains`
- `regex`
- `file_exists`
- `json_value`
- `json_path_exists`
- `tool_call_seen`
- `command_contains`
- `path_portability`
- `trace_field`

Use `semantic_assertion` only when the requirement is truly conceptual or subjective.

Use `baseline_strategy: snapshot` for contamination-prone prompts that naturally ask about skill improvement, triggering, review, or skill structure and can auto-load the target skill. Supply `--baseline-skill-path` during the benchmark run so those evals compare `with_skill` to `old_skill`; otherwise the runner falls back to a prompt-only baseline and records that fallback in `eval_metadata.json`.

Default to `deterministic`. Use `hybrid` when a small remainder needs semantic review after rules run. Use `semantic` only when the whole task is inherently open-ended.

The canonical artifact contract lives in `references/schemas.md`.

## Benchmark loop

Run the benchmark loop as one continuous sequence. Do not stop after the first response sample and call the skill evaluated.

Set stable paths first:

```bash
SKILL_CREATOR=/absolute/path/to/skill-creator
TARGET_SKILL=/absolute/path/to/target-skill
WORKSPACE=/absolute/path/to/<skill-name>-workspace
ITERATION="$WORKSPACE/iteration-1"
```

### Step 1: validate the bundle

```bash
"$SKILL_CREATOR/scripts/quick_validate.py" "$TARGET_SKILL"
```

Fix validation failures before benchmarking.

### Step 2: run with-skill and baseline executions

Use the benchmark helper:

```bash
"$SKILL_CREATOR/scripts/run_prompt_benchmark.py" \
  --skill-path "$TARGET_SKILL" \
  --workspace "$ITERATION"
```

This creates one directory per eval and configuration, such as:

```text
$ITERATION/
  eval-1/
    with_skill/
    baseline/
```

Each run should save replayable artifacts, including:

- `eval_metadata.json`
- `raw.jsonl`
- `stderr.txt`
- `transcript.md`
- `timing.json`
- `outputs/response.md`
- `outputs/metrics.json`
- `outputs/trace.json`

If a prompt-only baseline is contaminated because Copilot auto-loaded the target skill, rerun against an older snapshot instead of pretending the baseline is clean:

```bash
"$SKILL_CREATOR/scripts/run_prompt_benchmark.py" \
  --skill-path "$TARGET_SKILL" \
  --baseline-skill-path "$OLD_SKILL" \
  --workspace "$ITERATION"
```

Mixed baseline policies are allowed. If `evals/evals.json` marks only some evals with `baseline_strategy: snapshot`, the helper uses `old_skill` for those evals and prompt-only `baseline` for the rest when `--baseline-skill-path "$OLD_SKILL"` is present.

Treat `skill_triggered` and `baseline_contaminated` evidence as authoritative.

### Step 3: grade each run

Run deterministic grading once per run directory:

```bash
"$SKILL_CREATOR/scripts/grade_run.py" "$ITERATION/eval-1/with_skill"
"$SKILL_CREATOR/scripts/grade_run.py" "$ITERATION/eval-1/baseline"
```

Every run should end with a `grading.json` file before aggregation starts.

### Step 4: aggregate the iteration

```bash
"$SKILL_CREATOR/scripts/aggregate_benchmark.py" \
  "$ITERATION" \
  --skill-name "<skill-name>"
```

This writes:

- `benchmark.json`
- `benchmark.md`

The aggregate should surface diagnostics, not just a pass-rate summary.

### Step 5: review outputs and diagnostics

For an interactive review server:

```bash
"$SKILL_CREATOR/eval-viewer/generate_review.py" \
  "$ITERATION" \
  --skill-name "<skill-name>" \
  --benchmark "$ITERATION/benchmark.json"
```

To compare against the previous iteration, add:

```bash
--previous-workspace "$WORKSPACE/iteration-0"
```

For headless review, write a static HTML file instead of starting a server:

```bash
"$SKILL_CREATOR/eval-viewer/generate_review.py" \
  "$ITERATION" \
  --skill-name "<skill-name>" \
  --benchmark "$ITERATION/benchmark.json" \
  --previous-workspace "$WORKSPACE/iteration-0" \
  --static "$ITERATION/review.html"
```

When the user asks about headless review, explicitly mention `generate_review.py`, `--static`, `--previous-workspace`, and `diagnostics`.
Tell them to open `review.html`, inspect the benchmark and diagnostics view, and move or save `feedback.json` at the iteration root before the next rerun.

The viewer is the standard review surface. Use it instead of inventing a new one. It reads the workspace, benchmark summary, and optional prior iteration.

### Step 6: patch the skill and rerun only when the change is meaningful

Use feedback and failed assertions to fix real instruction gaps.

- Ignore empty feedback and low-signal comments.
- Say this plainly when the user asks: generalize from concrete failures instead of patching each complaint literally.
- Rerun only after a meaningful revision or meaningful change that should help more than one eval or run.
- Stop when the remaining misses are low-signal, contaminated, or would require obvious prompt-specific hacks.
- Preserve good behavior on held-out evals.
- Create a new `iteration-<N+1>/` directory for every rerun.
- If the review surface shows helper commands using a temporary benchmark copy or materialized scratch bundle, patch the instructions to use the real `SKILL_CREATOR` bundle path instead of the copied scratch location.

## How to judge benchmark results

Prefer saved facts over model judgment.

- `outputs/trace.json`, `outputs/metrics.json`, and `timing.json` should answer tool-use, path, and trigger questions before any semantic grader is asked.
- Promote repeated semantic checks into deterministic assertions when you can.
- Make provenance explicit in `grading.json` when any semantic fallback was used.
- Do not overstate findings from contaminated baselines, tiny sample sizes, or semantic-only judgments.

Use semantic review only for things the rule engine cannot decide cheaply, such as nuanced quality comparisons or open-ended conceptual correctness.

## Description-trigger loop

Keep this separate from the benchmark loop. It measures whether Copilot loads the skill for the right prompts; it does not grade the skill's full workflow output.

When the user asks about inconsistent loading, explicitly say `should-trigger` and `should-not-trigger` query sets.
Make deterministic description edits the first move: tighten the intent phrase, reorder trigger terms, add one disambiguator, remove generic wording, and test one candidate at a time with `run_eval.py`.
Treat model-generated rewriting through `run_loop.py` as a later automated search, not as the default first step.

The trigger eval set is a plain JSON array of objects with `query` and `should_trigger`. `assets/eval_review.html` can help the user review and export that file.

Example:

```json
[
  {
    "query": "Help me benchmark a Copilot skill with realistic evals and compare it against a baseline.",
    "should_trigger": true
  },
  {
    "query": "Summarize this README.",
    "should_trigger": false
  }
]
```

### Step 1: measure one description

```bash
TRIGGER_EVALS=/absolute/path/to/trigger-eval-set.json

"$SKILL_CREATOR/scripts/run_eval.py" \
  --eval-set "$TRIGGER_EVALS" \
  --skill-path "$TARGET_SKILL" \
  --runs-per-query 3 \
  --trigger-threshold 0.5
```

`run_eval.py` prints JSON with:

- `skill_name`
- `description`
- per-query `results`
- a `summary` with `total`, `passed`, and `failed`

Use this when the user wants measurement without automated rewriting.

### Step 2: run the optimization loop when the user wants automated search

`run_loop.py` still uses model-generated candidate descriptions through `improve_description.py`. Treat it as a candidate generator, not as truth. The truth is still the held-out trigger score.

If the user asks how to optimize the description, say that deterministic template or mutation search comes first and `run_loop.py` comes after that manual pass stops finding improvements.

```bash
"$SKILL_CREATOR/scripts/run_loop.py" \
  --eval-set "$TRIGGER_EVALS" \
  --skill-path "$TARGET_SKILL" \
  --model "<session-model>" \
  --max-iterations 5 \
  --runs-per-query 3 \
  --holdout 0.4 \
  --verbose \
  --results-dir "$WORKSPACE/description-loop"
```

Useful flags:

- `--description` to override the starting description
- `--report auto` or `--report /absolute/path/to/report.html` for a live HTML report
- `--report none` to disable the live report

When `--results-dir` is set, the loop writes `results.json`. If reporting is enabled, it also writes `report.html`.

The returned JSON includes:

- `exit_reason`
- `original_description`
- `best_description`
- `best_score`
- `best_train_score`
- `best_test_score`
- `final_description`
- `iterations_run`
- `holdout`
- `train_size`
- `test_size`
- `history`

Do not document or depend on `history.json`; the current tool does not write it.

### Step 3: apply the result carefully

- Prefer held-out performance over a description that merely sounds better.
- Review the proposed description before applying it.
- Update the frontmatter only after the trigger measurements justify the change.

## Installation and update workflow

When the user wants to install or update an existing skill, give a concrete sync procedure that starts from a source-of-truth directory outside `~/.copilot`.

Example:

```bash
SOURCE_SKILL=/absolute/path/to/repo/.github/skills/<name>
DEST_SKILL="$HOME/.copilot/skills/<name>"

"$SKILL_CREATOR/scripts/quick_validate.py" "$SOURCE_SKILL"
mkdir -p "$DEST_SKILL"
rsync -av --delete "$SOURCE_SKILL/" "$DEST_SKILL/"
```

Then tell the user to reload and inspect the installed skill:

- `/skills reload`
- `/skills info <name>`

Do not tell the user to edit the installed copy directly. Preserve the existing skill name unless they ask for a rename.

## Packaging

To create a portable archive:

```bash
"$SKILL_CREATOR/scripts/package_skill.py" "$TARGET_SKILL"
```

The output is a zip archive named after the skill. The packager validates first and excludes transient benchmark artifacts.

## Remaining model use

This bundle is deterministic-first, not model-free.

Use bundled model-driven helpers only where they still add value:

- `scripts/run_loop.py` and `scripts/improve_description.py` for candidate description generation
- `agents/grader.md` for unresolved semantic assertions
- `agents/comparator.md` for blind comparisons when the user explicitly wants them
- `agents/analyzer.md` for narrative synthesis on top of benchmark diagnostics

Everything else should default to typed contracts, saved artifacts, deterministic grading, and human review.

## Reference files

- `evals/evals.json`: benchmark scenarios and typed assertions
- `references/schemas.md`: artifact contracts
- `assets/eval_review.html`: review and export helper for trigger eval sets
- `agents/grader.md`: semantic fallback prompt for unresolved assertions
- `agents/comparator.md`: blind comparison prompt
- `agents/analyzer.md`: narrative analysis prompt

## Short reminder

1. Capture the user's real goal.
2. Write or revise the skill.
3. Add typed benchmark evals.
4. Run the benchmark loop end to end.
5. Patch only meaningful flaws.
6. Run the description-trigger loop separately if loading behavior is the problem.
7. Validate, package, or install once the workflow is stable.
