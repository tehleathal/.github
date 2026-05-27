---
name: source-sink-open-redirect
description: >-
  Finds open redirect vulnerabilities in login flows, OAuth callbacks, and
  post-action redirects. Use when redirect URLs come from query parameters,
  form fields, or unvalidated Referer headers.
---

# Source-Sink: Open Redirect

Open redirects send users to attacker-controlled URLs while appearing to originate from a trusted domain. Used in phishing and OAuth token theft chains.

## When to use

- Login/logout redirect parameters (`?next=`, `?returnUrl=`, `?redirect_uri=`)
- OAuth/OIDC authorization flows
- Email verification / password reset links
- "Continue shopping" or post-payment redirects

## Review procedure

### 1. Find redirect sinks

```
response.redirect(url)
res.redirect(302, url)
window.location = param
Location: header from user input
```

### 2. Validation quality

**Fail patterns:**

```javascript
// Prefix check bypass: https://trusted.com.evil.com
if (url.startsWith('https://trusted.com')) redirect(url);

// Relative redirect abuse: //evil.com
redirect(req.query.next); // next=//evil.com/phish

// javascript: URLs
redirect(userUrl); // javascript:alert(document.cookie)
```

**Pass patterns:**

```javascript
// Allowlist exact paths or hosts
const allowed = ['/dashboard', '/settings'];
if (allowed.includes(url) || isAllowedHost(parseUrl(url).host)) {
  redirect(url);
}
// Default to safe internal path on failure
redirect('/home');
```

### 3. OAuth redirect_uri

- Strict allowlist registered per client
- No wildcard subdomains unless fully controlled
- Reject fragment components in redirect

### 4. Impact assessment

| Context | Severity |
|---------|----------|
| Pre-auth redirect to phishing clone | Medium–High |
| Post-auth redirect with token in URL | Critical |
| Open redirect in password reset email | High (phishing) |

## Output format

```markdown
### [REDIR-001] Open redirect in login flow
- **Severity:** Medium
- **Location:** `src/auth/login.ts:78`
- **Source:** `req.query.returnUrl`
- **Sink:** `res.redirect(returnUrl)` without validation
- **PoC:** `/login?returnUrl=https://evil.com/fake-login`
- **Fix:** Allowlist relative paths only; reject absolute URLs or validate host against registered list
```
