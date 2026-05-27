---
name: insecure-defaults
description: "Detect fail-open insecure defaults that let apps run insecurely in production, distinguishing them from fail-secure code that crashes on missing config. Triggers: `process.env.X || 'default'`, `getenv(...) or '...'`, `ENV.fetch(..., default:)`, hardcoded `password`/`api_key`/`JWT_SECRET`, `DEBUG=true`, `AUTH_REQUIRED=false`, `verify_ssl: false`, CORS `*`, permissions `0777`, MD5/SHA1/DES/RC4/ECB in security contexts, security audit of config or env handling. Skip when: the file is a test fixture, `.example`/`.template`/`.sample` file, dev-only Docker Compose, or documentation snippet."
allowed-tools: Read Grep Glob Bash
license: CC-BY-SA-4.0
metadata:
  author: trailofbits
  source: https://github.com/trailofbits/skills/tree/main/plugins/insecure-defaults/skills/insecure-defaults
  tags: security, audit, secrets, configuration, fail-open, hardcoded-credentials
  version: 3
---

# Insecure Defaults Detection

<purpose>
Find fail-open vulnerabilities where apps run insecurely with missing configuration. Distinguish exploitable defaults from fail-secure patterns that crash safely.
</purpose>

<scope>
  <use_when>
  - Security audits of production applications (auth, crypto, API security).
  - Configuration review of deployment files, IaC templates, Docker configs.
  - Code review of environment variable handling and secrets management.
  - Pre-deployment checks for hardcoded credentials or weak defaults.
  </use_when>

  <do_not_use_when>
  - Test fixtures scoped to test environments (`test/`, `spec/`, `__tests__/`).
  - Example or template files (`.example`, `.template`, `.sample`).
  - Development-only tools (local Docker Compose for dev, debug scripts).
  - Documentation examples in README.md or `docs/`.
  - Build-time configuration replaced during deployment.
  - Crash-on-missing behavior where the app cannot start without proper config (fail-secure).
  </do_not_use_when>
</scope>

<governing_rule>
A default is a finding only when production code paths actually run with it. Trace the code path to decide between fail-open (CRITICAL) and fail-secure (safe).

- Fail-open (critical): `SECRET = env.get('KEY') or 'default'` → app runs with weak secret.
- Fail-secure (safe): `SECRET = env['KEY']` → app crashes if missing.
</governing_rule>

<working_method>
1. SEARCH: discover language, framework, and conventions. Locate secret storage, credentialed integrations, crypto usage, and config files. Run targeted searches in production-reachable code (not tests or examples).
2. VERIFY: trace each match. When does it execute (startup vs runtime)? What happens with the variable missing? Is there validation enforcing secure config?
3. CONFIRM: determine production impact. If production config supplies the variable, lower severity but still flag the code-level vulnerability. If config is missing or uses the default, mark critical.
4. REPORT: include location, pattern, verification trace, production impact, and exploitation path.
</working_method>

<section name="search-patterns">
Focus searches in `**/config/`, `**/auth/`, `**/database/`, and env files:
- Fallback secrets: `getenv.*\) or ['"]`, `process\.env\.[A-Z_]+ \|\| ['"]`, `ENV\.fetch.*default:`.
- Hardcoded credentials: `password.*=.*['"][^'"]{8,}['"]`, `api[_-]?key.*=.*['"][^'"]+['"]`.
- Weak defaults: `DEBUG.*=.*true`, `AUTH.*=.*false`, `CORS.*=.*\*`.
- Crypto algorithms: `MD5|SHA1|DES|RC4|ECB` in security contexts.

Tailor the approach based on discovery. Focus on production-reachable code, not test fixtures or example files.
</section>

<section name="finding-categories">
- Fallback secrets (`SECRET = env.get(X) or Y`): verify app starts without env var and secret is used in crypto/auth. Skip tests and examples.
- Default credentials (hardcoded `username`/`password` pairs): verify active in deployed config with no runtime override. Skip disabled accounts and documentation.
- Fail-open security (`AUTH_REQUIRED = env.get(X, 'false')`): verify default is insecure. Safe when app crashes or default is secure.
- Weak crypto (MD5/SHA1/DES/RC4/ECB in security contexts): verify use for passwords, encryption, or tokens. Skip checksums and non-security hashing.
- Permissive access (CORS `*`, permissions `0777`, public-by-default): verify the default allows unauthorized access. Skip explicitly justified permissiveness.
- Debug features (stack traces, introspection, verbose errors): verify enabled by default and exposed in responses. Skip logging-only.
</section>

<section name="rationalizations">
Reject these excuses:
- "It's just a development default" → if it reaches production code, it's a finding.
- "The production config overrides it" → verify prod config exists; the code-level vulnerability remains otherwise.
- "This would never run without proper config" → prove it with a code trace; many apps fail silently.
- "It's behind authentication" → defense in depth; a compromised session still exploits weak defaults.
- "We'll fix it before release" → document now; "later" rarely comes.
</section>

<section name="report-format">
```
Finding: Hardcoded JWT Secret Fallback
Location: src/auth/jwt.ts:15
Pattern: const secret = process.env.JWT_SECRET || 'default';

Verification: App starts without JWT_SECRET; secret used in jwt.sign() at line 42
Production Impact: Dockerfile missing JWT_SECRET
Exploitation: Attacker forges JWTs using 'default', gains unauthorized access
```
</section>

<review_checklist>
- Each finding sits in production-reachable code, not tests or examples.
- Each finding has a traced runtime behavior, not just a pattern match.
- Each finding distinguishes fail-open from fail-secure.
- Rationalizations rejected when applicable.
- Report names location, pattern, verification, production impact, and exploitation path.
</review_checklist>

<bundled_resources>
- `references/examples.md` — detailed examples and counter-examples per finding category.
</bundled_resources>
