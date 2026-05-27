---
name: source-sink-injection
description: >-
  Traces user input to dangerous sinks — SQL, NoSQL, OS command, LDAP, and
  template injection. Use when queries, shell commands, or dynamic code
  execution involve request data, file content, or external input.
---

# Source-Sink: Injection

Find paths where **attacker-controlled data** reaches a **dangerous sink** without proper parameterization or validation.

## When to use

- Database queries (SQL, ORM raw queries, stored procedures)
- NoSQL (MongoDB `$where`, operator injection)
- Shell commands (`exec`, `system`, `subprocess`)
- LDAP, XPath, template engines (SSTI)
- Dynamic code (`eval`, `Function`, `pickle`)

## Methodology: source → transform → sink

For each suspect path:

```
1. SOURCE: Where does data enter? (req.body, headers, file upload, webhook)
2. TRANSFORMS: Encoding, sanitization, ORM mapping — do they actually prevent injection?
3. SINK: What executes/interprets the data? (DB driver, shell, template engine)
4. VERDICT: Parameterized/bound? Allowlist? Still exploitable?
```

## Sink catalog

### SQL injection

**Sinks:** `query()`, `execute()`, `$queryRaw`, string concatenation in SQL

```python
# VULNERABLE
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")

# SAFE (parameterized)
cursor.execute("SELECT * FROM users WHERE name = ?", (name,))
```

**Review ORM "escape hatches":** `raw()`, `literal()`, `whereRaw`, `sequelize.query`

**Second-order SQLi:** User input stored in DB, later concatenated into query unescaped.

### NoSQL injection

```javascript
// VULNERABLE: operator injection via body
db.users.find({ username: req.body.username }); // body: { "username": { "$gt": "" } }

// SAFE
db.users.find({ username: String(req.body.username) });
```

Check: `$where`, `$regex` with user input, JavaScript evaluation in MongoDB

### Command injection

**Sinks:** `exec`, `spawn` with shell, `os.system`, backticks

```javascript
// VULNERABLE
exec(`convert ${userFilename} output.png`);

// SAFE
execFile('convert', [userFilename, 'output.png']); // + validate filename allowlist
```

### LDAP / XPath injection

User input in LDAP filter strings or XPath expressions without escaping.

### Server-Side Template Injection (SSTI)

**Sinks:** Jinja2 `Template(userInput)`, ERB, Freemarker with user-controlled template

Test mentally: can input contain `{{7*7}}` or `${7*7}`?

## High-risk code patterns (grep targets)

```
$queryRaw|executeRaw|raw\(|\.query\(`|f".*SELECT|format\(.*SELECT
exec\(|spawn\(.*shell|system\(|subprocess.*shell=True
eval\(|new Function\(|vm\.run
```

## False positive avoidance

- Parameterized queries with **all** dynamic parts bound — verify no string concat for identifiers
- ORM-generated queries — still check raw fragments
- "Sanitized" via blacklist — often bypassable

## Output format

```markdown
### [INJ-001] SQL injection in user search
- **Severity:** Critical
- **Location:** `src/repos/userRepo.ts:56`
- **Source:** `req.query.q` (GET parameter)
- **Sink:** `` db.query(`SELECT * FROM users WHERE name LIKE '%${q}%'`) ``
- **PoC:** `?q=' OR '1'='1`
- **Fix:** Use parameterized query: `WHERE name LIKE ?` with `[`%${q}%`]`
```
