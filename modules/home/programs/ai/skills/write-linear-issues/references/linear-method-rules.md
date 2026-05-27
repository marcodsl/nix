# Linear Method — Source Rules

Quoted rules from the Linear Method articles, condensed so the loaded `SKILL.md` can stay tight.

## Sources

- ["Write issues not user stories"](https://linear.app/method/write-issues-not-user-stories)
- ["Scope projects down"](https://linear.app/method/scope-projects)
- ["Generate momentum"](https://linear.app/method/building-with-momentum)

## Against user stories

> "At Linear, we don't write user stories and think they're an anti-pattern in product development."

> "[User stories are] a cargo cult ritual that feels good but wastes a lot of resources and time."

Linear's specific criticisms, paraphrased from the article:

- A roundabout way to describe tasks; obscures the work to be done.
- Time-consuming to write and read.
- Silos engineers into a mechanical role where they code to the issue requirements instead of thinking about the user experience holistically.
- Pushes product-level details down into the task layer where they get re-litigated.
- Does not match how people actually talk about software in real conversations.

## What an issue should be

> "Short and simple issues that describe the task in plain language."

> "Write short and simple issue titles that directly state what the task is."

> "Descriptions should be optional — not required."

> "Write only as much as you need to share to perform the task."

An issue describes a concrete task with a defined outcome: code shipped, a design produced, a document written, or an action taken.

## What does not belong in the tracker

> "If it's not a task, then it doesn't belong in the issue tracker."

> "Maybe it's a project idea that needs to be fleshed out in a document or conversation."

For work that needs exploration before it can be a task, Linear recommends placeholder issues like `Explore design` or `Write project spec`, time-boxed so they do not drift.

## Who writes the issue

> "Everyone on the team should write their own issues."

> "It's faster and easier for the person who understands how to do the work."

Exception: a bug report from a non-assignee is fine, but the assignee should rewrite it as a task once the cause is understood.

## Where UX and product decisions live

UX and product decisions belong at the project or roadmap level, not on the task. Once the approach is decided, the issue delegates the work to a team that already understands user needs intuitively.

## Scope and sizing (from "Scope projects down")

- Projects should fit **1–3 weeks with 1–3 people**.
- Smaller fixes take **hours or a day**.
- "If there is no way to scope down the project, then break it down into stages."

Quoted consequences of oversizing:

- "Shorter projects force you to prioritize the most important feature set."
- "Smaller scopes get you into the habit of shipping continuously, which creates quick feedback loops with customers."
- "Smaller teams help you move faster and reduce the management and communication overhead."
- "When you're early in the product building stage, you don't know enough to predict whether a project will be impactful or not so it's better to avoid massive projects."

## Momentum (from "Generate momentum")

> "Decide to do it or not to do it. Then you do it today instead of tomorrow."

> "If you've designed your operations to move fast and learn, then you can correct or revert decisions."

Applied to issues: small issues that ship today beat large issues that ship next sprint. Size each issue so it can close in one focused session.

## Bug-report hygiene (industry consensus, not Linear)

The Linear method article does not detail bug-report structure. Industry consensus across QA and engineering guidance:

- A complete bug report has steps to reproduce, expected vs actual, environment, and evidence (screenshot, video, or log link).
- Avoid speculative diagnosis in the body ("probably a cache issue", "looks like a race condition"). Put guesses in a comment after investigation, not in the issue title or description.
- Title the bug by the observable behavior and the condition, not by the suspected cause.
