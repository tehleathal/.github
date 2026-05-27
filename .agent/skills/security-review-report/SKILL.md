---
name: security-review-report
description: >-
  Formats structured security review findings with severity, evidence, and
  remediation. Use as the final step of every security review to deliver
  consistent, actionable output.
---

# Security Review Report Format

Standard output format for all security reviews. Use this skill **last**, after domain skills complete.

## When to use

- Completing any security review engagement
- User asks for "security report", "findings", or "audit results"
- Before giving merge recommendation

## Report template

Copy and fill completely:

```markdown
# Security Review Report

**Target:** {PR # / branch / files reviewed}
**Reviewer:** Security Reviewer agent
**Date:** {YYYY-MM-DD}
**Scope:** {brief description of what was reviewed}

---

## Executive summary

{2-4 sentences: overall risk posture, key themes, merge recommendation}

**Recommendation:** `[ ] Approve` `[ ] Approve with fixes` `[ ] Block merge`

---

## Findings summary

| Severity | Count |
|----------|-------|
| Critical | {n} |
| High | {n} |
| Medium | {n} |
| Low | {n} |
| Info | {n} |

---

## Critical & High findings

{Repeat block below for each Critical and High finding}

### [{ID}] {Short title}

| Field | Value |
|-------|-------|
| **Severity** | Critical / High |
| **Category** | {Auth / AuthZ / CSRF / Injection / XSS / SSRF / ...} |
| **Location** | `{file}:{line}` or `{file}:{start}-{end}` |
| **CWE** | {CWE-XXX if known, optional} |

**Description**
{What is wrong and why it matters — 2-3 sentences}

**Evidence**
{Code snippet, data-flow path, or request/response showing the issue}

**Exploit scenario**
{Step-by-step narrative of how an attacker would abuse this}

**Remediation**
{Specific fix — code pattern, config change, or architectural change}

**Verification**
{How to confirm the fix: test case, curl command, or manual step}

---

## Medium, Low & Info findings

{Shorter format acceptable}

### [{ID}] {Title}
- **Severity:** Medium
- **Location:** `file:line`
- **Issue:** {one sentence}
- **Fix:** {one sentence}

---

## Verified safe (optional)

List controls explicitly verified to reduce noise on re-review:

- `AUTH-OK` `/api/users` — JWT middleware at `routes/index.ts:42`
- `INJ-OK` All SQL in `userRepo.ts` uses parameterized queries

---

## Threat model summary

{From security-review-methodology / threat-modeling — 3-5 bullets}

---

## OWASP Top 10 coverage

| Category | Result |
|----------|--------|
| A01 Broken access control | {Pass/Fail/N/A} |
| ... | ... |

---

## Out of scope & assumptions

- {e.g., "Did not pentest production environment"}
- {e.g., "Assumed auth middleware in parent repo is unchanged"}

---

## Recommended next steps

1. {Fix Critical/High in priority order}
2. {Add regression test for {ID}}
3. {Re-run review after fixes}
```

## Finding ID conventions

Use prefixed IDs for traceability:

| Prefix | Category |
|--------|----------|
| AUTH- | Authentication |
| AUTHZ- | Authorization |
| CSRF- | CSRF |
| INJ- | Injection |
| XSS- | XSS |
| SSRF- | SSRF |
| DESER- | Deserialization |
| REDIR- | Open redirect |
| SEC- | Secrets |
| DEPS- | Dependencies |
| API- | API security |
| IAC- | Infrastructure |

Number sequentially within review: `AUTH-001`, `AUTH-002`.

## Severity definitions

| Level | Merge impact |
|-------|--------------|
| **Critical** | Block merge until fixed or explicit risk acceptance |
| **High** | Block merge unless fix planned before release |
| **Medium** | Should fix; may merge with ticket |
| **Low** | Fix when convenient |
| **Info** | No action required |

## Quality bar

Every Critical/High finding MUST have:

1. Exact location
2. Evidence (not hypothetical)
3. Exploit scenario
4. Actionable remediation

If evidence insufficient, downgrade to **Info** with label `HYPOTHESIS — needs validation`.

## Merge recommendation logic

```
Block        → Any open Critical, or High with trivial exploit in prod path
Approve w/ fixes → High/Medium with clear fix plan, no Critical
Approve      → No Critical/High; Medium accepted or none
```

State recommendation explicitly. Do not leave ambiguous.
