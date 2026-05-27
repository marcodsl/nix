# Before / After

Worked rewrites for the three shapes this skill sees most often. Each example shows the raw input, the rewritten issue, and one or two lines on why the rewrite is what it is.

## 1. User story → task

### Before

```
As a user, I want to reset my password so that I don't get locked out of my account.

Acceptance criteria:
- User can click "Forgot password" on the login page
- User receives an email with a reset link
- Reset link expires after 24 hours
- User can set a new password and is logged in
```

### After

**Title:** `Add password reset flow`

**Description:**

```
Route: /auth/reset-password
- "Forgot password" link on the login page sends a signed reset token to the account email.
- Token expires in 24h.
- Submitting a new password logs the user in and invalidates the token.
```

**Why:**

- Dropped the `As a user, I want… so that…` wrapper. The rationale is implicit and already lives in the auth project.
- Kept the four acceptance criteria because the user supplied them, but compressed to one block. No invented criteria.
- Title is imperative and names one object (`password reset flow`).

## 2. Vague feature → split proposal

### Before

```
Improve onboarding.
```

### After (scope-check fires → ask before drafting)

**Scope decision:** `split-proposed`

This title has zero verbs that say what to do, and `onboarding` spans signup, email verification, the welcome modal, and the empty-state tour. Two signals: vague verb, multi-subsystem. Asking the user to choose:

1. **Keep as one issue** — only if `Improve onboarding` is meant as a placeholder you will refine before pickup.
2. **Split into siblings:**
   - `Reduce signup form to email + password`
   - `Send verification email within 5s of signup`
   - `Replace welcome modal with inline checklist`
3. **Promote to a project** — `Onboarding v2`, with the three siblings above as sub-issues plus `Measure activation rate after launch`.

**Why:**

- Did not draft a description for `Improve onboarding` because the title alone fails the scope check. Drafting first would lock in scope the user has not chosen.
- The sibling titles are each imperative with one object and could each close in a focused day.

## 3. Bug paste → task

### Before

```
The submit button doesn't work sometimes. Tried on Chrome, sometimes the form just sits there after I click. Probably a cache issue?
```

### After

**Title:** `Fix Submit button no-op on slow networks`

**Description:**

```
Steps to reproduce:
1. Open /checkout with a throttled connection (DevTools → Network → Slow 3G).
2. Fill the form with valid data.
3. Click "Submit".

Expected: form posts and the page navigates to /checkout/confirm.
Actual: button stays enabled, no network request is sent, no error in the console.

Environment: Chrome 130, macOS 15.1, web app v2.34.0.
Evidence: screen recording in the linked Slack thread.
```

**Why:**

- Dropped the speculative cause (`probably a cache issue`). That belongs in a comment after the assignee investigates, not in the body.
- Title names the observable behavior (`Submit button no-op`) and the condition (`on slow networks`), not the suspected cause.
- Added environment and evidence because the reporter omitted them and the assignee will need both. No invented detail beyond what the reporter described; the throttled-network repro is the closest deterministic version of "sometimes".

## 4. Multi-subsystem chore → split

### Before

```
Refactor the auth module, migrate sessions to JWT, and update the docs while we're at it.
```

### After (scope-check fires → split-proposed)

Four signals fire: three imperative verbs, two subsystems (`auth module`, `docs`), the phrase `while we're at it`, and a mix of refactor + migration + docs.

**Scope decision:** `split-proposed`. Propose three siblings under a new project `Auth → JWT migration`:

- `Replace session middleware with JWT verifier`
- `Migrate existing sessions to JWT on next login`
- `Update auth docs to describe JWT flow`

**Why:**

- Each sibling closes in a focused session and maps to one PR.
- `while we're at it` is a flag for unrelated scope; the docs update gets its own issue rather than riding along.

## 5. Already-fine issue (no rewrite)

### Before

```
Title: Add /healthz endpoint returning 200
```

### After

No change. Title is imperative, names one object, is scannable, and the work is small enough that no description is needed. Output: `single-issue`, description `(none)`, reasoning: `title carries the full scope`.

The skill should recognize this case and not invent a description just to fill the field.
