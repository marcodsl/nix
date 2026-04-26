#!/usr/bin/env nix-shell
#! nix-shell -i sh -p bash uv python3
""":"
exec uv run --script "$0" "$@"
":"""

# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
# ruff: noqa: E402
"""
Aggregate individual run results into benchmark summary statistics.

Reads grading.json files from run directories and produces:
- run_summary with mean, stddev, min, max for each metric
- delta between the preferred primary and baseline configurations

Usage:
    /path/to/skill-creator/scripts/aggregate_benchmark.py <benchmark_dir>

Example:
    ~/.copilot/skills/skill-creator/scripts/aggregate_benchmark.py \
      benchmarks/2026-01-15T10-30-00/

The script supports two directory layouts:

    Workspace layout (from skill-creator iterations):
    <benchmark_dir>/
    └── eval-N/
        ├── with_skill/
        │   ├── run-1/grading.json
        │   └── run-2/grading.json
        └── baseline-config/
            ├── run-1/grading.json
            └── run-2/grading.json

    Legacy layout (with runs/ subdirectory):
    <benchmark_dir>/
    └── runs/
        └── eval-N/
            ├── with_skill/
            │   └── run-1/grading.json
            └── baseline-config/
                └── run-1/grading.json
"""

import argparse
import json
import math
import sys
from datetime import UTC, datetime
from pathlib import Path


def read_json(path: Path) -> dict:
    """Read JSON from path, returning {} on missing/invalid files."""
    if not path.exists():
        return {}
    try:
        with path.open() as f:
            data = json.load(f)
        return data if isinstance(data, dict) else {}
    except (json.JSONDecodeError, OSError):
        return {}


def calculate_stats(values: list[float]) -> dict:
    """Calculate mean, stddev, min, max for a list of values."""
    if not values:
        return {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0}

    n = len(values)
    mean = sum(values) / n

    if n > 1:
        variance = sum((x - mean) ** 2 for x in values) / (n - 1)
        stddev = math.sqrt(variance)
    else:
        stddev = 0.0

    return {
        "mean": round(mean, 4),
        "stddev": round(stddev, 4),
        "min": round(min(values), 4),
        "max": round(max(values), 4),
    }


def preferred_config_order(configs: list[str]) -> list[str]:
    """Order configs so the primary-vs-baseline comparison is stable and semantic."""
    ordered: list[str] = []
    for preferred in ("with_skill", "new_skill"):
        if preferred in configs and preferred not in ordered:
            ordered.append(preferred)
    for preferred in ("baseline", "without_skill", "old_skill"):
        if preferred in configs and preferred not in ordered:
            ordered.append(preferred)
    for config in configs:
        if config not in ordered:
            ordered.append(config)
    return ordered


def legacy_expectations_from_assertions(assertions: list[dict]) -> list[dict]:
    """Adapt canonical assertion results to the older expectation viewer shape."""
    return [
        {
            "text": assertion.get("assertion_id", "unknown-assertion"),
            "passed": assertion.get("status") == "passed",
            "evidence": assertion.get("summary", ""),
        }
        for assertion in assertions
    ]


def summarize_for_benchmark(run_summary: dict) -> dict:
    """Build a compact numeric benchmark summary from run_summary."""
    configs = preferred_config_order(
        [config for config in run_summary if config != "delta"]
    )
    by_configuration = {}
    for config in configs:
        config_summary = run_summary.get(config, {})
        validity = config_summary.get("validity", {})
        by_configuration[config] = {
            "runs": validity.get("valid_runs", 0) + validity.get("invalid_runs", 0),
            "valid_runs": validity.get("valid_runs", 0),
            "invalid_runs": validity.get("invalid_runs", 0),
            "contaminated_runs": validity.get("contaminated_runs", 0),
            "avg_pass_rate": config_summary.get("pass_rate", {}).get("mean", 0.0),
            "avg_duration_seconds": config_summary.get("time_seconds", {}).get(
                "mean", 0.0
            ),
            "avg_output_chars": config_summary.get("output_chars", {}).get("mean", 0.0),
        }

    delta = run_summary.get("delta", {})
    return {
        "by_configuration": by_configuration,
        "delta": {
            "primary_config": delta.get("primary_config", ""),
            "baseline_config": delta.get("baseline_config", ""),
            "pass_rate": float(delta.get("pass_rate", "+0.00")),
            "duration_seconds": float(delta.get("time_seconds", "+0.0")),
            "output_chars": float(delta.get("output_chars", "+0")),
            **({"tokens": float(delta["tokens"])} if "tokens" in delta else {}),
        },
    }


