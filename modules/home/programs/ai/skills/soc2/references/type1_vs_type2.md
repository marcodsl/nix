# Type I vs Type II

## Side-by-side

| Aspect | Type I | Type II |
|--------|--------|---------|
| Scope | Design of controls at a point in time | Design AND operating effectiveness over a period |
| Duration | Snapshot (single date) | Observation window (3-12 months, typically 6) |
| Evidence | Control descriptions, policies | Control descriptions plus operating evidence (logs, tickets, screenshots) |
| Cost | $20K-$50K (audit fees) | $30K-$100K+ (audit fees) |
| Timeline | 1-2 months (audit phase) | 6-12 months (observation + audit) |
| Best for | First-time compliance, rapid market need | Mature organizations, enterprise customers |

## Typical journey

```
Gap Assessment → Remediation → Type I Audit → Observation Period → Type II Audit → Annual Renewal
    (4-8 wk)      (8-16 wk)     (4-6 wk)       (6-12 mo)          (4-6 wk)       (ongoing)
```

## When to choose which

- **Type I** is the right starting point when this is your first SOC 2 effort, when an enterprise customer needs *some* assurance quickly, or when you need to validate that the design of your controls is sound before committing to an observation window.
- **Type II** is what enterprise procurement teams ultimately ask for. Plan to graduate from Type I to Type II once your controls have been operating long enough to produce evidence (typically 3-6 months).
- A **bridge letter** issued by management between the end of the report period and the renewal can keep customers covered while a fresh Type II is in progress.

## Type II operating-effectiveness checks

`scripts/gap_analyzer.py` runs an additional pass when invoked with `--type type2`. Each check below is applied per control; failures are bucketed by severity in the resulting JSON report.

| Check | Description | Severity |
|-------|-------------|----------|
| `evidence_period` | Evidence covers the full observation period | critical |
| `operating_consistency` | Control operated consistently throughout the period | critical |
| `frequency_adherence` | Control executed at the specified frequency | critical |
| `evidence_timestamps` | Evidence has timestamps within the observation period | high |
| `exception_handling` | Exceptions are documented and addressed | high |
| `owner_accountability` | Control owners are documented and accountable | medium |

The script currently flags missing `evidence_date`, missing `owner`, non-`collected` `status`, and missing `frequency` on each control. Treat the output as a baseline checklist and extend it with custom checks (e.g. cross-referencing ticket counts with the declared frequency) once the basics pass.

## Upgrade path from Type I to Type II

1. **Lock control descriptions** — the controls described in your Type I report should be the same controls under observation in Type II. Changes during the observation period must be documented and explained to the auditor.
2. **Establish the observation window** — typically begins the day after the Type I report period ends. 6 months is the most common first window; 12 months is required for many enterprise contracts.
3. **Automate evidence collection** — manual collection across a 6-month window does not scale. Wire up the automation listed in `evidence_collection_guide.md` before the window starts.
4. **Run a mid-period self-assessment** — at the half-way mark, run `gap_analyzer.py --type type2` against your live evidence to surface deficiencies while you still have time to remediate.
5. **Pre-audit dry run** — 4-6 weeks before fieldwork, walk every control with its owner and confirm that evidence exists, is timestamped within the window, and matches the declared frequency.
