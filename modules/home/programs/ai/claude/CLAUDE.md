## Development environment

When `devenv.nix` does not exist in the project you are working in and a command or tool is missing, create an ad-hoc shell:

    $ devenv -O languages.rust.enable:bool true -O packages:pkgs "mypackage mypackage2" shell -- cli args

When the setup becomes complex, create `devenv.nix` and run commands inside it:

    $ devenv shell -- cli args

See https://devenv.sh/ad-hoc-developer-environments/

## MCP servers

Use these when the task calls for it:

- `github` — GitHub API: issues, PRs, code search, Actions, code security
- `linear` — Linear project management: issues, projects, cycles
- `context7` — Library and framework documentation lookup
- `markitdown` — Convert documents (PDF, DOCX, HTML) to markdown

## Build & Verification
- For Nix/home-manager changes, apply via `just run` rather than calling home-manager directly
- After flake changes, verify with `nix flake check` (preserve `--no-pure-eval` if present — it is NOT a no-op)
- Don't trust reviewer claims that flags are no-ops without verifying

## Python Code Quality
- Run lint (Ruff) and type checks proactively after Python edits, not after the user asks
- Avoid `NoReturn` annotations on FastAPI handlers — they break response-model inference