---
name: threat-modeling
description: >-
  Practical STRIDE-based threat modeling for features and architecture changes.
  Use for new endpoints, multi-tenant features, auth redesigns, or when scope
  is unfamiliar before deep code review.
---

# Threat Modeling (STRIDE)

Lightweight threat modeling tailored for code review — not a formal diagramming exercise unless complexity warrants it.

## When to use

- New feature with unclear risk surface
- Architecture or auth model changes
- Multi-tenant or financial/healthcare data
- Before writing the review plan in `security-review-methodology`

## STRIDE per element

For each **component** (endpoint, service, data store, queue), evaluate:

| Threat | Question | Example finding |
|--------|----------|-----------------|
| **S** Spoofing | Can identity be faked? | JWT alg none, missing API key validation |
| **T** Tampering | Can data be modified unauthorized? | Missing HMAC on webhook, unsigned S3 uploads |
| **R** Repudiation | Can actions be denied? | No audit log on admin delete |
| **I** Info disclosure | Can data leak? | Verbose errors, IDOR, log injection |
| **D** DoS | Can service be exhausted? | Unbounded query, no rate limit, zip bomb |
| **E** Elevation | Can privilege increase? | Mass assignment, role in unsigned claim |

## Four-question rapid model

Answer in 5 minutes:

1. **What are we building?** (one sentence)
2. **What can go wrong?** (brainstorm 5–10 threats)
3. **What are we going to do about it?** (map to existing controls or gaps)
4. **Did we do a good job?** (after review — residual risk)

## Data flow diagram (text-based)

When helpful, sketch:

```
[Browser] --HTTPS--> [API Gateway] --mTLS--> [App Service]
                                              |
                         +--------------------+--------------------+
                         v                    v                    v
                    [PostgreSQL]         [Redis cache]      [S3 bucket]
                    tenant-scoped        session keys       user uploads
```

Mark **trust boundaries** with `|||`:

```
[Untrusted Internet] ||| [App] ||| [Internal DB]
```

Threats often live at boundaries.

## Threat → skill mapping

| Threat pattern | Skill to load |
|----------------|---------------|
| Missing login check | `business-logic-authentication` |
| Cross-tenant access | `business-logic-authorization` |
| Form POST without token | `business-logic-csrf` |
| User input in query | `source-sink-injection` |
| User content in HTML | `source-sink-xss` |
| Fetch user URL | `source-sink-ssrf` |
| Parse user blob | `source-sink-deserialization` |
| Redirect param | `source-sink-open-redirect` |
| New REST surface | `api-security-review` |
| Terraform/K8s change | `infrastructure-as-code-security` |

## Prioritization (DREAD-lite)

Score each threat 1–3 on: **D**amage, **R**eproducibility, **E**xploitability. Focus review on scores ≥ 6 total.

## Output template

```markdown
## Threat model: {feature name}

### Assets
- User PII, payment tokens, ...

### Trust boundaries
- Internet → API (auth required)
- API → DB (tenant filter required)

### Threat register
| ID | STRIDE | Threat | Likelihood | Impact | Mitigation status |
|----|--------|--------|------------|--------|-------------------|
| T-01 | E | User accesses other tenant's records | High | Critical | **GAP** — no tenant filter in new query |
| T-02 | I | Error message leaks stack trace | Med | Low | Partial — global handler exists |

### Review priorities
1. T-01 → business-logic-authorization on `src/api/invoices.ts`
2. T-02 → verify error handler covers new routes
```

Feed the **Review priorities** section directly into `security-review-methodology` Phase 4 plan.
