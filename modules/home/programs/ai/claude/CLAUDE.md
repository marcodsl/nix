<section name="Defaults">
- If a request has multiple plausible interpretations, surface them; don't pick silently.
- Prefer the minimum diff that solves the stated problem. No speculative abstractions, error handling for impossible cases, or "while I'm here" cleanups.
- Every changed line should trace to the user's request. Mention adjacent issues; don't fix them unsolicited.
- Before claiming "done", state how the work was verified (test run, file inspection, command output). If you can't verify it, say so.
</section>

<section name="Execution Style">
- Don't auto-start dev servers or long-running services — print the command for the user to run
- When given an orchestrator/research-only role, stay in that role across continuations; if direct edits seem needed, surface the proposal and wait
</section>

<section name="Skill routing">
- Use the `coding-guidelines` skill when planning, designing, or reviewing non-trivial software changes (architecture, validation, performance, multi-option tradeoffs). Skip for typo/rename/format edits.
- Use the `prompt-engineering` skill when editing prompts, agent rule files, persona files, or any of: `SKILL.md`, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.instructions.md`, `.agent.md`, `.prompt.md`, `.mdc`.
</section>

<section name="Development environment">
When `devenv.nix` does not exist in the project you are working in and a command or tool is missing, create an ad-hoc shell:

    $ devenv -O languages.rust.enable:bool true -O packages:pkgs "mypackage mypackage2" shell -- cli args

When the setup becomes complex, create `devenv.nix` and run commands inside it:

    $ devenv shell -- cli args

See https://devenv.sh/ad-hoc-developer-environments/

</section>

<section name="Git & Commits">
- Before committing, check `git status` and `git diff --staged`; never bundle pre-staged unrelated files
- Use Conventional Commits; one logical change per commit
- Use the `conventional-commits` skill to draft commit messages.
</section>

<section name="Security Reviews">
- When a reviewer/agent proposes a patch, verify the referenced lines exist before applying — guard against hallucinated diffs
</section>

<section name="Code Quality">
- Use the `coding` skill when editing `.py`, `.ts`, `.tsx`, or `.rs` files, or bootstrapping a project; it pulls in language-specific lint, type-check, and test rules.
- Before running Python, confirm it's available on PATH. If not, invoke via `nix run nixpkgs#python3 -- ...` instead of failing.
- Run lint (`ruff`) and type checks (`ty`) proactively after Python edits, not after the user asks
- Avoid `NoReturn` annotations on FastAPI handlers — they break response-model inference
</section>

<section name="Prose Style">
- Never use em dashes (—) in any written output. Replace with a period, a comma, or a restructured sentence.
- Use the `natural-tone` skill when editing READMEs, PR descriptions, commit-message bodies, release notes, or code comments.
</section>