def compute_diagnostics(results: dict[str, list[dict]]) -> list[dict]:
    """Derive initial machine-computed diagnostics from run results."""
    diagnostics: list[dict] = []
    seen_contaminated: set[tuple[int, str]] = set()
    seen_semantic_debt: set[tuple[int, str]] = set()
    assertion_status_by_config: dict[str, dict[str, set[str]]] = {}

    for config, runs in results.items():
        for result in runs:
            if result.get("baseline_contaminated"):
                key = (result["eval_id"], config)
                if key not in seen_contaminated:
                    diagnostics.append(
                        {
                            "kind": "contaminated_baseline",
                            "eval_id": result["eval_id"],
                            "configuration": config,
                            "message": (
                                "Baseline triggered the target skill and should "
                                "not be treated as a clean no-skill control."
                            ),
                        }
                    )
                    seen_contaminated.add(key)

            for assertion in result.get("assertions", []):
                assertion_id = assertion.get("assertion_id")
                if not assertion_id:
                    continue
                assertion_status_by_config.setdefault(assertion_id, {}).setdefault(
                    config, set()
                ).add(assertion.get("status", "unknown"))
                if assertion.get("status") == "unresolved":
                    debt_key = (result["eval_id"], assertion_id)
                    if debt_key not in seen_semantic_debt:
                        diagnostics.append(
                            {
                                "kind": "semantic_debt",
                                "eval_id": result["eval_id"],
                                "assertion_id": assertion_id,
                                "message": (
                                    "Assertion remained unresolved and still "
                                    "requires semantic fallback."
                                ),
                            }
                        )
                        seen_semantic_debt.add(debt_key)

    for assertion_id, by_config in sorted(assertion_status_by_config.items()):
        if len(by_config) < 2:
            continue
        normalized = {tuple(sorted(statuses)) for statuses in by_config.values()}
        if len(normalized) == 1:
            diagnostics.append(
                {
                    "kind": "non_differentiating_assertion",
                    "assertion_id": assertion_id,
                    "message": (
                        "This assertion produced the same status in every "
                        "configuration and did not help distinguish variants."
                    ),
                }
            )

    return diagnostics


