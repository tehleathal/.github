---
name: security-review-methodology
description: >-
  Orchestrates security code reviews from scope through threat model to review
  plan. Use at the start of every security review, PR audit, or seccheck before
  loading domain-specific skills.
---

# Security Review Methodology

Master workflow for structured security code review. Run this skill **first** on every review engagement.

## When to use

- Starting a PR or commit security review
- User asks for "security review", "seccheck", or "audit this change"
- Before loading injection, auth, or other domain skills

## Five-phase workflow

### Phase 1: Understand scope and architecture

```
Scope checklist:
- [ ] What files/commits/PR are in scope?
- [ ] What is the application type (web API, SPA, worker, IaC, library)?
- [ ] What frameworks and languages are involved?
- [ ] What changed vs. what is inherited context?
- [ ] Are there existing security controls (WAF, auth middleware, CSP)?
```

**Actions:**

1. Read the diff or changed files first, then expand to related auth/config code
2. Map high-level architecture: clients → gateway → app → data stores → third parties
3. Note trust boundaries (public internet, internal VPC, multi-tenant data layer)

### Phase 2: Build threat model

Use STRIDE-lite mapping. For each component in scope, ask which apply:

| STRIDE | Question | Category |
|--------|----------|----------|
| **S**poofing | Can attacker impersonate another user/tenant/service? | Business logic |
| **T**ampering | Can data be modified in transit or at rest without authorization? | Both |
| **R**epudiation | Are security events logged with integrity? | Info/hardening |
| **I**nformation disclosure | Can unauthorized parties read sensitive data? | Both |
| **D**enial of service | Can attacker exhaust resources? | API/infra |
| **E**levation of privilege | Can low-privilege user gain admin/other-tenant access? | Business logic |

Also classify threats:

- **Category 1 — Missing controls** (things that *should* be there): auth, authorization, CSRF, rate limits
- **Category 2 — Source→sink** (things that *shouldn't* happen): injection, XSS, SSRF, unsafe deserialization

### Phase 3: Translate to app-specific guidelines

Produce 5–10 **project-specific** rules for this review, e.g.:

- "Every `/api/v1/*` handler must call `requireAuth()` before business logic"
- "Tenant ID must come from JWT claims, never from request body"
- "All `$queryRaw` usages are Critical review targets"

Avoid generic rules like "validate input" — be specific to this codebase.

### Phase 4: Create review plan

Output a numbered plan listing:

1. Files/areas to inspect (prioritized by risk)
2. Which skills to apply (reference skill `name` values)
3. Specific questions each skill must answer for this change

**Example plan excerpt:**

```
1. [HIGH] src/api/users.ts — new DELETE endpoint
   → business-logic-authentication: Is JWT validated?
   → business-logic-authorization: Can user A delete user B?
   → business-logic-csrf: Cookie-based session + POST?

2. [HIGH] src/db/search.ts — raw SQL added
   → source-sink-injection: Trace req.query.q to query execution
```

### Phase 5: Execute review against plan

For each plan item:

1. Open the file and trace the relevant data flow
2. Load the mapped domain skill and follow its checklist
3. Record finding or mark **verified safe** with evidence
4. Do not skip items — note "N/A" with justification if truly irrelevant

## Output before domain skills

Before loading other skills, emit this brief:

```markdown
## Review scope
[2-3 sentences]

## Architecture notes
[Key boundaries and data flows]

## Threat model summary
| Threat | Applicable? | Priority |
|--------|-------------|----------|

## App-specific guidelines
1. ...
2. ...

## Review plan
1. [area] → [skills]
2. ...
```

Then proceed to execute the plan using domain skills.

## Anti-patterns

- Reviewing line-by-line without a threat model (misses logic flaws)
- Running OWASP checklist before understanding what changed
- Treating "no SAST alerts" as clean bill of health
- Reviewing only the diff without following calls into auth helpers
