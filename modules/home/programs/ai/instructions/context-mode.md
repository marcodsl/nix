# Context-mode operating rules

Use this file for the detailed context-mode workflow. The top-level `copilot-instructions.md` contains the routing-critical rules that take precedence.

## Think in code

When you need to analyze, count, filter, compare, search, parse, transform, or process data, write code that does the work with `ctx_execute(language, code)` and print only the answer with `console.log()`.

- Do not read large raw outputs into context to process mentally.
- Prefer robust, pure JavaScript with no npm dependencies.
- Use only Node.js built-ins such as `fs`, `path`, and `child_process`.
- Always use `try/catch`, handle `null` and `undefined`, and keep code compatible with both Node.js and Bun.

## Blocked commands

Do not attempt these paths and do not retry them in the terminal:

- `curl` or `wget`: use `ctx_fetch_and_index(url, source)` for web content or `ctx_execute(language: "javascript", code: "const r = await fetch(...)")` for sandboxed HTTP.
- Inline HTTP from terminal code such as `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(`: use `ctx_execute(language, code)` instead.
- Direct web fetching tools: use `ctx_fetch_and_index(url, source)` and then `ctx_search(queries)`.

## Redirected tools

Use sandbox equivalents when exploration or analysis could produce large output.

- Use terminal or `run_in_terminal` only for `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
- For other command execution, prefer `ctx_batch_execute(commands, queries)` or `ctx_execute(language: "shell", code: "...")`.
- Read files directly only when you need file contents in context to edit them. For analysis, exploration, or summarization, prefer `ctx_execute_file(path, language, code)` so only your summary enters context.
- For searches that could return many matches, prefer sandbox execution and print only the summary you need.

## Tool selection hierarchy

1. **Gather** with `ctx_batch_execute(commands, queries)` as the primary tool. Use descriptive command labels because they become searchable chunk titles.
2. **Follow up** with `ctx_search(queries: ["q1", "q2", ...])`, passing all related questions in one call.
3. **Process** with `ctx_execute(language, code)` or `ctx_execute_file(path, language, code)` so only stdout enters context.
4. **Fetch web content** with `ctx_fetch_and_index(url, source)` and then query it with `ctx_search(queries)`.
5. **Index reusable content** with `ctx_index(content, source)` using descriptive source labels.

## Output constraints

- Keep responses under 500 words.
- Write substantial artifacts such as code, configs, and PRDs to files instead of returning them inline.
- When you create an artifact file, return only the file path and a one-line description.
- When indexing content, use descriptive source labels so later searches can target that source precisely.

## ctx commands

| Command       | Action                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------- |
| `ctx stats`   | Call the `ctx_stats` MCP tool and display the full output verbatim.                                     |
| `ctx doctor`  | Call the `ctx_doctor` MCP tool, run the returned shell command, and display the result as a checklist.  |
| `ctx upgrade` | Call the `ctx_upgrade` MCP tool, run the returned shell command, and display the result as a checklist. |
| `ctx purge`   | Call the `ctx_purge` MCP tool with `confirm: true`. Warn before wiping the knowledge base.              |

After `/clear` or `/compact`, knowledge base contents and session stats remain available. Use `ctx purge` when you need a fresh start.
