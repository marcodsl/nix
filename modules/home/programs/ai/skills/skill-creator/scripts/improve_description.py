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
"""Improve a skill description based on eval results.

Takes eval results (from run_eval.py) and generates an improved description
by calling `copilot -p` in an isolated temporary Copilot config.
"""

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from scripts.utils import parse_skill_md


def _call_copilot(prompt: str, model: str | None, timeout: int = 300) -> str:
    """Run `copilot -p` with the prompt and return the text response."""
    with tempfile.TemporaryDirectory(prefix="skill-description-config-") as temp_dir:
        cmd = [
            "copilot",
            "-p",
            prompt,
            "--config-dir",
            temp_dir,
            "--allow-all",
            "--output-format",
            "text",
            "--silent",
            "--no-custom-instructions",
        ]
        if model:
            cmd.extend(["--model", model])

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=temp_dir,
            timeout=timeout,
        )

    if result.returncode != 0:
        raise RuntimeError(
            f"copilot -p exited {result.returncode}\n"
            f"stdout: {result.stdout}\nstderr: {result.stderr}"
        )
    return result.stdout


def improve_description(
    skill_name: str,
    skill_content: str,
    current_description: str,
    eval_results: dict,
    history: list[dict],
    model: str,
    test_results: dict | None = None,
    log_dir: Path | None = None,
    iteration: int | None = None,
) -> str:
    """Call Copilot CLI to improve the description based on eval results."""
    failed_triggers = [
        r for r in eval_results["results"] if r["should_trigger"] and not r["pass"]
    ]
    false_triggers = [
        r for r in eval_results["results"] if not r["should_trigger"] and not r["pass"]
    ]

    train_score = (
        f"{eval_results['summary']['passed']}/{eval_results['summary']['total']}"
    )
    if test_results:
        test_score = (
            f"{test_results['summary']['passed']}/{test_results['summary']['total']}"
        )
        scores_summary = f"Train: {train_score}, Test: {test_score}"
    else:
        scores_summary = f"Train: {train_score}"

    prompt = f"""You are optimizing a skill description for a GitHub Copilot CLI
skill called "{skill_name}". A skill is a folder that contains a SKILL.md file
and optional helper resources. Copilot decides whether to load the skill based
primarily on the skill name and description, then reads the SKILL.md body only
after it chooses to use the skill.

The description appears in Copilot's loaded skills list. When a user sends a
query, Copilot decides whether to invoke the skill based on the title and this
description. Your goal is to write a description that triggers for relevant
queries and stays out of the way for irrelevant ones.

Here's the current description:
<current_description>
"{current_description}"
</current_description>

Current scores ({scores_summary}):
<scores_summary>
"""
    if failed_triggers:
        prompt += "FAILED TO TRIGGER (should have triggered but didn't):\n"
        for r in failed_triggers:
            prompt += (
                f'  - "{r["query"]}" (triggered {r["triggers"]}/{r["runs"]} times)\n'
            )
        prompt += "\n"

    if false_triggers:
        prompt += "FALSE TRIGGERS (triggered but shouldn't have):\n"
        for r in false_triggers:
            prompt += (
                f'  - "{r["query"]}" (triggered {r["triggers"]}/{r["runs"]} times)\n'
            )
        prompt += "\n"

    if history:
        prompt += (
            "PREVIOUS ATTEMPTS "
            "(do NOT repeat these — try something structurally different):\n\n"
        )
        for h in history:
            train_s = (
                f"{h.get('train_passed', h.get('passed', 0))}/"
                f"{h.get('train_total', h.get('total', 0))}"
            )
            test_s = (
                f"{h.get('test_passed', '?')}/{h.get('test_total', '?')}"
                if h.get("test_passed") is not None
                else None
            )
            score_str = f"train={train_s}" + (f", test={test_s}" if test_s else "")
            prompt += f"<attempt {score_str}>\n"
            prompt += f'Description: "{h["description"]}"\n'
            if "results" in h:
                prompt += "Train results:\n"
                for r in h["results"]:
                    status = "PASS" if r["pass"] else "FAIL"
                    prompt += (
                        f'  [{status}] "{r["query"][:80]}" '
                        f"(triggered {r['triggers']}/{r['runs']})\n"
                    )
            if h.get("note"):
                prompt += f"Note: {h['note']}\n"
            prompt += "</attempt>\n\n"

    prompt += f"""</scores_summary>

Skill content (for context on what the skill does):
<skill_content>
{skill_content}
</skill_content>

Based on the failures, write a new and improved description that is more likely
to trigger correctly. Do not overfit to the exact queries. Generalize from the
failures to broader categories of user intent and situations where this skill
would be useful or not useful.

The main constraints:
1. Avoid overfitting to a fixed list of prompts
2. Keep the description short enough to be a good discovery surface
3. Emphasize user intent, not internal implementation details

Concretely, your description should not be more than about 100-200 words. There
is a hard limit of 1024 characters — descriptions over that will be truncated,
so stay comfortably under it.

Here are some tips that tend to work well:
- Phrase the description in the imperative, for example "Use this skill for"
- Focus on the user's goal and when Copilot should reach for the skill
- Make it distinctive enough to compete with neighboring skills
- If repeated attempts keep failing, change the structure rather than adding a
  longer keyword list

Please respond with only the new description text in <new_description> tags,
nothing else."""

    text = _call_copilot(prompt, model)

    match = re.search(r"<new_description>(.*?)</new_description>", text, re.DOTALL)
    description = (
        match.group(1).strip().strip('"') if match else text.strip().strip('"')
    )

    transcript: dict = {
        "iteration": iteration,
        "prompt": prompt,
        "response": text,
        "parsed_description": description,
        "char_count": len(description),
        "over_limit": len(description) > 1024,
    }

    if len(description) > 1024:
        shorten_prompt = (
            f"{prompt}\n\n"
            f"---\n\n"
            f"A previous attempt produced this description, which at "
            f"{len(description)} characters is over the 1024-character hard limit:\n\n"
            f'"{description}"\n\n'
            f"Rewrite it to be under 1024 characters while keeping the most "
            f"important trigger words and intent coverage. Respond with only "
            f"the new description in <new_description> tags."
        )
        shorten_text = _call_copilot(shorten_prompt, model)
        match = re.search(
            r"<new_description>(.*?)</new_description>", shorten_text, re.DOTALL
        )
        shortened = (
            match.group(1).strip().strip('"')
            if match
            else shorten_text.strip().strip('"')
        )

        transcript["rewrite_prompt"] = shorten_prompt
        transcript["rewrite_response"] = shorten_text
        transcript["rewrite_description"] = shortened
        transcript["rewrite_char_count"] = len(shortened)
        description = shortened

    transcript["final_description"] = description

    if log_dir:
        log_dir.mkdir(parents=True, exist_ok=True)
        log_file = log_dir / f"improve_iter_{iteration or 'unknown'}.json"
        log_file.write_text(json.dumps(transcript, indent=2))

    return description