def load_run_results(benchmark_dir: Path) -> dict:
    """
    Load all run results from a benchmark directory.

    Returns dict keyed by config name (e.g. "with_skill"/"without_skill",
    or "new_skill"/"old_skill"), each containing a list of run results.
    """
    # Support both layouts: eval dirs directly under benchmark_dir, or under runs/
    runs_dir = benchmark_dir / "runs"
    if runs_dir.exists():
        search_dir = runs_dir
    elif list(benchmark_dir.glob("eval-*")):
        search_dir = benchmark_dir
    else:
        print(
            f"No eval directories found in {benchmark_dir} or {benchmark_dir / 'runs'}"
        )
        return {}

    results: dict[str, list] = {}

    for eval_idx, eval_dir in enumerate(sorted(search_dir.glob("eval-*"))):
        metadata_path = eval_dir / "eval_metadata.json"
        eval_name = f"Eval {eval_idx}"
        if metadata_path.exists():
            try:
                with metadata_path.open() as mf:
                    metadata = json.load(mf)
                    eval_id = metadata.get("eval_id", eval_idx)
                    eval_name = metadata.get("eval_name", f"Eval {eval_id}")
            except (json.JSONDecodeError, OSError):
                eval_id = eval_idx
                eval_name = f"Eval {eval_idx}"
        else:
            try:
                eval_id = int(eval_dir.name.split("-")[1])
            except ValueError:
                eval_id = eval_idx
            eval_name = f"Eval {eval_id}"

        # Discover config directories dynamically rather than hardcoding names
        for config_dir in sorted(eval_dir.iterdir()):
            if not config_dir.is_dir():
                continue

            run_dirs = sorted(config_dir.glob("run-*"))
            if run_dirs:
                run_entries = []
                for run_dir in run_dirs:
                    try:
                        run_number = int(run_dir.name.split("-")[1])
                    except ValueError:
                        run_number = len(run_entries) + 1
                    run_entries.append((run_number, run_dir))
            elif (config_dir / "grading.json").exists():
                run_entries = [(1, config_dir)]
            else:
                # Skip non-config directories (inputs, outputs, etc.)
                continue

            config = config_dir.name
            if config not in results:
                results[config] = []

            for run_number, run_dir in run_entries:
                grading_file = run_dir / "grading.json"

                if not grading_file.exists():
                    print(f"Warning: grading.json not found in {run_dir}")
                    continue

                try:
                    with grading_file.open() as f:
                        grading = json.load(f)
                except json.JSONDecodeError as e:
                    print(f"Warning: Invalid JSON in {grading_file}: {e}")
                    continue

                # Extract metrics
                result = {
                    "eval_id": eval_id,
                    "eval_name": eval_name,
                    "run_number": run_number,
                    "pass_rate": grading.get("summary", {}).get("pass_rate", 0.0),
                    "passed": grading.get("summary", {}).get("passed", 0),
                    "failed": grading.get("summary", {}).get("failed", 0),
                    "total": grading.get("summary", {}).get("total", 0),
                }

                # Extract timing — check grading.json first, then sibling timing.json
                timing_data = {}
                timing = grading.get("timing", {})
                if isinstance(timing, dict):
                    timing_data.update(timing)
                timing_data.update(read_json(run_dir / "timing.json"))
                result["time_seconds"] = timing_data.get("total_duration_seconds", 0.0)
                result["tokens"] = timing_data.get("total_tokens")
                result["exit_code"] = timing_data.get("exit_code", 0)
                result["skill_triggered"] = timing_data.get("skill_triggered", False)
                result["baseline_contaminated"] = timing_data.get(
                    "baseline_contaminated", False
                )

                # Extract metrics if available
                grading_metrics = grading.get("execution_metrics", {})
                output_metrics = read_json(run_dir / "outputs" / "metrics.json")
                result["tool_calls"] = output_metrics.get(
                    "total_tool_calls", grading_metrics.get("total_tool_calls", 0)
                )
                result["output_chars"] = output_metrics.get(
                    "output_chars", grading_metrics.get("output_chars", 0)
                )
                result["errors"] = output_metrics.get(
                    "errors_encountered", grading_metrics.get("errors_encountered", 0)
                )
                if not result["skill_triggered"]:
                    result["skill_triggered"] = output_metrics.get(
                        "skill_triggered", grading_metrics.get("skill_triggered", False)
                    )

                raw_assertions = grading.get("assertions", [])
                raw_expectations = grading.get(
                    "expectations"
                ) or legacy_expectations_from_assertions(raw_assertions)
                for exp in raw_expectations:
                    if "text" not in exp or "passed" not in exp:
                        print(
                            "Warning: expectation in "
                            f"{grading_file} missing required fields "
                            f"(text, passed, evidence): {exp}"
                        )
                result["assertions"] = raw_assertions
                result["expectations"] = raw_expectations

                # Extract notes from user_notes_summary
                notes_summary = grading.get("user_notes_summary", {})
                notes = []
                notes.extend(notes_summary.get("uncertainties", []))
                notes.extend(notes_summary.get("needs_review", []))
                notes.extend(notes_summary.get("workarounds", []))
                result["notes"] = notes

                run_validity = grading.get("run_validity", {})
                if not run_validity:
                    issues = []
                    if result["baseline_contaminated"]:
                        issues.append(
                            "Baseline run still triggered the target skill, so "
                            "this is not a clean no-skill control"
                        )
                    elif (
                        config in {"without_skill", "baseline"}
                        and result["skill_triggered"]
                    ):
                        issues.append(
                            "Without-skill run triggered the target skill unexpectedly"
                        )
                    run_validity = {"valid": not issues, "issues": issues}
                result["run_validity"] = run_validity

                results[config].append(result)

    return results


