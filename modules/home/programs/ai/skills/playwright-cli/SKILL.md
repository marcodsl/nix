---
name: playwright-cli
description: "Drive a real browser from the shell with `playwright-cli`: snapshot pages, interact via element refs, manage tabs and sessions, capture screenshots and traces. Triggers: `playwright-cli` or `npx playwright-cli` commands, snapshot YAML, `playwright-cli open`/`goto`/`click`/`fill`/`snapshot`, browser session management, multi-tab flows, request mocking via `--route`, spec-driven test generation (plan/generate/heal), `--annotate` UI review. Skip when: the task is API or backend only."
allowed-tools: Bash(playwright-cli:*) Bash(npx:*) Bash(npm:*)
license: Apache-2.0
metadata:
  author: microsoft
  source: https://github.com/microsoft/playwright-cli
  tags: playwright, browser-automation, testing, e2e, codegen, screenshots, sessions
  version: 3
---

# Browser Automation with playwright-cli

<purpose>
Drive a real browser from the shell with `playwright-cli`. Snapshot the page, interact via refs, manage tabs and sessions, and feed results back into the agent loop.
</purpose>

<scope>
  <use_when>
  - Verifying or debugging behavior in a running web app from the command line.
  - Generating, healing, or running Playwright tests.
  - Capturing snapshots, screenshots, network traffic, or traces for review.
  - Driving multi-step UI flows the user wants reproduced without writing test code yet.
  </use_when>

  <do_not_use_when>
  - The task is server-side or API-only; no browser interaction is needed.
  - A unit test or library API call would already give the answer.
  </do_not_use_when>
</scope>

<governing_rule>
Snapshot first, interact via refs, verify with another snapshot. Treat each command as one observable step; do not assume page state across actions without re-snapshotting.
</governing_rule>

<section name="environment">
- NixOS note: the default `chrome` channel needs system Google Chrome, which is not packaged on this host. Always pass `--browser chromium` to `open`. Run `node $(dirname $(realpath $(which playwright-cli)))/../lib/node_modules/@playwright/cli/node_modules/playwright/cli.js install chromium` once if browsers are not yet downloaded.
- If global `playwright-cli` is missing, try `npx --no-install playwright-cli --version`. When available, use `npx playwright-cli` in commands. Otherwise `npm install -g @playwright/cli@latest`.
</section>

<section name="quick-start">
```bash
playwright-cli open --browser chromium
playwright-cli goto https://playwright.dev
playwright-cli snapshot
playwright-cli click e15
playwright-cli type "page.click"
playwright-cli press Enter
playwright-cli close
```
</section>

<section name="core-concepts">
- Snapshots: every command emits a snapshot with `eNN` refs. Use those refs as the primary way to target elements. CSS selectors and Playwright locators (`getByRole`, `getByTestId`) also work.
- Output modes: `--raw` strips status/snapshot framing for piping; `--json` wraps every reply as JSON.
- Sessions: `-s=name open ...` creates a named session with optional `--persistent` profile; `playwright-cli list`, `close-all`, and `kill-all` manage them.
- Interactive UI review: `playwright-cli show --annotate` lets the user draw boxes and add notes; the agent receives the annotated artifact.
</section>

<section name="routing-to-references">
- Full command catalog (core, navigation, keyboard, mouse, tabs, storage, network, devtools, snapshots, sessions, install, worked examples) → `references/commands.md`
- Running and debugging Playwright tests → `references/playwright-tests.md`
- Request mocking → `references/request-mocking.md`
- Running Playwright code → `references/running-code.md`
- Browser session management → `references/session-management.md`
- Spec-driven testing (plan / generate / heal) → `references/spec-driven-testing.md`
- Storage state (cookies, localStorage) → `references/storage-state.md`
- Test generation → `references/test-generation.md`
- Tracing → `references/tracing.md`
- Video recording → `references/video-recording.md`
- Inspecting element attributes → `references/element-attributes.md`
</section>

<review_checklist>
- Took a snapshot before interacting with unknown page state.
- Used refs (or explicit locators) instead of guessing element positions.
- Re-snapshotted to verify the effect of an action.
- Closed or cleaned up sessions when the task ended.
- Passed `--browser chromium` when running on NixOS.
</review_checklist>