def main():
    parser = argparse.ArgumentParser(
        description="Improve a skill description based on eval results"
    )
    parser.add_argument(
        "--eval-results",
        required=True,
        help="Path to eval results JSON (from run_eval.py)",
    )
    parser.add_argument("--skill-path", required=True, help="Path to skill directory")
    parser.add_argument(
        "--history", default=None, help="Path to history JSON (previous attempts)"
    )
    parser.add_argument("--model", required=True, help="Model for improvement")
    parser.add_argument(
        "--verbose", action="store_true", help="Print thinking to stderr"
    )
    args = parser.parse_args()

    skill_path = Path(args.skill_path)
    if not (skill_path / "SKILL.md").exists():
        print(f"Error: No SKILL.md found at {skill_path}", file=sys.stderr)
        sys.exit(1)

    eval_results = json.loads(Path(args.eval_results).read_text())
    history = []
    if args.history:
        history = json.loads(Path(args.history).read_text())

    name, _, content = parse_skill_md(skill_path)
    current_description = eval_results["description"]

    if args.verbose:
        print(f"Current: {current_description}", file=sys.stderr)
        print(
            f"Score: {eval_results['summary']['passed']}/"
            f"{eval_results['summary']['total']}",
            file=sys.stderr,
        )

    new_description = improve_description(
        skill_name=name,
        skill_content=content,
        current_description=current_description,
        eval_results=eval_results,
        history=history,
        model=args.model,
    )

    if args.verbose:
        print(f"Improved: {new_description}", file=sys.stderr)

    output = {
        "description": new_description,
        "history": [
            *history,
            {
                "description": current_description,
                "passed": eval_results["summary"]["passed"],
                "failed": eval_results["summary"]["failed"],
                "total": eval_results["summary"]["total"],
                "results": eval_results["results"],
            },
        ],
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
