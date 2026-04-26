# JSON Schemas

This document defines the clean-break artifact contracts for the recreated deterministic-first `skill-creator` bundle.

Treat these shapes as the source of truth for benchmark tooling, grading, aggregation, and review.

---

## evals.json

Located at `evals/evals.json` inside the skill directory.

```json
{
  "skill_name": "example-skill",
  "evals": [
    {
      "id": 1,
      "eval_name": "install existing skill",
      "prompt": "I already have a Copilot skill in a repo. How do I sync it into ~/.copilot/skills?",
      "expected_output": "Gives a repeatable install or sync workflow.",
      "grading_mode": "deterministic",
      "baseline_strategy": "prompt_only",
      "files": [],
      "assertions": [
        {
          "assertion_id": "uses-path-based-helper",
          "type": "regex",
          "path": "outputs/response.md",
          "pattern": "scripts/.+\\.py"
        },
        {
          "assertion_id": "avoids-cwd-sensitive-paths",
          "type": "path_portability",
          "path": "outputs/response.md",
          "forbid": ["$PWD/", "/tmp/"],
          "allow_relative": true
        }
      ]
    }
  ]
}
```

### Required fields

- `skill_name`: must match the skill frontmatter name
- `evals[].id`: stable integer identifier
- `evals[].prompt`: the user request used for the run
- `evals[].expected_output`: human-readable success description for review
- `evals[].grading_mode`: one of `deterministic`, `hybrid`, or `semantic`
- `evals[].baseline_strategy`: one of `prompt_only` or `snapshot`
- `evals[].assertions[]`: typed assertions with stable `assertion_id` values

### Optional fields

- `evals[].eval_name`: short human-readable label for reports and review UIs
- `evals[].files`: input file paths relative to the skill root, or absolute paths copied into the temporary benchmark project
- `evals[].baseline_strategy`: per-eval baseline policy. `snapshot` uses `old_skill` when `--baseline-skill-path` is supplied; otherwise the runner falls back to `prompt_only` and records that fallback in `eval_metadata.json`
- `evals[].notes`: authoring notes that should not affect grading

### Assertion contract

Every assertion must include:

- `assertion_id`: stable identifier used for aggregation and diagnostics
- `type`: assertion kind

Type-specific fields depend on `type`.

### Supported deterministic assertion types

#### `contains`

```json
{
  "assertion_id": "mentions-reload",
  "type": "contains",
  "path": "outputs/response.md",
  "needle": "/skills reload",
  "case_sensitive": false
}
```

#### `regex`

```json
{
  "assertion_id": "uses-static-review-command",
  "type": "regex",
  "path": "outputs/response.md",
  "pattern": "generate_review\\.py[\\s\\S]*--static"
}
```

#### `file_exists`

```json
{
  "assertion_id": "writes-benchmark-json",
  "type": "file_exists",
  "path": "benchmark.json"
}
```

#### `json_value`

```json
{
  "assertion_id": "baseline-marked-contaminated",
  "type": "json_value",
  "path": "timing.json",
  "field": "baseline_contaminated",
  "equals": true
}
```

#### `json_path_exists`

```json
{
  "assertion_id": "trace-has-shell-commands",
  "type": "json_path_exists",
  "path": "outputs/trace.json",
  "field": "shell_commands"
}
```

#### `tool_call_seen`

```json
{
  "assertion_id": "saw-read-file",
  "type": "tool_call_seen",
  "path": "outputs/trace.json",
  "tool": "read_file",
  "min_count": 1
}
```

#### `command_contains`

```json
{
  "assertion_id": "aggregate-command-mentioned",
  "type": "command_contains",
  "path": "outputs/trace.json",
  "needle": "aggregate_benchmark.py"
}
```

#### `path_portability`

```json
{
  "assertion_id": "portable-helper-paths",
  "type": "path_portability",
  "path": "outputs/response.md",
  "forbid": ["$PWD/", "/tmp/"],
  "allow_relative": true
}
```

#### `trace_field`

```json
{
  "assertion_id": "target-skill-fired",
  "type": "trace_field",
  "path": "outputs/trace.json",
  "field": "skill_triggered",
  "equals": true
}
```

### Semantic assertion type

Use this only when deterministic checks are not enough.

