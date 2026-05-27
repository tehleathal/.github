---
name: business-logic-authorization
description: >-
  Reviews authorization beyond login — RBAC, tenant isolation, object-level
  access control, and privilege escalation. Use when authenticated routes may
  access other users' or tenants' data, or for admin/privileged operations.
---

# Business Logic: Authorization

Authentication proves **who**; authorization proves **what they may do**. Most real-world breaches are authorization failures, not auth bypass.

## When to use

- Multi-tenant applications
- RBAC/ABAC/policy engines
- CRUD on user-owned resources (documents, orders, profiles)
- Admin panels, impersonation, service-to-service calls

## Authorization layers (check all that apply)

```
Layer 1: Route-level role     → "Must be admin"
Layer 2: Tenant isolation     → "Row belongs to user's org"
Layer 3: Resource-level       → "User owns this specific record"
Layer 4: Field-level          → "May read but not write field X"
Layer 5: Action-level         → "May view but not delete"
```

A route can pass Layer 1 and still fail Layer 3.

## Review procedure

### 1. Identify authorization model

Document how this app encodes authorization:

- Roles in JWT claims? Database lookup? External policy service (OPA, Casbin)?
- Where is tenant ID sourced (claim vs. header vs. body — **body is suspect**)?

### 2. IDOR / horizontal privilege escalation

For every operation on `{id}`, `{userId}`, `{tenantId}`:

```
- [ ] Is the resource ID from user input?
- [ ] Does the query filter by authenticated user's tenant/user?
- [ ] Is authorization checked AFTER fetch (TOCTOU) or in the query?
```

**Fail:**

```javascript
// BAD: fetches any order by ID
app.get('/orders/:id', auth, async (req, res) => {
  const order = await Order.findById(req.params.id);
  res.json(order);
});
```

**Pass:**

```javascript
// GOOD: scoped query
const order = await Order.findOne({ _id: req.params.id, userId: req.user.id });
if (!order) return res.status(404).send();
```

### 3. Vertical privilege escalation

- Can regular user hit admin-only routes by URL guessing?
- Are admin checks on client only (hidden UI) without server enforcement?
- Role strings compared case-sensitively or from user-controlled JWT claim without signature?

### 4. Tenant isolation (multi-tenant)

Critical checks:

- Every DB query includes `tenant_id = current_tenant`
- Shared caches keyed by tenant
- Background jobs carry tenant context
- File storage paths include tenant prefix (no `s3://bucket/{user_supplied_path}`)
- Search/index queries scoped (Elasticsearch, SQL)

**Fail:** `SELECT * FROM invoices WHERE id = ?` without tenant filter

### 5. Mass assignment / over-posting

```javascript
// BAD: user can set role via body
User.update(req.body); // { name: "x", role: "admin" }
```

Use explicit allowlists for updatable fields.

### 6. Indirect references

- GraphQL: can nested resolver access parent object's unauthorized children?
- BFF/API aggregation: does inner service call use end-user token or over-privileged service account?
- Webhooks: can user register callback URL to internal metadata endpoints?

## Common bypass patterns

| Pattern | Example |
|---------|---------|
| Predictable IDs | Sequential user IDs enumerated |
| UUID without ownership check | UUID hard to guess but not authorization |
| Export/bulk endpoints | `/export?userId=other` |
| File download | `/files?path=../../other-tenant/secret.pdf` |
| JWT claim trust | `"role": "admin"` set client-side (unsigned token) |

## Output format

```markdown
### [AUTHZ-001] IDOR on order retrieval
- **Severity:** High
- **Location:** `src/routes/orders.ts:87`
- **Issue:** `findById(req.params.id)` without `userId` filter
- **Exploit:** Authenticated user A requests `/orders/{B's order UUID}`
- **Fix:** Add `where: { id, userId: req.user.id }`; return 404 not 403 to prevent enumeration
```
