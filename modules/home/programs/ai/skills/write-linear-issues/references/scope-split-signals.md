# Scope Split Signals

The skill runs this checklist before drafting any title. Rule of thumb: **two or more signals → stop and ask the user before drafting.**

## Signal list

Title and verb signals:

- **Multiple imperative verbs in the title.** `Add X and update Y and migrate Z` is three issues, not one.
- **Vague action verb.** `Improve`, `clean up`, `revisit`, `polish`, `harden`. These hide scope; they do not constrain it.
- **No verb at all.** `Onboarding`, `Payments`, `Auth`. That is a project name, not an issue title.

Surface-area signals:

- **More than one subsystem, screen, route, or service named.** Crossing module boundaries usually means multiple PRs and possibly multiple reviewers.
- **Mixed user-facing and infrastructure work** in the same issue (`Add CSV export and migrate the export worker to a queue`).
- **Mixes a bug fix with new feature work.** Land the fix first; the feature is its own issue.

Effort signals (Linear sizing guide: hours-to-a-day for fixes, 1–3 weeks for projects):

- **Estimated effort exceeds one focused day.**
- **Likely to need more than one PR.**
- **Likely to need more than one assignee** (frontend + backend + design).
- **Cannot close in one cycle.** If the team uses cycles and this issue spans more than one, it is a project.

Description signals (look for these phrases in the input):

- `and also`
- `plus`
- `while we're at it`
- `as well as`
- `also need to`
- `refactor` (as a side-note inside a feature issue)
- `cleanup` (as a side-note inside a feature issue)

Acceptance-criteria signals:

- **Three or more distinct acceptance criteria** that each require different code paths or different tests.
- **Acceptance criteria from different personas** (admin + end user + integrator).

## How to ask the user

Use the host's structured-choice tool. Phrase the question as `This looks like more than one task — how would you like to split it?` and offer:

1. **Keep as one issue** — accept the size; the skill will add a short note in the description acknowledging the scope.
2. **Split into siblings** — the skill will propose 2–5 sibling issue titles under the same parent or project. The user picks which to keep.
3. **Promote to a project** — the work is project-sized; the skill will propose a project name and 2–5 sub-issue titles.

When the host has no question tool, fall back to one short markdown question that lists the three options.

Do not draft titles or descriptions for the split until the user picks an option. The signals are evidence the scope is wrong, not a license to invent the breakdown unilaterally.

## When signals fire but the user keeps as one issue

Acknowledge the size in the description with one line, for example: `Scope intentionally large; spans middleware and the docs site. Split if blocked.` Do not invent acceptance criteria to compensate for the size.

## When zero or one signals fire

Draft directly. Do not ask. Asking on every issue is the noisy mode the user explicitly opted out of.
