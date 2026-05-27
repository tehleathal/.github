---
name: business-logic-csrf
description: >-
  Reviews CSRF protection for state-changing operations — forms, cookie-based
  sessions, and cross-origin requests. Use for POST/PUT/PATCH/DELETE handlers,
  cookie auth, or when browsers may send authenticated requests cross-site.
---

# Business Logic: CSRF Protection

CSRF forces a victim's browser to perform authenticated actions they did not intend. APIs using **cookie-based sessions** without CSRF tokens are especially vulnerable.

## When to use

- State-changing HTTP methods (POST, PUT, PATCH, DELETE)
- Cookie-based authentication (session cookies, `SameSite=None` cookies)
- Server-rendered forms
- OAuth consent flows
- NOT typically needed for: pure Bearer-token APIs with no cookies (verify this assumption)

## Decision tree

```
Uses cookie-based session for auth?
├─ NO (Bearer token in Authorization header only, no cookies)
│   └─ CSRF risk LOW — verify CORS + no cookie fallback
└─ YES
    └─ State-changing endpoints exist?
        ├─ YES → CSRF protection REQUIRED unless alternative mitigations proven
        └─ NO → document why (read-only app)
```

## Review procedure

### 1. Identify state-changing endpoints

List all mutations in scope. For each:

- [ ] CSRF token validated (synchronizer token, double-submit cookie)?
- [ ] Or: `SameSite=Strict/Lax` on session cookie **and** no sensitive GET side effects?
- [ ] Or: Custom header required (`X-Requested-With`, `X-CSRF-Token`) with CORS preventing cross-origin send?

### 2. CSRF token implementation quality

If tokens used, verify:

- Token bound to session (not static per app)
- Token validated on server for every mutation
- Token rotated on privilege change (login)
- Token not accepted from URL query string
- AJAX and form submissions both covered

**Fail:**

```html
<!-- Token in form but endpoint also accepts POST without token via API -->
<form method="POST"><input type="hidden" name="csrf" value="...">
```

### 3. SameSite cookie analysis

| Setting | CSRF protection |
|---------|-----------------|
| `SameSite=Strict` | Strong for same-site navigation |
| `SameSite=Lax` | Protects POST from third-party; top-level GET may still send cookie |
| `SameSite=None` | **Requires** CSRF token or other mitigation |
| Missing attribute | Browser defaults vary — treat as gap |

### 4. CORS misconfiguration enabling CSRF-like attacks

```javascript
// BAD: reflects any origin with credentials
app.use(cors({ origin: true, credentials: true }));
```

With `credentials: true`, attacker origin must not be reflected.

### 5. GraphQL / JSON API with cookies

Cookie-authenticated GraphQL mutations need CSRF protection same as REST.

### 6. OAuth-specific

- `state` parameter prevents login CSRF
- Redirect URI strictly allowlisted

## Safe patterns

```javascript
// Double-submit or synchronizer token middleware on all mutations
app.use('/api', csrfProtection);
app.post('/api/transfer', requireCsrf, handler);

// OR: Bearer-only API, cookies not used for auth
// Document: "Session cookie is display-only; API requires Authorization header"
```

## Output format

```markdown
### [CSRF-001] Unprotected fund transfer endpoint
- **Severity:** High
- **Location:** `src/routes/transfer.ts:34`
- **Issue:** POST `/api/transfer` uses session cookie auth without CSRF token
- **Exploit:** Attacker site submits form to `/api/transfer` while victim is logged in
- **Fix:** Add CSRF middleware; set `SameSite=Strict` on session cookie; require custom header for API
```
