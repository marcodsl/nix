# Conventional Commits examples

Reference messages for the common shapes. Match the spec at https://www.conventionalcommits.org/en/v1.0.0/#specification.

## Feature

```text
feat(lang): add Polish language
```

## Bug fix with body and footers

```text
fix(parser): prevent racing of requests

Introduce a request id and keep only the latest response.
Remove timeout-based mitigation that is now obsolete.

Reviewed-by: Z
Refs: #123
```

## Breaking change with `!`

```text
feat(api)!: remove v1 session endpoint
```

## Breaking change with footer

```text
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` in config files now loads and merges external config files.
```

## Documentation-only change

```text
docs: correct spelling of CHANGELOG
```

## Revert-style extension

```text
revert: drop experimental formatter integration

Refs: 676104e
```

## Multi-paragraph commit via repeated `-m`

```bash
git commit -m "fix(parser): prevent racing of requests" \
  -m "Introduce a request id and keep only the latest response." \
  -m "Refs: #123"
```

## Subject-line phrasing

- Good: `fix(parser): reject invalid UTF-8 sequences`
- Weak: `fix(parser): fixed parser bug`
- Weak: `chore: stuff`

## Scope choice

- Good: `feat(api): add cursor pagination`
- Weak: `feat(stuff): add pagination`