def aggregate_results(results: dict) -> dict:
    """
    Aggregate run results into summary statistics.

    Returns run_summary with stats for each configuration and delta.
    """
    run_summary = {}
    configs = preferred_config_order(list(results.keys()))

    for config in configs:
        runs = results.get(config, [])

        if not runs:
            run_summary[config] = {
                "pass_rate": {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0},
                "time_seconds": {"mean": 0.0, "stddev": 0.0, "min": 0.0, "max": 0.0},
                "output_chars": {"mean": 0, "stddev": 0, "min": 0, "max": 0},
            }
            continue

        pass_rates = [r["pass_rate"] for r in runs]
        times = [r["time_seconds"] for r in runs]
        output_chars = [r.get("output_chars", 0) for r in runs]
        tokens = [r["tokens"] for r in runs if r.get("tokens") is not None]
        invalid_runs = sum(
            1 for r in runs if not r.get("run_validity", {}).get("valid", True)
        )
        contaminated_runs = sum(
            1 for r in runs if r.get("baseline_contaminated", False)
        )
        skill_triggered_runs = sum(1 for r in runs if r.get("skill_triggered", False))

        run_summary[config] = {
            "pass_rate": calculate_stats(pass_rates),
            "time_seconds": calculate_stats(times),
            "output_chars": calculate_stats(output_chars),
            "validity": {
                "valid_runs": len(runs) - invalid_runs,
                "invalid_runs": invalid_runs,
                "contaminated_runs": contaminated_runs,
                "skill_triggered_runs": skill_triggered_runs,
            },
        }
        if tokens:
            run_summary[config]["tokens"] = calculate_stats(tokens)

    # Calculate delta between the first two configs (if two exist)
    primary_config = configs[0] if configs else ""
    baseline_config = configs[1] if len(configs) >= 2 else ""
    if baseline_config:
        primary = run_summary.get(primary_config, {})
        baseline = run_summary.get(baseline_config, {})
    else:
        primary = run_summary.get(primary_config, {}) if primary_config else {}
        baseline = {}

    delta_pass_rate = primary.get("pass_rate", {}).get("mean", 0) - baseline.get(
        "pass_rate", {}
    ).get("mean", 0)
    delta_time = primary.get("time_seconds", {}).get("mean", 0) - baseline.get(
        "time_seconds", {}
    ).get("mean", 0)
    delta_output_chars = primary.get("output_chars", {}).get("mean", 0) - baseline.get(
        "output_chars", {}
    ).get("mean", 0)
    delta_tokens = primary.get("tokens", {}).get("mean", 0) - baseline.get(
        "tokens", {}
    ).get("mean", 0)

    run_summary["delta"] = {
        "primary_config": primary_config,
        "baseline_config": baseline_config,
        "pass_rate": f"{delta_pass_rate:+.2f}",
        "time_seconds": f"{delta_time:+.1f}",
        "output_chars": f"{delta_output_chars:+.0f}",
    }
    if primary.get("tokens") or baseline.get("tokens"):
        run_summary["delta"]["tokens"] = f"{delta_tokens:+.0f}"

    return run_summary


