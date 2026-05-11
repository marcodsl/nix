<overview>
Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.
</overview>

<tradeoff>
These guidelines bias toward caution over speed. For trivial tasks (typo fixes, renames, single-line tweaks), favor directness.
</tradeoff>

<principle id="1" title="Think Before Coding">
<summary>Don't assume. Don't hide confusion. Surface tradeoffs.</summary>

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when the requested approach adds complexity, risk, or scope without a clear reason.
- If something is unclear, stop. Name what's confusing. Ask.
</principle>

<principle id="2" title="Simplicity First">
<summary>Minimum code that solves the problem. Nothing speculative.</summary>

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.
</principle>

<principle id="3" title="Surgical Changes">
<summary>Touch only what you must. Clean up only your own mess.</summary>

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes leave code unused (orphaned imports, variables, functions):
- Remove what YOUR change made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.
</principle>

<principle id="4" title="Goal-Driven Execution">
<summary>Define success criteria. Loop until verified.</summary>

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Why this matters: strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.
</principle>

<section name="Development environment">
When `devenv.nix` does not exist in the project you are working in and a command or tool is missing, create an ad-hoc shell:

    $ devenv -O languages.rust.enable:bool true -O packages:pkgs "mypackage mypackage2" shell -- cli args

When the setup becomes complex, create `devenv.nix` and run commands inside it:

    $ devenv shell -- cli args

See https://devenv.sh/ad-hoc-developer-environments/
</section>

<section name="MCP servers">
Use these when the task calls for it:

- `github` — GitHub API: issues, PRs, code search, Actions, code security
- `linear` — Linear project management: issues, projects, cycles
- `context7` — Library and framework documentation lookup
- `markitdown` — Convert documents (PDF, DOCX, HTML) to markdown
</section>

<section name="Build & Verification">
- For Nix/home-manager changes, apply via `just run` rather than calling home-manager directly
- After flake changes, verify with `nix flake check` (preserve `--no-pure-eval` if present — it is NOT a no-op)
- Don't trust reviewer claims that flags are no-ops without verifying
</section>

<section name="Python Code Quality">
- Run lint (Ruff) and type checks proactively after Python edits, not after the user asks
- Avoid `NoReturn` annotations on FastAPI handlers — they break response-model inference
</section>