```json
{
  "assertion_id": "explains-progressive-disclosure",
  "type": "semantic_assertion",
  "path": "outputs/response.md",
  "prompt": "Decide whether the response explicitly explains the three-layer model: metadata as discovery surface, SKILL.md as loaded workflow, bundled resources as on-demand detail.",
  "rubric": ["Fails if the answer only suggests splitting files without naming the three layers.", "Passes if the answer explains why each layer exists."]
}
```

---

## eval_metadata.json

Located at `<run-dir>/eval_metadata.json`.

```json
{
  "eval_id": 1,
  "eval_name": "install existing skill",
  "prompt": "I already have a Copilot skill in a repo. How do I sync it into ~/.copilot/skills?",
  "expected_output": "Gives a repeatable install or sync workflow.",
  "grading_mode": "deterministic",
  "configuration": "with_skill",
  "run_number": 1,
  "skill_name": "example-skill",
  "skill_path": "/abs/path/to/skill",
  "baseline_strategy_requested": "prompt_only",
  "baseline_strategy_applied": "prompt_only",
  "baseline_kind": "no_skill",
  "files": []
}
```

---

## metrics.json

Located at `<run-dir>/outputs/metrics.json`.

```json
{
  "tool_call_counts": {
    "read_file": 4,
    "run_in_terminal": 1
  },
  "total_tool_calls": 5,
  "errors_encountered": 0,
  "files_created": [],
  "response_chars": 1420,
  "transcript_chars": 2310,
  "skill_triggered": true,
  "baseline_contaminated": false
}
```

---

## trace.json

Located at `<run-dir>/outputs/trace.json`.

```json
{
  "skill_name": "example-skill",
  "configuration": "with_skill",
  "skill_triggered": true,
  "baseline_contaminated": false,
  "tool_call_counts": {
    "read_file": 4,
    "run_in_terminal": 1
  },
  "tool_names": ["read_file", "run_in_terminal"],
  "shell_commands": ["/abs/path/to/skill-creator/scripts/quick_validate.py /abs/path/to/skill"],
  "path_mentions": {
    "absolute": ["/abs/path/to/skill-creator/scripts/quick_validate.py"],
    "relative": [],
    "cwd_sensitive": [],
    "transient": []
  },
  "events": [
    {
      "kind": "tool_call",
      "tool": "read_file",
      "count": 4
    }
  ]
}
```

This artifact is the preferred source for trace-derived assertions.

---

## timing.json

