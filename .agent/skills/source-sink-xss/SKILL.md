---
name: source-sink-xss
description: >-
  Finds cross-site scripting via unsafe HTML rendering, DOM sinks, and missing
  CSP. Use for templates, React dangerouslySetInnerHTML, innerHTML, markdown
  renderers, or user-generated content display.
---

# Source-Sink: Cross-Site Scripting (XSS)

XSS occurs when untrusted data is rendered as active content in a victim's browser.

## When to use

- Server-side templates (Jinja, ERB, EJS)
- SPA rendering (React, Vue, Angular)
- Markdown/rich text renderers
- URL parameters reflected in HTML/JS
- PDF/HTML generators including user content

## XSS types

| Type | Source | Sink |
|------|--------|------|
| **Reflected** | Request param → immediate response | HTML body, JS context |
| **Stored** | Saved user content → later viewers | DB → template |
| **DOM-based** | `location.hash`, `postMessage` → DOM API | `innerHTML`, `document.write` |

## Review procedure

### 1. Map output contexts

Each sink has different encoding rules:

| Context | Required encoding |
|---------|-------------------|
| HTML body | HTML entity encode |
| HTML attribute | Attribute encode + quote |
| JavaScript string | JS escape |
| URL (`href`) | URL encode + scheme allowlist |
| CSS | Strict allowlist |

**Fail:** Using HTML encoding for JS context: `<script>var x='{{ user.name }}'</script>`

### 2. Framework-specific sinks

**React:**
```jsx
// VULNERABLE
<div dangerouslySetInnerHTML={{ __html: userBio }} />

// SAFE
<div>{userBio}</div> // auto-escaped
```

**Vue:** `v-html="untrusted"`

**Angular:** bypassSecurityTrustHtml

**Server templates:**
```jinja2
{# VULNERABLE #}
{{ user_content | safe }}

{# SAFE #}
{{ user_content }}  {# auto-escaped #}
```

### 3. Markdown and WYSIWYG

- Markdown → HTML converters often allow `<script>` via raw HTML
- Verify sanitizer (DOMPurify, bleach) with strict config
- Check `javascript:` URLs in links

### 4. DOM sinks (client-side)

```javascript
// VULNERABLE
element.innerHTML = userInput;
document.write(params.get('msg'));
eval(location.hash.slice(1));
```

Prefer `textContent`, framework bindings.

### 5. Content-Security-Policy

CSP is defense-in-depth, not primary fix. Note if missing:

```
Content-Security-Policy: default-src 'self'; script-src 'self'
```

Flag `unsafe-inline`, `unsafe-eval` in script-src.

### 6. Cookie flags (XSS impact reduction)

If XSS found, note whether session cookies lack `HttpOnly` (enables session theft).

## Testing mindset

For each user-controlled string reaching HTML:

- Would `<img src=x onerror=alert(1)>` execute?
- Would `"><script>alert(1)</script>` break out of attribute?
- JSON embedded in `<script>` tags — JSON not JS-safe without encoding

## Output format

```markdown
### [XSS-001] Stored XSS in comment display
- **Severity:** High
- **Location:** `views/comments.ejs:23`
- **Source:** `comment.body` from database (user-submitted)
- **Sink:** `<%- comment.body %>` (unescaped EJS output)
- **Impact:** Session theft via cookie exfiltration (cookies not HttpOnly)
- **Fix:** Use `<%= comment.body %>` or sanitize with DOMPurify before render
```
