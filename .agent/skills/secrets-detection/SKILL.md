---
name: secrets-detection
description: >-
  Detects hardcoded secrets, credentials, API keys, and tokens in code, config,
  tests, and CI. Use for every review pass and when scanning new config files,
  env examples, or infrastructure changes.
---

# Secrets & Credentials Detection

Hardcoded secrets in repos are immediately exploitable if leaked via git history, forks, or logs.

## When to use

- Any code/config change (quick pass)
- New `.env.example`, config YAML, docker-compose, CI workflows
- Test fixtures and mock data
- Client-side code (never put secrets in frontend bundles)

## Scan procedure

### 1. High-confidence patterns

Search changed files for:

```
# API keys and tokens
(AKIA[0-9A-Z]{16})                    # AWS access key
(ghp_[a-zA-Z0-9]{36})                 # GitHub PAT
(xox[baprs]-[0-9a-zA-Z-]+)            # Slack token
(sk_live_[0-9a-zA-Z]{24,})            # Stripe live key
(api[_-]?key\s*[:=]\s*['"][^'"]+['"]) # Generic API key assignment

# Private keys
-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----

# Passwords in code
password\s*[:=]\s*['"][^'"]{8,}['"]
```

Also check: Base64 blobs near `secret`, `token`, `credential` variable names.

### 2. Common hiding places

- Test files (`test/fixtures/config.json`) — still get committed and scanned by attackers
- Docker Compose `environment:` sections
- GitHub Actions `${{ }}` with hardcoded values instead of secrets
- Frontend `.env` files bundled into JS
- Comments: `// prod password: ...`
- Terraform `default = "..."` for sensitive vars

### 3. .env and gitignore hygiene

- [ ] `.env` in `.gitignore` (verify not committed in PR)
- [ ] `.env.example` has placeholders only (`your-api-key-here`)
- [ ] No real secrets in example files

### 4. Logging and error leakage

```javascript
logger.info('Connecting with password', password); // LEAK
throw new Error(`Auth failed for key ${apiKey}`);   // LEAK
```

### 5. Client-side exposure

Secrets in browser-delivered code are public:

- AWS keys in React apps
- Firebase config (apiKey is often public by design — verify Firebase rules compensate)
- JWT signing secrets in frontend

## Severity

| Finding | Severity |
|---------|----------|
| Production private key / cloud root key | Critical |
| Live payment API key | Critical |
| Test-only key in committed test | High (may be reused) |
| Placeholder in .env.example | Info |

## Remediation guidance

1. **Rotate immediately** — assume compromised if ever committed
2. Move to secret manager / env vars / GitHub Actions secrets
3. Use `git filter-repo` or BFG if secret hit main branch history
4. Add pre-commit hook (detect-secrets, gitleaks)

## Output format

```markdown
### [SEC-001] Hardcoded AWS access key
- **Severity:** Critical
- **Location:** `scripts/deploy.sh:14`
- **Evidence:** `AKIAIOSFODNN7EXAMPLE`
- **Fix:** Remove from repo; rotate key in IAM; use OIDC/GitHub Actions secrets
- **Note:** Check git history for prior exposure
```

Do not reproduce full secret values in the report — truncate: `AKIA...MPLE`.
