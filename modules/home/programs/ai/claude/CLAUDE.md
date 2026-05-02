## Development environment

When `devenv.nix` does not exist in the project you are working in and a command or tool is missing, create an ad-hoc shell:

    $ devenv -O languages.rust.enable:bool true -O packages:pkgs "mypackage mypackage2" shell -- cli args

When the setup becomes complex, create `devenv.nix` and run commands inside it:

    $ devenv shell -- cli args

See https://devenv.sh/ad-hoc-developer-environments/

## MCP servers

Use these when the task calls for it:

- `github-mcp` — GitHub API: issues, PRs, code search, Actions, code security
- `linear-mcp` — Linear project management: issues, projects, cycles
- `context7-mcp` — Library and framework documentation lookup
- `markitdown` — Convert documents (PDF, DOCX, HTML) to markdown
