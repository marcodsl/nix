# Google Cloud Skills — Third-Party Attribution

The following references under `references/` are imports from the
[google/skills](https://github.com/google/skills) repository, distributed under
the Apache License 2.0 (see `LICENSE` in this directory):

- `alloydb-basics`
- `bigquery-basics`
- `cloud-run-basics`
- `cloud-sql-basics`
- `firebase-basics`
- `gemini-api`
- `gke-basics`
- `google-cloud-recipe-auth`
- `google-cloud-recipe-networking-observability`*
- `google-cloud-recipe-onboarding`
- `google-cloud-waf-cost-optimization`
- `google-cloud-waf-reliability`
- `google-cloud-waf-security`

The body content of each upstream `SKILL.md` was relocated to
`references/<name>.md` and its YAML frontmatter stripped so the merged parent
skill in `SKILL.md` carries the only frontmatter. Per-skill `references/` and
`assets/` subdirectories were nested under `references/<name>/`. No prose was
modified.

## Source

- Upstream: <https://github.com/google/skills>
- Pinned commit: `42b28e212973529d8c17ce73c2044c1455d0966f`
- Imported on: 2026-05-05

\* Imported from upstream directory `google-cloud-networking-observability`
and renamed to match its declared `name:` in `SKILL.md`
(`google-cloud-recipe-networking-observability`), so the directory and skill
name agree. File contents are unchanged.

## License

These references are licensed under the Apache License, Version 2.0. The full
license text is in `LICENSE` in this directory. The remainder of this dotfiles
repository is licensed separately (AGPL-3.0-only); the Apache-2.0 terms apply
only to the listed references and to `LICENSE` itself.
