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
"""Deterministically grade a single skill benchmark run."""

import argparse
import json
import re
from pathlib import Path


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        with path.open() as handle:
            data = json.load(handle)
    except (json.JSONDecodeError, OSError):
        return {}
    return data if isinstance(data, dict) else {}


def _read_text(path: Path) -> str:
    if not path.exists():
        return ""
    try:
        return path.read_text()
    except OSError:
        return ""


def _lookup_field(data: object, field: str) -> tuple[bool, object | None]:
    current = data
    for part in field.split("."):
        if isinstance(current, dict) and part in current:
            current = current[part]
            continue
        if isinstance(current, list) and part.isdigit():
            index = int(part)
            if 0 <= index < len(current):
                current = current[index]
                continue
        return False, None
    return True, current


def _normalize_assertions(raw_assertions: list[object]) -> list[dict]:
    normalized: list[dict] = []
    for item in raw_assertions:
        if isinstance(item, dict):
            normalized.append(item)
        elif isinstance(item, str):
            normalized.append(
                {
                    "assertion_id": item,
                    "type": "semantic_assertion",
                    "prompt": item,
                }
            )
    return normalized


def _result(
    *,
    assertion: dict,
    status: str,
    source: str,
    summary: str,
    evidence: list[str] | None = None,
    observed: object | None = None,
) -> dict:
    result = {
        "assertion_id": assertion.get("assertion_id", "unknown-assertion"),
        "type": assertion.get("type", "unknown"),
        "status": status,
        "source": source,
        "path": assertion.get("path"),
        "summary": summary,
        "evidence": evidence or [],
    }
    if observed is not None:
        result["observed"] = observed
    return result


def _evaluate_assertion(assertion: dict, run_dir: Path) -> dict:
    assertion_type = assertion.get("type")
    target_path = run_dir / assertion.get("path", "") if assertion.get("path") else None

    if assertion_type == "contains":
        text = _read_text(target_path) if target_path else ""
        needle = assertion.get("needle", "")
        haystack = text if assertion.get("case_sensitive", True) else text.lower()
        probe = needle if assertion.get("case_sensitive", True) else needle.lower()
        passed = bool(probe) and probe in haystack
        return _result(
            assertion=assertion,
            status="passed" if passed else "failed",
            source="deterministic",
            summary=(
                f"Found {needle!r} in {assertion.get('path')}."
                if passed
                else f"Did not find {needle!r} in {assertion.get('path')}."
            ),
            evidence=[needle] if passed else [],
            observed={"needle": needle},
        )

    if assertion_type == "regex":
        text = _read_text(target_path) if target_path else ""
        flags = 0 if assertion.get("case_sensitive", True) else re.IGNORECASE
        pattern = assertion.get("pattern", "")
        match = re.search(pattern, text, flags)
        return _result(
            assertion=assertion,
            status="passed" if match else "failed",
            source="deterministic",
            summary=(
                f"Pattern {pattern!r} matched {assertion.get('path')}."
                if match
                else f"Pattern {pattern!r} did not match {assertion.get('path')}."
            ),
            evidence=[match.group(0)] if match else [],
            observed={"pattern": pattern},
        )

    if assertion_type == "file_exists":
        exists = (run_dir / assertion.get("path", "")).exists()
        return _result(
            assertion=assertion,
            status="passed" if exists else "failed",
            source="deterministic",
            summary=(
                f"Found expected file {assertion.get('path')}."
                if exists
                else f"Missing expected file {assertion.get('path')}."
            ),
        )

    if assertion_type in {"json_value", "json_path_exists", "trace_field"}:
        payload = _read_json(target_path) if target_path else {}
        field = assertion.get("field", "")
        found, value = _lookup_field(payload, field) if field else (False, None)
        if assertion_type == "json_path_exists":
            return _result(
                assertion=assertion,
                status="passed" if found else "failed",
                source="deterministic",
                summary=(
                    f"Found JSON field {field!r} in {assertion.get('path')}."
                    if found
                    else f"Missing JSON field {field!r} in {assertion.get('path')}."
                ),
                observed={"field": field, "value": value},
            )

        expected = assertion.get("equals")
        passed = found and value == expected
        return _result(
            assertion=assertion,
            status="passed" if passed else "failed",
            source="deterministic",
            summary=(
                f"Field {field!r} matched expected value {expected!r}."
                if passed
                else f"Field {field!r} did not match expected value {expected!r}."
            ),
            observed={"field": field, "value": value, "expected": expected},
        )

    if assertion_type == "tool_call_seen":
        payload = _read_json(target_path) if target_path else {}
        tool = assertion.get("tool", "")
        min_count = int(assertion.get("min_count", 1))
        tool_call_counts = payload.get("tool_call_counts", {})
        actual = tool_call_counts.get(tool, 0)
        passed = actual >= min_count
        return _result(
            assertion=assertion,
            status="passed" if passed else "failed",
            source="deterministic",
            summary=(
                f"Saw tool {tool!r} {actual} time(s)."
                if passed
                else (
                    f"Saw tool {tool!r} only {actual} time(s); expected at least "
                    f"{min_count}."
                )
            ),
            observed={"tool": tool, "actual": actual, "min_count": min_count},
        )

    if assertion_type == "command_contains":
        payload = _read_json(target_path) if target_path else {}
        needle = assertion.get("needle", "")
        commands = payload.get("shell_commands", [])
        matches = [command for command in commands if needle in command]
        return _result(
            assertion=assertion,
            status="passed" if matches else "failed",
            source="deterministic",
            summary=(
                f"Found {needle!r} in captured shell commands."
                if matches
                else f"Did not find {needle!r} in captured shell commands."
            ),
            evidence=matches,
        )

    if assertion_type == "path_portability":
        text = _read_text(target_path) if target_path else ""
        forbidden = assertion.get("forbid", [])
        matches = [token for token in forbidden if token and token in text]
        return _result(
            assertion=assertion,
            status="failed" if matches else "passed",
            source="deterministic",
            summary=(
                (
                    "Found forbidden path patterns in "
                    f"{assertion.get('path')}: {', '.join(matches)}."
                )
                if matches
                else f"No forbidden path patterns found in {assertion.get('path')}."
            ),
            evidence=matches,
        )

    if assertion_type == "semantic_assertion":
        return _result(
            assertion=assertion,
            status="unresolved",
            source="pending_semantic_fallback",
            summary="Requires semantic fallback grading.",
            observed={"prompt": assertion.get("prompt", "")},
        )

    return _result(
        assertion=assertion,
        status="unresolved",
        source="not_applicable",
        summary=f"Unsupported assertion type: {assertion_type!r}.",
    )


