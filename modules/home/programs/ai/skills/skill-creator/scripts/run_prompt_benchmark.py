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
"""Run prompt benchmarks for a Copilot CLI skill."""

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
import time
from collections import Counter
from datetime import UTC, datetime
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.utils import parse_skill_md


def _iso(ts: float) -> str:
    """Format a POSIX timestamp as ISO 8601 UTC."""
    return datetime.fromtimestamp(ts, UTC).isoformat().replace("+00:00", "Z")


def _collect_shell_commands(arguments: object) -> list[str]:
    """Extract likely shell commands from tool arguments."""
    commands: list[str] = []

    def visit(value: object) -> None:
        if isinstance(value, dict):
            for key, nested in value.items():
                if key in {"command", "cmd", "shellCommand"} and isinstance(
                    nested, str
                ):
                    commands.append(nested)
                else:
                    visit(nested)
        elif isinstance(value, list):
            for nested in value:
                visit(nested)

    visit(arguments)
    return commands


def _classify_paths(texts: list[str]) -> dict[str, list[str]]:
    """Extract coarse path classes from response text and captured commands."""
    absolute_pattern = re.compile(r"(?<![A-Za-z0-9_])(/[A-Za-z0-9._~/-]+)")
    relative_pattern = re.compile(
        r"(?<![A-Za-z0-9_])([A-Za-z0-9._-]+(?:/[A-Za-z0-9._-]+)+)"
    )
    cwd_sensitive_pattern = re.compile(
        r"(\$PWD/[A-Za-z0-9._~/-]+|\./[A-Za-z0-9._~/-]+|\.\./[A-Za-z0-9._~/-]+)"
    )

    absolute: set[str] = set()
    relative: set[str] = set()
    cwd_sensitive: set[str] = set()
    transient: set[str] = set()

    for text in texts:
        for match in absolute_pattern.findall(text):
            absolute.add(match)
            if match.startswith(("/tmp/", "/private/tmp/")):
                transient.add(match)
        for match in relative_pattern.findall(text):
            if not match.startswith(("http/", "https/")):
                relative.add(match)
        for match in cwd_sensitive_pattern.findall(text):
            cwd_sensitive.add(match)

    return {
        "absolute": sorted(absolute),
        "relative": sorted(relative),
        "cwd_sensitive": sorted(cwd_sensitive),
        "transient": sorted(transient),
    }


def _format_eval_files(eval_files: list[str]) -> str:
    """Format materialized eval files for the transcript."""
    if not eval_files:
        return "- none"
    return "\n".join(f"- {path}" for path in eval_files)


def _extract_response_metrics_and_trace(
    raw_output: str, skill_name: str
) -> tuple[str, dict, dict]:
    """Parse Copilot JSONL output into response text, metrics, and trace data."""
    started_tools: dict[str, tuple[str | None, dict]] = {}
    tool_calls: Counter[str] = Counter()
    message_order: list[str] = []
    message_content: dict[str, dict[str, list[str]]] = {}
    skill_triggered = False
    errors_encountered = 0
    shell_commands: list[str] = []
    trace_events: list[dict[str, object]] = []

    for line in raw_output.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue

        event_type = event.get("type")
        data = event.get("data", {})

        if event_type == "tool.execution_start":
            tool_name = data.get("toolName") or "unknown"
            arguments = data.get("arguments", {})
            if not isinstance(arguments, dict):
                arguments = {}
            tool_calls[tool_name] += 1
            started_tools[data.get("toolCallId", "")] = (tool_name, arguments)
            shell_commands.extend(_collect_shell_commands(arguments))
            continue

        if event_type == "tool.execution_complete":
            tool_name, tool_args = started_tools.get(
                data.get("toolCallId", ""), (None, {})
            )
            trace_events.append(
                {
                    "kind": "tool_call",
                    "tool": tool_name or "unknown",
                    "success": bool(data.get("success")),
                }
            )
            if not data.get("success"):
                errors_encountered += 1
            if (
                tool_name == "skill"
                and tool_args.get("skill") == skill_name
                and data.get("success")
            ):
                skill_triggered = True
            continue

        if event_type == "assistant.message_delta":
            message_id = data.get("messageId")
            delta = data.get("deltaContent", "")
            if not message_id:
                continue
            if message_id not in message_content:
                message_order.append(message_id)
                message_content[message_id] = {"initial": [], "deltas": []}
            if delta:
                message_content[message_id]["deltas"].append(delta)
            continue

        if event_type != "assistant.message":
            continue

        message_id = data.get("messageId")
        if not message_id:
            continue
        if message_id not in message_content:
            message_order.append(message_id)
            message_content[message_id] = {"initial": [], "deltas": []}

        content = data.get("content")
        if isinstance(content, str):
            if content:
                message_content[message_id]["initial"].append(content)
            continue

        if isinstance(content, list):
            for part in content:
                if isinstance(part, dict) and part.get("type") == "text":
                    text = part.get("text", "")
                    if text:
                        message_content[message_id]["initial"].append(text)

    response_parts: list[str] = []
    for message_id in message_order:
        parts = message_content[message_id]
        text = (
            "".join(parts["deltas"]).strip()
            if parts["deltas"]
            else "".join(parts["initial"]).strip()
        )
        if text:
            response_parts.append(text)

    response_text = "\n\n".join(response_parts).strip() or "(No text response captured)"
    tool_call_counts = dict(sorted(tool_calls.items()))
    metrics = {
        "tool_call_counts": tool_call_counts,
        "tool_calls": tool_call_counts,
        "total_tool_calls": sum(tool_calls.values()),
        "errors_encountered": errors_encountered,
        "skill_triggered": skill_triggered,
    }
    trace = {
        "skill_name": skill_name,
        "tool_call_counts": tool_call_counts,
        "tool_names": sorted(tool_call_counts),
        "shell_commands": shell_commands,
        "path_mentions": _classify_paths([response_text, *shell_commands]),
        "events": trace_events,
        "skill_triggered": skill_triggered,
        "errors_encountered": errors_encountered,
    }
    return response_text, metrics, trace