Located at `<run-dir>/timing.json`.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3,
  "executor_start": "2026-01-15T10:30:00Z",
  "executor_end": "2026-01-15T10:30:23Z",
  "executor_duration_seconds": 23.3,
  "exit_code": 0,
  "skill_triggered": true,
  "baseline_contaminated": false
}
```

---

## grading.json

Located at `<run-dir>/grading.json`.

```json
{
  "eval_id": 1,
  "configuration": "with_skill",
  "grading_mode": "hybrid",
  "assertions": [
    {
      "assertion_id": "mentions-reload",
      "type": "contains",
      "status": "passed",
      "source": "deterministic",
      "path": "outputs/response.md",
      "summary": "Found '/skills reload' in outputs/response.md.",
      "evidence": ["/skills reload"],
      "observed": {
        "matches": ["/skills reload"]
      }
    },
    {
      "assertion_id": "explains-progressive-disclosure",
      "type": "semantic_assertion",
      "status": "passed",
      "source": "semantic_fallback",
      "path": "outputs/response.md",
      "summary": "The response names metadata, SKILL.md, and bundled resources explicitly.",
      "evidence": ["Metadata is the discovery surface", "Bundled resources are on-demand detail"]
    }
  ],
  "summary": {
    "passed": 2,
    "failed": 0,
    "unresolved": 0,
    "skipped": 0,
    "total": 2,
    "pass_rate": 1.0
  },
  "run_validity": {
    "valid": true,
    "issues": []
  },
  "provenance": {
    "deterministic_complete": false,
    "semantic_fallback_used": true,
    "semantic_assertions": ["explains-progressive-disclosure"]
  }
}
```

### Assertion statuses

- `passed`
- `failed`
- `unresolved`
- `skipped`

### Assertion sources

- `deterministic`
- `semantic_fallback`
- `pending_semantic_fallback`
- `not_applicable`

---

## benchmark.json

Located at `<workspace>/iteration-<N>/benchmark.json`.

```json
{
  "metadata": {
    "skill_name": "example-skill",
    "skill_path": "/abs/path/to/skill",
    "timestamp": "2026-01-15T10:30:00Z",
    "configurations": ["with_skill", "baseline"]
  },
  "runs": [
    {
      "eval_id": 1,
      "eval_name": "install existing skill",
      "configuration": "with_skill",
      "run_dir": "/abs/path/to/workspace/iteration-1/eval-1/with_skill",
      "summary": {
        "pass_rate": 1.0,
        "passed": 2,
        "failed": 0,
        "unresolved": 0
      },
      "validity": {
        "valid": true,
        "issues": []
      },
      "failed_assertions": []
    }
  ],
  "summary": {
    "by_configuration": {
      "with_skill": {
        "runs": 8,
        "valid_runs": 8,
        "avg_pass_rate": 0.92,
        "avg_duration_seconds": 18.4
      },
      "baseline": {
        "runs": 8,
        "valid_runs": 7,
        "avg_pass_rate": 0.41,
        "avg_duration_seconds": 16.9
      }
    },
    "delta": {
      "pass_rate": 0.51,
      "duration_seconds": 1.5
    }
  },
  "diagnostics": [
    {
      "kind": "contaminated_baseline",
      "eval_id": 4,
      "message": "Baseline triggered the target skill and should not be treated as a clean no-skill control."
    },
    {
      "kind": "non_differentiating_assertion",
      "assertion_id": "mentions-benchmark-json",
      "message": "This assertion passed in every configuration and did not help distinguish variants."
    }
  ]
}
```

The `diagnostics` array is for computed findings, not free-form commentary.

---

## trigger_eval_set.json

Passed to `run_eval.py` and `run_loop.py` via `--eval-set`.

The file is a plain JSON array. Each item must provide `query` and `should_trigger`.

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

Extra keys are currently ignored, but the documented contract is just `query` and `should_trigger`.

---

## trigger_results.json

Produced on stdout by `run_eval.py`.

```json
{
  "skill_name": "example-skill",
  "description": "Benchmark Copilot skills against real executions.",
  "results": [
    {
      "query": "Help me benchmark a Copilot skill with realistic evals and compare it against a baseline.",
      "should_trigger": true,
      "trigger_rate": 1.0,
      "triggers": 3,
      "runs": 3,
      "pass": true
    }
  ],
  "summary": {
    "total": 10,
    "passed": 9,
    "failed": 1
  }
}
```

`trigger_rate` is `triggers / runs`. `pass` applies the configured `trigger_threshold`.

---

## results.json

Written by `run_loop.py` when `--results-dir` is set. The same object is also printed to stdout.

```json
{
  "exit_reason": "max_iterations (5)",
  "original_description": "Create or update Copilot skills.",
  "best_description": "Create, benchmark, and improve GitHub Copilot CLI skills with typed evals and deterministic grading.",
  "best_score": "8/10",
  "best_train_score": "5/6",
  "best_test_score": "3/4",
  "final_description": "Create, benchmark, and improve GitHub Copilot CLI skills with typed evals and deterministic grading.",
  "iterations_run": 5,
  "holdout": 0.4,
  "train_size": 6,
  "test_size": 4,
  "history": [
    {
      "iteration": 1,
      "description": "Create or update Copilot skills.",
      "train_passed": 4,
      "train_failed": 2,
      "train_total": 6,
      "train_results": [
        {
          "query": "Help me benchmark a Copilot skill with realistic evals and compare it against a baseline.",
          "should_trigger": true,
          "trigger_rate": 1.0,
          "triggers": 3,
          "runs": 3,
          "pass": true
        }
      ],
      "test_passed": 2,
      "test_failed": 2,
      "test_total": 4,
      "test_results": [
        {
          "query": "Summarize this README.",
          "should_trigger": false,
          "trigger_rate": 0.33,
          "triggers": 1,
          "runs": 3,
          "pass": false
        }
      ],
      "passed": 4,
      "failed": 2,
      "total": 6,
      "results": [
        {
          "query": "Help me benchmark a Copilot skill with realistic evals and compare it against a baseline.",
          "should_trigger": true,
          "trigger_rate": 1.0,
          "triggers": 3,
          "runs": 3,
          "pass": true
        }
      ]
    }
  ]
}
```

`history` intentionally duplicates the train summary under `passed`, `failed`, `total`, and `results` for backward compatibility with `generate_report.py`.

`run_loop.py` does not write `history.json`.
{
"assertion_id": "mentions-with-skill-run",
"type": "contains",
"path": "outputs/response.md",
"needle": "with_skill",
"case_sensitive": false
},
{
"assertion_id": "mentions-baseline-run",
"type": "contains",
"path": "outputs/response.md",
"needle": "baseline",
"case_sensitive": false
},
{
"assertion_id": "mentions-trace-artifact",
"type": "contains",
"path": "outputs/response.md",
"needle": "outputs/trace.json",
"case_sensitive": false
},
{
"assertion_id": "mentions-grading-step",
"type": "contains",
"path": "outputs/response.md",
"needle": "grading.json",
"case_sensitive": false
}
]
},
{
"id": 3,
"eval_name": "optimize description trigger loop",
"prompt": "I think my skill works, but Copilot still loads it inconsistently. How should I optimize the description and what command should I run for the trigger eval loop?",
"expected_output": "Describes should-trigger and should-not-trigger queries, deterministic-first search, and the run_eval or run_loop commands.",
"grading_mode": "deterministic",
"baseline_strategy": "snapshot",
"files": [],
"assertions": [
{
"assertion_id": "mentions-trigger-query-sets",
"type": "contains",
"path": "outputs/response.md",
"needle": "should-trigger",
"case_sensitive": false
},
{
"assertion_id": "mentions-run-loop-command",
"type": "contains",
"path": "outputs/response.md",
"needle": "run_loop.py",
"case_sensitive": false
},
{
"assertion_id": "mentions-run-eval-command",
"type": "contains",
"path": "outputs/response.md",
"needle": "run_eval.py",
"case_sensitive": false
},
{
"assertion_id": "puts-manual-edits-first",
"type": "regex",
"path": "outputs/response.md",
"pattern": "manual(ly)? first|deterministic description edits the first move|one change at a time|one candidate at a time"
},
{
"assertion_id": "treats-run-loop-as-later-pass",
"type": "regex",
"path": "outputs/response.md",
"pattern": "after manual edits stop helping|after that manual pass stops finding improvements|later automated search|after manual.*run_loop\\.py|run_loop\\.py comes after"
}
]
},
{
"id": 4,
"eval_name": "recover from contaminated baseline",
"prompt": "My with-skill vs baseline benchmark looks suspicious because the baseline may have auto-loaded the same skill. What exact rerun setup should I use so the comparison is honest, and what metadata should I record to prove the baseline was contaminated?",
"expected_output": "Explains how to detect baseline contamination, rerun with an older snapshot, and preserve the contamination evidence.",
"grading_mode": "deterministic",
"files": [],
"assertions": [
{
"assertion_id": "mentions-baseline-contamination",
"type": "contains",
"path": "outputs/response.md",
"needle": "contaminated",
"case_sensitive": false
},
{
"assertion_id": "mentions-baseline-skill-path",
"type": "contains",
"path": "outputs/response.md",
"needle": "--baseline-skill-path",
"case_sensitive": false
},
{
"assertion_id": "mentions-contamination-metadata",
"type": "regex",
"path": "outputs/response.md",
"pattern": "skill_triggered|baseline_contaminated"
}
]
},
{
"id": 5,
"eval_name": "grade and aggregate benchmark",
"prompt": "I already have a benchmark workspace full of eval runs. How should I grade every run and turn the results into benchmark.json without hand-waving over the file layout or the saved artifacts?",
"expected_output": "Describes per-run grading into grading.json and aggregation into benchmark.json.",
"grading_mode": "deterministic",
"files": [],
"assertions": [
{
"assertion_id": "mentions-grade-run-script",
"type": "contains",
"path": "outputs/response.md",
"needle": "grade_run.py",
"case_sensitive": false
},
{
"assertion_id": "mentions-grading-json",
"type": "contains",
"path": "outputs/response.md",
"needle": "grading.json",
"case_sensitive": false
},
{
"assertion_id": "mentions-aggregate-command",
"type": "contains",
"path": "outputs/response.md",
"needle": "aggregate_benchmark.py",
"case_sensitive": false
},
{
"assertion_id": "mentions-benchmark-json",
"type": "contains",
"path": "outputs/response.md",
"needle": "benchmark.json",
"case_sensitive": false
}
]
},
{
"id": 6,
"eval_name": "headless review viewer",
"prompt": "I need to review iteration 2 on a headless machine and compare it against iteration 1. What review command should I run, and how should I use the result once it exists?",
"expected_output": "Uses generate_review.py in static mode with previous-workspace support and explains the review surface.",
"grading_mode": "deterministic",
"files": [],
"assertions": [
{
"assertion_id": "mentions-generate-review",
"type": "contains",
"path": "outputs/response.md",
"needle": "generate_review.py",
"case_sensitive": false
},
{
"assertion_id": "mentions-static-flag",
"type": "contains",
"path": "outputs/response.md",
"needle": "--static",
"case_sensitive": false
},
{
"assertion_id": "mentions-previous-workspace-flag",
"type": "contains",
"path": "outputs/response.md",
"needle": "--previous-workspace",
"case_sensitive": false
},
{
"assertion_id": "mentions-diagnostics-review",
"type": "contains",
"path": "outputs/response.md",
"needle": "diagnostics",
"case_sensitive": false
}
]
},
{
"id": 7,
"eval_name": "use feedback without overfitting",
"prompt": "I finished reviewing the benchmark and exported feedback.json. How should I decide what to patch, what to ignore, and when to stop iterating instead of overfitting the skill?",
"expected_output": "Explains how to use concrete feedback, ignore low-signal noise, and rerun only after meaningful revisions.",
"grading_mode": "deterministic",
"baseline_strategy": "snapshot",
"files": [],
"assertions": [
{
"assertion_id": "mentions-ignore-low-signal-feedback",
"type": "regex",
"path": "outputs/response.md",
"pattern": "low-signal|empty feedback"
},
{
"assertion_id": "mentions-meaningful-rerun-threshold",
"type": "regex",
"path": "outputs/response.md",
"pattern": "meaningful revision|meaningful change"
},
{
"assertion_id": "treats-feedback-as-hints",
"type": "regex",
"path": "outputs/response.md",
"pattern": "hints, not truth|evidence first, comments second|backed by saved artifacts"
},
{
"assertion_id": "mentions-eval-prompt-test",
"type": "regex",
"path": "outputs/response.md",
"pattern": "without naming the eval prompt|without naming the eval"
},
{
"assertion_id": "requires-multi-run-benefit",
"type": "regex",
"path": "outputs/response.md",
"pattern": "more than one run|multiple runs/evals|multiple evals|help more than one run"
}
]
},
{
"id": 8,
"eval_name": "explain progressive disclosure",
"prompt": "My skill is growing and starting to feel bloated. How should I split SKILL.md, scripts, references, and assets so Copilot gets the right amount of context without burying the important instructions?",
"expected_output": "Explains progressive disclosure across metadata, SKILL.md, and bundled resources, then maps scripts, references, and assets onto that model.",
"grading_mode": "deterministic",
"baseline_strategy": "snapshot",
"files": [],
"assertions": [
{
"assertion_id": "mentions-metadata-layer",
"type": "contains",
"path": "outputs/response.md",
"needle": "metadata",
"case_sensitive": false
},
{
"assertion_id": "mentions-skill-md-layer",
"type": "contains",
"path": "outputs/response.md",
"needle": "SKILL.md",
"case_sensitive": false
},
{
"assertion_id": "mentions-bundled-resources-layer",
"type": "regex",
"path": "outputs/response.md",
"pattern": "bundled resources|references|scripts|assets"
},
{
"assertion_id": "explains-discovery-surface",
"type": "contains",
"path": "outputs/response.md",
"needle": "discovery surface",
"case_sensitive": false
},
{
"assertion_id": "explains-loaded-workflow",
"type": "contains",
"path": "outputs/response.md",
"needle": "loaded workflow",
"case_sensitive": false
},
{
"assertion_id": "explains-on-demand-detail",
"type": "regex",
"path": "outputs/response.md",
"pattern": "on-demand detail|available only when needed|only when needed"
}
]
}
]
}
