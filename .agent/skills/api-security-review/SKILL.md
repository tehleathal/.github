---
name: api-security-review
description: >-
  Reviews REST, GraphQL, and gRPC API security — authentication, authorization,
  rate limiting, input validation, and error handling. Use for new or modified
  API endpoints, schemas, and API gateways.
---

# API Security Review

APIs are the primary attack surface for modern applications. Review holistically, not just injection.

## When to use

- REST controllers, FastAPI/Express routes, NestJS modules
- GraphQL schemas, resolvers, subscriptions
- gRPC/protobuf services
- API gateway config, OpenAPI specs

## Review checklist

### Authentication & authorization

Cross-reference domain skills:

- [ ] Auth enforced before handler (see `business-logic-authentication`)
- [ ] Object-level auth on every resource ID (see `business-logic-authorization`)
- [ ] CSRF if cookie auth (see `business-logic-csrf`)

### Input validation

```
For each input (path, query, body, headers):
- [ ] Schema validation at boundary (Zod, Joi, Pydantic, class-validator)
- [ ] Type coercion safe (string "123abc" → int)
- [ ] Max length / array size limits
- [ ] Reject unknown fields (prevent mass assignment)
- [ ] File upload: size, MIME verify (magic bytes), extension allowlist
```

**Fail:**

```typescript
app.post('/users', (req, res) => {
  createUser(req.body); // no validation
});
```

### Rate limiting & abuse prevention

- [ ] Login, password reset, OTP endpoints rate-limited
- [ ] Expensive endpoints (search, export, report) throttled
- [ ] Per-user AND per-IP limits where appropriate
- [ ] GraphQL: query depth/complexity limits, disable introspection in prod

### HTTP method & status semantics

- [ ] Idempotent methods don't mutate state (GET, HEAD)
- [ ] 401 vs 403 used correctly (unauthenticated vs unauthorized)
- [ ] 404 instead of 403 for IDOR (prevent enumeration) — team preference

### Information disclosure

```json
// BAD: verbose error
{ "error": "duplicate key value violates unique constraint \"users_email_key\"" }

// BETTER
{ "error": "Email already registered" }
```

- [ ] Stack traces not in production responses
- [ ] Pagination doesn't leak total count of unauthorized resources

### CORS

```javascript
// Review: origin allowlist, credentials, exposed headers
cors({ origin: ['https://app.example.com'], credentials: true })
```

### GraphQL-specific

- [ ] Introspection disabled in production
- [ ] Batch attacks / alias flooding mitigated
- [ ] N+1 queries not a DoS vector (dataloaders, limits)
- [ ] Mutations require auth same as REST

### API versioning & deprecation

- Old API versions still receive security patches?
- Breaking auth changes don't leave old endpoints open

### Webhooks (outbound)

- [ ] HMAC signature on payload
- [ ] Retry with backoff; no secret in URL

## Output format

```markdown
### [API-001] Missing rate limit on password reset
- **Severity:** Medium
- **Location:** `POST /api/auth/reset-password`
- **Issue:** Unlimited requests enable email bombing and user enumeration
- **Fix:** Rate limit 5/hour per IP and per email; uniform response timing
```