def _build_run_validity(run_dir: Path, timing: dict) -> dict:
    issues: list[str] = []
    if not (run_dir / "outputs" / "response.md").exists():
        issues.append("Missing outputs/response.md")
    if timing.get("exit_code") not in {None, 0}:
        issues.append(f"Executor exited with code {timing.get('exit_code')}")
    if timing.get("baseline_contaminated"):
        issues.append(
            "Baseline run still triggered the target skill, so this is not a "
            "clean no-skill control"
        )
    return {"valid": not issues, "issues": issues}


def main() -> None:
    parser = argparse.ArgumentParser(description="Deterministically grade one run")
    parser.add_argument("run_dir", help="Run directory containing artifacts")
    args = parser.parse_args()

    run_dir = Path(args.run_dir).resolve()
    if not run_dir.exists():
        raise SystemExit(f"Run directory does not exist: {run_dir}")

    metadata = _read_json(run_dir / "eval_metadata.json")
    if not metadata:
        metadata = _read_json(run_dir.parent / "eval_metadata.json")
    assertions = _normalize_assertions(metadata.get("assertions", []))

    metrics = _read_json(run_dir / "outputs" / "metrics.json")
    timing = _read_json(run_dir / "timing.json")

    results = [_evaluate_assertion(assertion, run_dir) for assertion in assertions]
    passed = sum(result["status"] == "passed" for result in results)
    failed = sum(result["status"] == "failed" for result in results)
    unresolved = sum(result["status"] == "unresolved" for result in results)
    skipped = sum(result["status"] == "skipped" for result in results)
    total = len(results)
    deterministic_complete = all(
        result["source"] == "deterministic" for result in results
    )
    semantic_assertions = [
        result["assertion_id"]
        for result in results
        if result["source"] == "pending_semantic_fallback"
    ]

    grading = {
        "eval_id": metadata.get("eval_id"),
        "configuration": metadata.get("configuration"),
        "grading_mode": metadata.get("grading_mode", "deterministic"),
        "assertions": results,
        "expectations": [
            {
                "text": result["assertion_id"],
                "passed": result["status"] == "passed",
                "evidence": result["summary"],
            }
            for result in results
        ],
        "summary": {
            "passed": passed,
            "failed": failed,
            "unresolved": unresolved,
            "skipped": skipped,
            "total": total,
            "pass_rate": round((passed / total), 4) if total else 0.0,
        },
        "execution_metrics": {
            "tool_calls": metrics.get(
                "tool_call_counts", metrics.get("tool_calls", {})
            ),
            "total_tool_calls": metrics.get("total_tool_calls", 0),
            "errors_encountered": metrics.get("errors_encountered", 0),
            "output_chars": metrics.get(
                "output_chars", metrics.get("response_chars", 0)
            ),
            "transcript_chars": metrics.get("transcript_chars", 0),
            "skill_triggered": metrics.get("skill_triggered", False),
        },
        "timing": timing,
        "run_validity": _build_run_validity(run_dir, timing),
        "provenance": {
            "deterministic_complete": deterministic_complete,
            "semantic_fallback_used": False,
            "semantic_assertions": semantic_assertions,
        },
    }

    (run_dir / "grading.json").write_text(json.dumps(grading, indent=2) + "\n")
    print(json.dumps(grading["summary"], indent=2))


if __name__ == "__main__":
    main()
