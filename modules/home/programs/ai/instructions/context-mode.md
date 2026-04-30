# Context-mode operating rules

Use this file for detailed context-mode workflow. The top-level `copilot-instructions.md` owns routing-critical rules.

## Think in code

When you need to analyze, count, filter, compare, parse, transform, or process data, use `ctx_execute(language, code)` and print only the answer.

- Do not read large raw outputs into context for mental processing.
- Prefer robust JavaScript with Node.js built-ins (`fs`, `path`, `child_process`) and no npm dependencies.
- Use `try/catch`, handle `null`/`undefined`, and keep code compatible with Node.js and Bun.

## Blocked commands

Do not attempt or retry these in the terminal:

- `curl` or `wget`: use `ctx_fetch_and_index(url, source)` for web content, or sandboxed fetch inside `ctx_execute`.
- Inline terminal HTTP (`fetch('http`, `requests.get/post`, `http.get/request`): use `ctx_execute` instead.
- Direct web fetching tools: use `ctx_fetch_and_index` then `ctx_search`.

## Redirected tools

- Use terminal or `run_in_terminal` for short-output shell work: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, installs, and similarly bounded commands.
- For larger exploration or analysis, use `ctx_batch_execute`, `ctx_execute(language: "shell", code: "...")`, or `ctx_execute_file`.
- Read files directly only when their contents must be in context for editing. For analysis or summarization, use `ctx_execute_file` and print a summary.
- For searches that could produce many matches, run a sandboxed search and print only the needed summary.

## Tool hierarchy

1. Gather with `ctx_batch_execute(commands, queries)` and descriptive command labels.
2. Follow up with batched `ctx_search(queries)`.
3. Process with `ctx_execute` or `ctx_execute_file` so only stdout enters context.
4. Fetch web content with `ctx_fetch_and_index` and query with `ctx_search`.
5. Index reusable content with `ctx_index(content, source)` and descriptive labels.

## Output constraints

- Keep responses under 500 words.
- Write substantial artifacts such as code, configs, and PRDs to files instead of returning them inline.
- When creating an artifact file, return only the file path and one-line description.
- Use descriptive source labels when indexing content.

## ctx commands

- `ctx stats`: call `ctx_stats` and show full output verbatim.
- `ctx doctor`: call `ctx_doctor`, run the returned shell command, show result as a checklist.
- `ctx upgrade`: call `ctx_upgrade`, run the returned shell command, show result as a checklist.
- `ctx purge`: call `ctx_purge` with `confirm: true`; warn before wiping the knowledge base.

After `/clear` or `/compact`, knowledge base contents and stats remain available. Use `ctx purge` only for a fresh start.
