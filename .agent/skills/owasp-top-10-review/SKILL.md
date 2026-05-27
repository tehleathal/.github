---
name: owasp-top-10-review
description: >-
  OWASP Top 10 baseline checklist mapped to concrete code review actions. Use
  after threat modeling for broad coverage, or as a final pass before report
  generation.
---

# OWASP Top 10 Review Checklist

Baseline pass ensuring no Top 10 category is missed. **Run after** `security-review-methodology` threat model — skip categories marked N/A with justification.

## OWASP Top 10 (2021) → Review actions

### A01: Broken Access Control

- [ ] Every object reference authorized (see `business-logic-authorization`)
- [ ] CORS not overly permissive with credentials
- [ ] Directory listing disabled; path traversal blocked
- [ ] Rate limits on sensitive actions

**Look for:** Missing `@PreAuthorize`, IDOR, forced browsing to `/admin`

### A02: Cryptographic Failures

- [ ] TLS enforced (HSTS, no mixed content)
- [ ] Passwords hashed with modern algorithm (argon2/bcrypt)
- [ ] Secrets not in source code (see `secrets-detection`)
- [ ] Sensitive data not logged
- [ ] Weak random (`Math.random()` for tokens)

### A03: Injection

- [ ] All DB/shell/template paths parameterized (see `source-sink-injection`)
- [ ] ORM raw query usage audited

### A04: Insecure Design

- [ ] Threat model exists for new features (see `threat-modeling`)
- [ ] Business logic limits (transfer caps, rate limits) at server
- [ ] No security through obscurity as sole control

### A05: Security Misconfiguration

- [ ] Debug mode off in production configs
- [ ] Default credentials changed
- [ ] Error responses don't leak stack traces
- [ ] Security headers present (CSP, X-Frame-Options, etc.)
- [ ] Cloud storage buckets not public (see `infrastructure-as-code-security`)

### A06: Vulnerable and Outdated Components

- [ ] Dependencies scanned for CVEs (see `dependency-supply-chain`)
- [ ] No EOL runtime versions

### A07: Identification and Authentication Failures

- [ ] Auth on all protected routes (see `business-logic-authentication`)
- [ ] Session fixation prevented; logout invalidates session
- [ ] MFA for sensitive operations (note gap if missing)

### A08: Software and Data Integrity Failures

- [ ] CI/CD pipeline integrity (signed artifacts, protected branches)
- [ ] Auto-update without signature verification
- [ ] Insecure deserialization (see `source-sink-deserialization`)

### A09: Security Logging and Monitoring Failures

- [ ] Auth failures logged (not passwords)
- [ ] Audit trail for admin actions
- [ ] Logs don't contain PII/secrets

### A10: Server-Side Request Forgery

- [ ] URL fetchers validated (see `source-sink-ssrf`)

## Execution instructions

1. Copy checklist into review notes
2. For each applicable item, cite **pass** (with evidence) or **fail** (with finding ID)
3. Mark N/A items: "A10 N/A — no server-side URL fetch in this PR"
4. Escalate any unchecked item to a domain skill for deep review

## Output

```markdown
## OWASP Top 10 coverage
| Category | Status | Notes |
|----------|--------|-------|
| A01 Access control | FAIL | AUTHZ-001 IDOR |
| A03 Injection | PASS | All queries parameterized in changed files |
| A10 SSRF | N/A | No URL fetch in scope |
```

Do not duplicate full finding writeups here — reference finding IDs from domain skills.