def generate_benchmark(
    benchmark_dir: Path, skill_name: str = "", skill_path: str = ""
) -> dict:
    """
    Generate complete benchmark.json from run results.
    """
    results = load_run_results(benchmark_dir)
    run_summary = aggregate_results(results)
    diagnostics = compute_diagnostics(results)

    # Build runs array for benchmark.json
    runs = []
    for config in results:
        for result in results[config]:
            result_payload = {
                "pass_rate": result["pass_rate"],
                "passed": result["passed"],
                "failed": result["failed"],
                "total": result["total"],
                "time_seconds": result["time_seconds"],
                "output_chars": result.get("output_chars", 0),
                "tool_calls": result.get("tool_calls", 0),
                "errors": result.get("errors", 0),
                "exit_code": result.get("exit_code", 0),
                "skill_triggered": result.get("skill_triggered", False),
                "baseline_contaminated": result.get("baseline_contaminated", False),
            }
            if result.get("tokens") is not None:
                result_payload["tokens"] = result["tokens"]

            runs.append(
                {
                    "eval_id": result["eval_id"],
                    "eval_name": result.get("eval_name", f"Eval {result['eval_id']}"),
                    "configuration": config,
                    "run_number": result["run_number"],
                    "run_dir": result.get("run_dir", ""),
                    "result": result_payload,
                    "summary": {
                        "pass_rate": result["pass_rate"],
                        "passed": result["passed"],
                        "failed": result["failed"],
                        "total": result["total"],
                    },
                    "validity": result.get(
                        "run_validity", {"valid": True, "issues": []}
                    ),
                    "run_validity": result.get(
                        "run_validity", {"valid": True, "issues": []}
                    ),
                    "assertions": result.get("assertions", []),
                    "expectations": result["expectations"],
                    "failed_assertions": [
                        assertion.get("assertion_id", "unknown-assertion")
                        for assertion in result.get("assertions", [])
                        if assertion.get("status") == "failed"
                    ],
                    "notes": result["notes"],
                }
            )

    # Determine eval IDs from results
    eval_ids = sorted({r["eval_id"] for config in results.values() for r in config})
    runs_per_configuration = max(
        (len(config_runs) for config_runs in results.values()), default=0
    )

    summary = summarize_for_benchmark(run_summary)

    return {
        "metadata": {
            "skill_name": skill_name or "<skill-name>",
            "skill_path": skill_path or "<path/to/skill>",
            "executor_model": "<model-name>",
            "analyzer_model": "<model-name>",
            "timestamp": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "evals_run": eval_ids,
            "runs_per_configuration": runs_per_configuration,
        },
        "runs": runs,
        "summary": summary,
        "run_summary": run_summary,
        "diagnostics": diagnostics,
        "notes": [],  # Optional narrative notes may still be added later.
    }


