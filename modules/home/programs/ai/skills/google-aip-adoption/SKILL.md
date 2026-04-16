---
name: google-aip-adoption
description: "Design and review API contracts with Google AIP conventions. Use when: shaping resource models, choosing standard vs custom methods, defining field behavior, planning compatibility/versioning, or documenting exceptions."
license: AGPL-3.0-only
metadata:
  author: marcodsl
  tags: [api-design, google-aip, contracts]
---

## Google AIP Adoption

Rules for using Google AIP guidance to design, review, and refactor API contracts without depending on Google-specific tooling.

## Purpose

Use this skill to turn broad API-style guidance into concrete contract decisions. Treat Google AIPs as the default source of truth for resource-oriented APIs, then map that guidance onto the protocol or stack in use.

## Scope

### Use this skill when

- Creating or reviewing API contracts, resource models, or lifecycle methods.
- Checking whether standard methods, custom methods, and long-running behavior follow predictable AIP semantics.
- Evaluating field behavior, pagination, filtering, errors, compatibility, or exception rationale.
- Refactoring brownfield APIs toward stronger AIP-style consistency without breaking compatibility.

### Do not use this skill when

- The task is mostly about transport syntax, code generation, or framework annotations rather than contract behavior.
- The API intentionally follows a different style guide and the task is not to compare or migrate it toward AIP conventions.
- The work is implementation-only and does not involve API contract design, review, or compatibility decisions.

## Governing rule

Prefer predictable, resource-oriented contracts over ad hoc RPC shapes. Start with stable resource identity and standard methods, then justify every exception explicitly.

## Core contract rules

### Start with resource-oriented design

- Model resources before methods ([AIP-121](https://google.aip.dev/121)).
- Use canonical identity concepts such as `name` and `parent` when those concepts exist, and keep resource names hierarchical and stable ([AIP-122](https://google.aip.dev/122), [AIP-123](https://google.aip.dev/123)).
- Prefer standard lifecycle methods (`Get`, `List`, `Create`, `Update`, `Delete`) before inventing custom or batch methods ([AIP-131](https://google.aip.dev/131) to [AIP-135](https://google.aip.dev/135)).
- Treat AIP conventions as the default for new management-plane APIs. For data-plane APIs, apply the same principles where they improve the contract and document intentional deviations.
- Map AIP intent onto the stack in use. Do not require a specific protocol, schema language, annotation system, or linter just to claim compliance.

### Choose method shape deliberately

- Use `Get` for one resource by stable identity, `List` for bounded collection reads, `Create` under a parent, `Update` with explicit partial update semantics, and `Delete` with explicit deletion behavior.
- Use custom methods only when standard methods do not model the behavior ([AIP-136](https://google.aip.dev/136)).
- Use canonical `:verb` URI forms for custom methods. Keep `name` or `parent` as the only URI variable, and do not turn slash-action forms into new precedents ([AIP-127](https://google.aip.dev/127), [AIP-136](https://google.aip.dev/136)).
- Expose long-running work explicitly instead of hiding asynchronous behavior behind synchronous-looking methods ([AIP-151](https://google.aip.dev/151)).
- Prefer singular methods over batch methods until there is a real use case. If batch methods exist, define atomicity, ordering, limits, and failure reporting explicitly ([AIP-231](https://google.aip.dev/231), [AIP-233](https://google.aip.dev/233), [AIP-234](https://google.aip.dev/234), [AIP-235](https://google.aip.dev/235)).

### Make field semantics explicit

- Use noun-first field names and make field behavior explicit: required, optional, output-only, immutable ([AIP-140](https://google.aip.dev/140), [AIP-203](https://google.aip.dev/203)).
- Use resource-relative field masks for updates and keep read and write semantics aligned ([AIP-161](https://google.aip.dev/161)).
- Track explicit field presence only when unset vs default is semantically meaningful ([AIP-149](https://google.aip.dev/149)).
- Assign each field a clear owner. If the server computes an effective value, preserve user intent and expose the computed value separately ([AIP-129](https://google.aip.dev/129)).
- Treat lifecycle state as service-managed output and use explicit actions for state transitions ([AIP-216](https://google.aip.dev/216)).
- Use standard metadata fields and timestamps consistently when those concepts exist ([AIP-148](https://google.aip.dev/148)).

### Design collection and mutation safety

- Add pagination from the start for collection-returning RPCs, and keep page tokens opaque and non-authorizing ([AIP-158](https://google.aip.dev/158)).
- If filtering exists, use one documented `string filter` instead of inventing multiple query mechanisms ([AIP-160](https://google.aip.dev/160)).
- Support concurrency control and idempotency for retry-sensitive mutations when the domain needs them ([AIP-154](https://google.aip.dev/154), [AIP-155](https://google.aip.dev/155)).
- Offer validation-only execution, soft-delete behavior, and bulk-delete safeguards when those workflows matter ([AIP-163](https://google.aip.dev/163), [AIP-164](https://google.aip.dev/164), [AIP-165](https://google.aip.dev/165)).
- Document wildcard-parent and partial-failure behavior explicitly for cross-collection reads or multi-target operations ([AIP-159](https://google.aip.dev/159), [AIP-217](https://google.aip.dev/217)).

### Make errors and compatibility boring

- Return structured, machine-readable errors with stable codes and actionable metadata ([AIP-193](https://google.aip.dev/193)).
- Check authorization before validation when that avoids leaking resource existence ([AIP-211](https://google.aip.dev/211)).
- Align retry expectations with status-code semantics instead of making callers guess ([AIP-194](https://google.aip.dev/194)).
- Do not remove, rename, or move contract elements in the same major version. Do not change resource names, field types, or default behavior in place ([AIP-180](https://google.aip.dev/180)).
- Use major-only versions such as `v1`, `v1beta`, or `v1alpha` ([AIP-185](https://google.aip.dev/185)).
- For brownfield APIs, preserve compatibility first and converge toward stronger AIP compliance incrementally.

## Review workflow

Review API contracts in this order:

1. Identify the resource model and whether the API is management-plane, data-plane, or a mixed surface.
2. Classify each RPC as standard, custom, long-running, or batch.
3. Check resource identity, method semantics, field behavior, pagination/filtering, error handling, and compatibility expectations.
4. Prefer fixing deviations over carrying exceptions.
5. Use whatever validation mechanisms the repo already has, but do not block adoption on unavailable Google-specific tooling.

## Exception policy

- Every intentional standards deviation must include a short rationale, bounded scope, and an explicit non-precedent note such as `aip.dev/not-precedent`.
- Do not reuse one exception as precedent for new APIs ([AIP-200](https://google.aip.dev/200)).
- If compatibility forces a legacy alias or non-canonical shape, treat it as compatibility debt rather than the new default.

## Verification checklist

- [ ] Modeled resources, names, and parents before choosing methods.
- [ ] Chose standard methods before custom, long-running, or batch alternatives.
- [ ] Made field behavior, masks, pagination, filtering, and mutation safety explicit where relevant.
- [ ] Defined error, authorization, retry, and compatibility semantics.
- [ ] Documented long-running behavior, partial-failure behavior, or legacy exceptions where they exist.
- [ ] Recorded every intentional deviation as bounded, compatibility-aware, and non-precedent.
