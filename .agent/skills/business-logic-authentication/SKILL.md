---
name: business-logic-authentication
description: >-
  Reviews authentication controls — session validation, JWT verification, API
  keys, and identity on every protected route. Use for login flows, middleware,
  route guards, token handling, or when auth bypass is suspected.
---

# Business Logic: Authentication

Static scanners cannot verify that **every protected route actually authenticates**. This skill finds missing, weak, or bypassable authentication.

## When to use

- New or modified routes, controllers, handlers, resolvers
- Auth middleware, guards, decorators, filters
- JWT/session/API-key validation code
- "Requires login" claims in PR descriptions

## Review procedure

### 1. Inventory protected vs. public endpoints

```
For each entry point in scope:
- [ ] Is it intended to be public or authenticated?
- [ ] Does code enforce that intent before any side effect?
- [ ] Are there alternate paths (internal routes, debug flags, GraphQL fields)?
```

### 2. Verify authentication happens **before** business logic

**Fail patterns:**

```typescript
// BAD: business logic runs before auth check
async function deleteUser(req, res) {
  const user = await db.users.find(req.params.id);
  if (!req.user) return res.status(401).send(); // too late — timing side channel
  await db.users.delete(user.id);
}
```

```python
# BAD: optional auth — anonymous gets same code path
@router.get("/profile")
def profile(user: User | None = Depends(get_optional_user)):
    return get_sensitive_data(user or default_user)
```

**Pass patterns:**

- Global middleware/guard applied at router level
- Decorator `@RequireAuth` on class or method with framework-enforced ordering
- Fail-closed default: unauthenticated → 401 before handler body

### 3. Session and token validation depth

Check each mechanism:

| Mechanism | Verify |
|-----------|--------|
| **JWT** | Signature alg not `none`; secret/key from secure config; `exp`/`nbf` checked; issuer/audience if used; no sensitive data in payload |
| **Session cookie** | `HttpOnly`, `Secure`, `SameSite`; session ID rotated on login; server-side invalidation |
| **API keys** | Not in URL query strings; compared with constant-time compare; scoped and revocable |
| **OAuth/OIDC** | State parameter for CSRF; redirect URI allowlist; token exchange server-side |

### 4. Authentication bypass vectors

Hunt specifically for:

- **Route registration order** — unprotected duplicate route shadows protected one
- **HTTP method confusion** — `GET` unauthenticated, `POST` authenticated on same resource
- **Path normalization** — `/admin` vs `/admin/` vs `/./admin`
- **Header spoofing** — trusting `X-User-Id`, `X-Forwarded-User` without gateway validation
- **JWT `kid` injection** — accepting attacker-supplied signing keys
- **Default credentials** — hardcoded admin passwords in config/seeds
- **Debug endpoints** — `/health`, `/metrics`, `/graphql` introspection exposing mutations

### 5. Password and credential handling

- Passwords hashed with bcrypt/argon2/scrypt (not MD5/SHA1)
- No password in logs, error messages, or URL params
- Rate limiting / lockout on login (cross-ref `api-security-review`)

## Evidence to collect

For each issue:

1. Entry point (route, handler name)
2. Expected auth mechanism vs. what code actually does
3. Exploit scenario (e.g., "unauthenticated DELETE /api/users/123")

## Output format

```markdown
### [AUTH-001] Missing authentication on {endpoint}
- **Severity:** Critical
- **Location:** `file:line`
- **Issue:** Handler performs {action} without calling {auth middleware}
- **Exploit:** `curl -X DELETE https://app/api/users/1` (no token)
- **Fix:** Apply `requireAuth` middleware at router level; add test asserting 401 without token
```

Mark verified-safe routes explicitly: "AUTH-OK: `/api/foo` — `authMiddleware` applied in `routes/index.ts:42`"