def generate_markdown(benchmark: dict) -> str:
    """Generate human-readable benchmark.md from benchmark data."""
    metadata = benchmark["metadata"]
    run_summary = benchmark["run_summary"]

    # Determine config names (excluding "delta")
    configs = preferred_config_order([k for k in run_summary if k != "delta"])
    config_a = configs[0] if len(configs) >= 1 else "config_a"
    config_b = configs[1] if len(configs) >= 2 else "config_b"
    label_a = config_a.replace("_", " ").title()
    label_b = config_b.replace("_", " ").title()
    delta = run_summary.get("delta", {})
    delta_label = (
        f"Delta ({label_a} - {label_b})" if config_b != "config_b" else "Delta"
    )

    lines = [
        f"# Skill Benchmark: {metadata['skill_name']}",
        "",
        f"**Model**: {metadata['executor_model']}",
        f"**Date**: {metadata['timestamp']}",
        (
            f"**Evals**: {', '.join(map(str, metadata['evals_run']))} "
            f"({metadata['runs_per_configuration']} runs each per configuration)"
        ),
        "",
        "## Summary",
        "",
        f"| Metric | {label_a} | {label_b} | {delta_label} |",
        "|--------|------------|---------------|-------|",
    ]

    a_summary = run_summary.get(config_a, {})
    b_summary = run_summary.get(config_b, {})

    # Format pass rate
    a_pr = a_summary.get("pass_rate", {})
    b_pr = b_summary.get("pass_rate", {})
    lines.append(
        f"| Pass Rate | {a_pr.get('mean', 0) * 100:.0f}% ± "
        f"{a_pr.get('stddev', 0) * 100:.0f}% | "
        f"{b_pr.get('mean', 0) * 100:.0f}% ± "
        f"{b_pr.get('stddev', 0) * 100:.0f}% | "
        f"{delta.get('pass_rate', '—')} |"
    )

    # Format time
    a_time = a_summary.get("time_seconds", {})
    b_time = b_summary.get("time_seconds", {})
    lines.append(
        f"| Time | {a_time.get('mean', 0):.1f}s ± "
        f"{a_time.get('stddev', 0):.1f}s | "
        f"{b_time.get('mean', 0):.1f}s ± "
        f"{b_time.get('stddev', 0):.1f}s | "
        f"{delta.get('time_seconds', '—')}s |"
    )

    # Format output chars
    a_output_chars = a_summary.get("output_chars", {})
    b_output_chars = b_summary.get("output_chars", {})
    lines.append(
        f"| Output Chars | {a_output_chars.get('mean', 0):.0f} ± "
        f"{a_output_chars.get('stddev', 0):.0f} | "
        f"{b_output_chars.get('mean', 0):.0f} ± "
        f"{b_output_chars.get('stddev', 0):.0f} | "
        f"{delta.get('output_chars', '—')} |"
    )
    if a_summary.get("tokens") or b_summary.get("tokens"):
        a_tokens = a_summary.get("tokens", {})
        b_tokens = b_summary.get("tokens", {})
        lines.append(
            f"| Tokens | {a_tokens.get('mean', 0):.0f} ± "
            f"{a_tokens.get('stddev', 0):.0f} | "
            f"{b_tokens.get('mean', 0):.0f} ± "
            f"{b_tokens.get('stddev', 0):.0f} | "
            f"{delta.get('tokens', '—')} |"
        )

    a_validity = a_summary.get("validity", {})
    b_validity = b_summary.get("validity", {})
    lines.append(
        f"| Invalid Runs | {a_validity.get('invalid_runs', 0)} | "
        f"{b_validity.get('invalid_runs', 0)} | — |"
    )
    lines.append(
        f"| Skill-Triggered Runs | {a_validity.get('skill_triggered_runs', 0)} | "
        f"{b_validity.get('skill_triggered_runs', 0)} | — |"
    )

    # Notes section
    if benchmark.get("notes"):
        lines.extend(["", "## Notes", ""])
        for note in benchmark["notes"]:
            lines.append(f"- {note}")

    if benchmark.get("diagnostics"):
        lines.extend(["", "## Diagnostics", ""])
        for diagnostic in benchmark["diagnostics"]:
            lines.append(
                f"- {diagnostic.get('kind', 'diagnostic')}: "
                f"{diagnostic.get('message', '')}"
            )

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Aggregate benchmark run results into summary statistics"
    )
    parser.add_argument(
        "benchmark_dir", type=Path, help="Path to the benchmark directory"
    )
    parser.add_argument(
        "--skill-name", default="", help="Name of the skill being benchmarked"
    )
    parser.add_argument(
        "--skill-path", default="", help="Path to the skill being benchmarked"
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        help="Output path for benchmark.json (default: <benchmark_dir>/benchmark.json)",
    )

    args = parser.parse_args()

    if not args.benchmark_dir.exists():
        print(f"Directory not found: {args.benchmark_dir}")
        sys.exit(1)

    # Generate benchmark
    benchmark = generate_benchmark(args.benchmark_dir, args.skill_name, args.skill_path)

    # Determine output paths
    output_json = args.output or (args.benchmark_dir / "benchmark.json")
    output_md = output_json.with_suffix(".md")

    # Write benchmark.json
    with output_json.open("w") as f:
        json.dump(benchmark, f, indent=2)
    print(f"Generated: {output_json}")

    # Write benchmark.md
    markdown = generate_markdown(benchmark)
    with output_md.open("w") as f:
        f.write(markdown)
    print(f"Generated: {output_md}")

    # Print summary
    run_summary = benchmark["run_summary"]
    configs = preferred_config_order([k for k in run_summary if k != "delta"])
    delta = run_summary.get("delta", {})

    print("\nSummary:")
    for config in configs:
        pr = run_summary[config]["pass_rate"]["mean"]
        label = config.replace("_", " ").title()
        print(f"  {label}: {pr * 100:.1f}% pass rate")
    delta_primary = delta.get("primary_config", configs[0] if configs else "config_a")
    delta_baseline = delta.get(
        "baseline_config", configs[1] if len(configs) >= 2 else "config_b"
    )
    print(
        "  Delta"
        f" ({delta_primary.replace('_', ' ').title()} - "
        f"{delta_baseline.replace('_', ' ').title()}): {delta.get('pass_rate', '—')}"
    )


if __name__ == "__main__":
    main()
