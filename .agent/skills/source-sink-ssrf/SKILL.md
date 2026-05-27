---
name: source-sink-ssrf
description: >-
  Finds server-side request forgery where the app fetches attacker-controlled
  URLs. Use for webhooks, import-by-URL, PDF generators, image proxies, OAuth
  callbacks, or any HTTP client using user-supplied URLs.
---

# Source-Sink: Server-Side Request Forgery (SSRF)

SSRF makes the **server** request attacker-chosen URLs, reaching internal networks, cloud metadata, or bypassing firewalls.

## When to use

- URL fetch/import features (`fetch(url)`, `requests.get`, `curl`)
- Webhook registration and callback URLs
- Image/PDF from URL, OG preview, link unfurling
- SSO/OAuth redirect validation (partial overlap with open redirect)
- XML external entities (XXE) — related class

## Review procedure

### 1. Find HTTP clients with dynamic URLs

```
grep targets: fetch(, axios.get(, requests., HttpClient, urllib, WebClient
Trace: is URL fully or partially user-controlled?
```

### 2. Attack targets

| Target | Example |
|--------|---------|
| Cloud metadata | `http://169.254.169.254/latest/meta-data/` |
| Internal services | `http://localhost:6379/`, `http://10.0.0.5/admin` |
| File protocol | `file:///etc/passwd` (some libraries) |
| Gopher | Legacy attack on Redis, memcached |

### 3. Bypass techniques to consider

- DNS rebinding
- Decimal/octal IP: `http://2130706433/` (= 127.0.0.1)
- IPv6 localhost: `http://[::1]/`
- Redirect chains: allowlisted host redirects to internal
- URL parser differentials: `@`, `#`, `\`, encoded chars

### 4. Mitigations to verify

**Strong:**
- Allowlist of domains/IPs (not blocklist)
- Resolve DNS and block private/link-local ranges before request
- Disable redirects or re-validate each hop
- Network egress policies (defense in depth)

**Weak (often bypassable):**
- Blocklist of `127.0.0.1`, `localhost` only
- Regex URL validation without DNS resolution

### 5. Webhook-specific

- User registers `https://attacker.com/hook` — expected
- User registers `http://169.254.169.254/` — SSRF
- Validate URL at registration AND at delivery time

## Output format

```markdown
### [SSRF-001] Unrestricted URL fetch in preview feature
- **Severity:** High
- **Location:** `src/services/preview.ts:41`
- **Source:** `req.body.url`
- **Sink:** `axios.get(url)` with no allowlist
- **Impact:** Access to AWS metadata credentials, internal admin panels
- **Fix:** Allowlist domains; resolve and reject RFC1918/link-local; disable redirects
```
