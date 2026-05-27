---
name: source-sink-deserialization
description: >-
  Finds unsafe deserialization and remote code execution sinks — pickle, YAML,
  Java serialization, .NET BinaryFormatter, eval. Use when parsing serialized
  objects, accepting binary formats, or dynamic code execution exists.
---

# Source-Sink: Unsafe Deserialization & RCE

Untrusted serialized data can execute arbitrary code during deserialization.

## When to use

- Deserialization APIs (Java `ObjectInputStream`, Python `pickle`, PHP `unserialize`)
- YAML/XML parsers with unsafe defaults
- `eval`, `exec`, dynamic imports from user input
- Template engines with code execution
- File upload processing (auto-deserialize metadata)

## High-risk sinks by language

| Language | Dangerous API | Safe alternative |
|----------|---------------|------------------|
| Python | `pickle.loads`, `yaml.load` | `json.loads`, `yaml.safe_load` |
| Java | `ObjectInputStream`, Jackson default typing | Typed DTOs, no default typing |
| PHP | `unserialize()` | JSON |
| .NET | `BinaryFormatter`, `TypeNameHandling.All` | System.Text.Json strict |
| Node | `node-serialize`, `vm.runInContext` with user code | JSON.parse only |

## Review procedure

### 1. Trace serialized input sources

- HTTP body (not just JSON — check Content-Type)
- Cookies, session blobs
- Message queues (Kafka, RabbitMQ payloads)
- Cache values (Redis)
- File uploads

### 2. Java-specific: gadget chains

Jackson/Fastjson with `@type` or default typing:

```java
// VULNERABLE
objectMapper.enableDefaultTyping();

// User sends: {"@class":"com.sun.rowset.JdbcRowSetImpl",...}
```

### 3. Python pickle

**Never** unpickle untrusted data. No mitigation except not using pickle.

### 4. YAML

```python
yaml.load(user_input)        # VULNERABLE — can instantiate arbitrary objects
yaml.safe_load(user_input)   # SAFE for standard YAML
```

### 5. eval/exec RCE

```javascript
// VULNERABLE
eval(req.body.expression);
new Function(userCode)();
```

### 6. Prototype pollution (JS)

```javascript
// merge(userInput, defaults) where userInput has __proto__
```

Can lead to RCE via template engines or gadget chains.

## Output format

```markdown
### [DESER-001] Pickle deserialization of user upload
- **Severity:** Critical
- **Location:** `src/workers/process.py:112`
- **Source:** Uploaded `.pkl` file contents
- **Sink:** `pickle.loads(data)`
- **Impact:** Arbitrary code execution on worker host
- **Fix:** Replace with JSON schema-validated format; never unpickle untrusted data
```