def _copy_skill(skill_path: Path, target_dir: Path) -> None:
    """Copy a skill directory into a project-visible skills location."""
    shutil.copytree(
        skill_path,
        target_dir,
        dirs_exist_ok=True,
        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".DS_Store"),
    )


def _materialize_eval_files(
    *, skill_path: Path, eval_item: dict, project_root: Path
) -> list[str]:
    """Copy eval input files into the temp project and return their project paths."""
    materialized_paths: list[str] = []
    for raw_path in eval_item.get("files", []):
        entry = Path(raw_path)
        if entry.is_absolute():
            source = entry
            target_rel = Path("inputs") / entry.name
        else:
            source = skill_path / entry
            target_rel = entry

        if not source.exists():
            raise FileNotFoundError(
                f"Eval file not found for eval {eval_item.get('id')}: {raw_path}"
            )

        target = project_root / target_rel
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            shutil.copytree(
                source,
                target,
                dirs_exist_ok=True,
                ignore=shutil.ignore_patterns("__pycache__", "*.pyc", ".DS_Store"),
            )
        else:
            shutil.copy2(source, target)
        materialized_paths.append(str(target_rel))

    return materialized_paths


def _run_config(
    *,
    skill_path: Path,
    materialized_skill_path: Path | None,
    skill_name: str,
    configuration: str,
    eval_item: dict,
    run_dir: Path,
    force_skill: bool,
    model: str | None,
    timeout: int,
) -> dict:
    """Run one benchmark configuration and persist its artifacts."""
    outputs_dir = run_dir / "outputs"
    outputs_dir.mkdir(parents=True, exist_ok=True)

    base_prompt = eval_item["prompt"].strip()

    with (
        tempfile.TemporaryDirectory(prefix="skill-bench-project-") as project_dir,
        tempfile.TemporaryDirectory(prefix="skill-bench-config-") as config_dir,
    ):
        project_root = Path(project_dir)
        if materialized_skill_path is not None:
            target = project_root / ".github" / "skills" / skill_name
            target.parent.mkdir(parents=True, exist_ok=True)
            _copy_skill(materialized_skill_path, target)
        eval_files = _materialize_eval_files(
            skill_path=skill_path, eval_item=eval_item, project_root=project_root
        )

        file_prompt = (
            f"Input files available in the project: {', '.join(eval_files)}.\n"
            if eval_files
            else "Input files: none.\n"
        )
        if force_skill:
            task_prompt = (
                f"Use the /{skill_name} skill. "
                f"{base_prompt}\n"
                f"{file_prompt}"
                "Respond with concrete steps and exact commands where appropriate."
            )
        else:
            task_prompt = (
                f"{base_prompt}\n"
                f"{file_prompt}"
                "Respond with concrete steps and exact commands where appropriate. "
                "Do not explicitly invoke or name any skill."
            )

        cmd = [
            "copilot",
            "-p",
            task_prompt,
            "--config-dir",
            config_dir,
            "--allow-all",
            "--output-format",
            "json",
            "--silent",
            "--no-custom-instructions",
        ]
        if model:
            cmd.extend(["--model", model])

        started_at = time.time()
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=project_root,
            timeout=timeout,
        )
        finished_at = time.time()

    response_text, metrics, trace = _extract_response_metrics_and_trace(
        result.stdout, skill_name
    )
    baseline_contaminated = (not force_skill) and metrics["skill_triggered"]
    transcript = (
        f"# {run_dir.name}\n\n"
        f"## Eval Prompt\n\n{base_prompt}\n\n"
        f"## Input Files\n\n"
        f"{_format_eval_files(eval_files)}\n\n"
        f"## Task Prompt\n\n{task_prompt}\n\n"
        f"## Response\n\n{response_text}\n"
    )

    (run_dir / "raw.jsonl").write_text(result.stdout)
    (run_dir / "stderr.txt").write_text(result.stderr)
    (run_dir / "transcript.md").write_text(transcript)
    (outputs_dir / "response.md").write_text(
        response_text if response_text.endswith("\n") else f"{response_text}\n"
    )
    trace_payload = {
        **trace,
        "configuration": configuration,
        "baseline_contaminated": baseline_contaminated,
    }
    (outputs_dir / "trace.json").write_text(json.dumps(trace_payload, indent=2) + "\n")

    metrics_payload = {
        **metrics,
        "total_steps": 1,
        "files_created": ["response.md", "trace.json"],
        "response_chars": len(response_text),
        "output_chars": len(response_text),
        "transcript_chars": len(transcript),
        "baseline_contaminated": baseline_contaminated,
    }
    (outputs_dir / "metrics.json").write_text(
        json.dumps(metrics_payload, indent=2) + "\n"
    )

    timing_payload = {
        "duration_ms": round((finished_at - started_at) * 1000),
        "total_duration_seconds": round(finished_at - started_at, 3),
        "executor_start": _iso(started_at),
        "executor_end": _iso(finished_at),
        "executor_duration_seconds": round(finished_at - started_at, 3),
        "exit_code": result.returncode,
        "skill_triggered": metrics["skill_triggered"],
        "baseline_contaminated": baseline_contaminated,
    }
    (run_dir / "timing.json").write_text(json.dumps(timing_payload, indent=2) + "\n")

    return {
        "run_dir": str(run_dir),
        "exit_code": result.returncode,
        "skill_triggered": metrics["skill_triggered"],
        "duration_seconds": round(finished_at - started_at, 3),
        "baseline_contaminated": baseline_contaminated,
    }


def _resolve_baseline_plan(
    *, eval_item: dict, baseline_skill_path: Path | None
) -> dict[str, str | None]:
    """Resolve the requested per-eval baseline strategy."""
    requested = eval_item.get("baseline_strategy")
    if requested is None:
        requested = "snapshot" if baseline_skill_path is not None else "prompt_only"

    if requested not in {"prompt_only", "snapshot"}:
        raise SystemExit(
            "Unsupported baseline_strategy for eval "
            f"{eval_item.get('id')}: {requested!r}. "
            "Use 'prompt_only' or 'snapshot'."
        )

    if requested == "snapshot" and baseline_skill_path is not None:
        return {
            "requested": requested,
            "applied": "snapshot",
            "fallback": None,
        }

    if requested == "snapshot":
        return {
            "requested": requested,
            "applied": "prompt_only",
            "fallback": "missing_baseline_skill_path",
        }

    return {
        "requested": requested,
        "applied": "prompt_only",
        "fallback": None,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Run prompt benchmarks for a skill")
    parser.add_argument(
        "--skill-path", required=True, help="Path to the skill directory"
    )
    parser.add_argument(
        "--workspace",
        required=True,
        help="Iteration directory to write benchmark artifacts into",
    )
    parser.add_argument(
        "--evals",
        default=None,
        help="Path to evals.json (defaults to <skill-path>/evals/evals.json)",
    )
    parser.add_argument(
        "--eval-ids",
        type=int,
        nargs="*",
        default=None,
        help="Optional subset of eval IDs to run",
    )
    parser.add_argument(
        "--timeout", type=int, default=300, help="Timeout per run in seconds"
    )
    parser.add_argument(
        "--model",
        default=None,
        help="Model to use for copilot -p (default: user's configured model)",
    )
    parser.add_argument(
        "--baseline-skill-path",
        default=None,
        help=(
            "Optional path to an older snapshot of the same skill; "
            "uses old_skill instead of baseline"
        ),
    )
    args = parser.parse_args()

    skill_path = Path(args.skill_path).resolve()
    workspace = Path(args.workspace).resolve()
    evals_path = (
        Path(args.evals).resolve()
        if args.evals
        else (skill_path / "evals" / "evals.json").resolve()
    )
    baseline_skill_path = (
        Path(args.baseline_skill_path).resolve() if args.baseline_skill_path else None
    )

    if not (skill_path / "SKILL.md").exists():
        raise SystemExit(f"No SKILL.md found at {skill_path}")
    if not evals_path.exists():
        raise SystemExit(f"No eval set found at {evals_path}")

    skill_name, _, _ = parse_skill_md(skill_path)
    if baseline_skill_path is not None:
        if not (baseline_skill_path / "SKILL.md").exists():
            raise SystemExit(f"No SKILL.md found at {baseline_skill_path}")
        baseline_name, _, _ = parse_skill_md(baseline_skill_path)
        if baseline_name != skill_name:
            raise SystemExit(
                "Baseline snapshot must have the same skill name as the skill "
                "under test "
                f"({baseline_name!r} != {skill_name!r})"
            )

    evals_data = json.loads(evals_path.read_text())
    eval_items = evals_data.get("evals", [])
    if args.eval_ids:
        wanted = set(args.eval_ids)
        eval_items = [item for item in eval_items if item.get("id") in wanted]

    workspace.mkdir(parents=True, exist_ok=True)

    summary: list[dict] = []
    for item in eval_items:
        baseline_plan = _resolve_baseline_plan(
            eval_item=item, baseline_skill_path=baseline_skill_path
        )
        if baseline_plan["fallback"] is not None:
            print(
                "eval="
                f"{item['id']} requested baseline_strategy=snapshot but no "
                "--baseline-skill-path was provided; falling back to a prompt-only "
                "baseline",
                file=sys.stderr,
            )

        configs = [("with_skill", skill_path, True)]
        if baseline_plan["applied"] == "snapshot":
            assert baseline_skill_path is not None
            configs.append(("old_skill", baseline_skill_path, True))
        else:
            configs.append(("baseline", None, False))

        eval_dir = workspace / f"eval-{item['id']}"
        eval_dir.mkdir(parents=True, exist_ok=True)
        metadata = {
            "eval_id": item["id"],
            "eval_name": item.get("eval_name")
            or item.get("name")
            or f"{skill_name}-eval-{item['id']}",
            "prompt": item["prompt"],
            "grading_mode": item.get("grading_mode", "deterministic"),
            "assertions": item.get("assertions", item.get("expectations", [])),
            "expected_output": item.get("expected_output", ""),
            "files": item.get("files", []),
            "skill_name": skill_name,
            "skill_path": str(skill_path),
            "baseline_strategy_requested": baseline_plan["requested"],
            "baseline_strategy_applied": baseline_plan["applied"],
        }
        if baseline_plan["fallback"] is not None:
            metadata["baseline_strategy_fallback"] = baseline_plan["fallback"]
        (eval_dir / "eval_metadata.json").write_text(
            json.dumps(metadata, indent=2) + "\n"
        )

        for config_name, config_skill_path, force_skill in configs:
            run_dir = eval_dir / config_name
            run_dir.mkdir(parents=True, exist_ok=True)
            run_metadata = {
                **metadata,
                "configuration": config_name,
                "run_number": 1,
                "configuration_skill_path": (
                    str(config_skill_path) if config_skill_path is not None else None
                ),
                "baseline_kind": (
                    "skill_snapshot"
                    if config_name == "old_skill"
                    else "no_skill"
                    if config_name == "baseline"
                    else "target_skill"
                ),
                "baseline_strategy_requested": baseline_plan["requested"],
                "baseline_strategy_applied": baseline_plan["applied"],
            }
            if baseline_plan["fallback"] is not None:
                run_metadata["baseline_strategy_fallback"] = baseline_plan["fallback"]
            (run_dir / "eval_metadata.json").write_text(
                json.dumps(run_metadata, indent=2) + "\n"
            )
            run_summary = _run_config(
                skill_path=skill_path,
                materialized_skill_path=config_skill_path,
                skill_name=skill_name,
                configuration=config_name,
                eval_item=item,
                run_dir=run_dir,
                force_skill=force_skill,
                model=args.model,
                timeout=args.timeout,
            )
            run_summary["eval_id"] = item["id"]
            run_summary["configuration"] = config_name
            summary.append(run_summary)
            print(
                f"eval={item['id']} config={config_name} "
                f"exit={run_summary['exit_code']} "
                f"skill_triggered={run_summary['skill_triggered']} "
                f"duration={run_summary['duration_seconds']:.2f}s"
            )

    contaminated = [
        row
        for row in summary
        if row["configuration"] == "baseline" and row["baseline_contaminated"]
    ]
    print(
        json.dumps(
            {"workspace": str(workspace), "contaminated_baselines": contaminated},
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
