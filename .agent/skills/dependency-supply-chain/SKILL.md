---
name: dependency-supply-chain
description: >-
  Reviews dependency and supply chain security — lockfiles, known CVEs, typosquat
  risk, and build integrity. Use when package manifests, lockfiles, Docker base
  images, or CI install steps change.
---

# Dependency & Supply Chain Security

Third-party code runs with your application's privileges. Dependency changes deserve security scrutiny equal to first-party code.

## When to use

- Changes to `package.json`, `requirements.txt`, `go.mod`, `Cargo.toml`, `pom.xml`
- Lockfile updates (package-lock, yarn.lock, poetry.lock)
- Docker `FROM` image changes
- New GitHub Actions or CI dependencies
- Post-install scripts (`preinstall`, `prepare`)

## Review procedure

### 1. Identify what changed

```
- [ ] New direct dependencies added?
- [ ] Version bumps (major vs patch)?
- [ ] Lockfile-only changes (transitive updates)?
- [ ] Removed dependencies (verify no orphaned imports)?
```

### 2. Dependency risk assessment

For each **new** dependency:

| Question | Red flag |
|----------|----------|
| Is it widely used / maintained? | Zero stars, archived, single maintainer |
| Name similar to popular package? | Typosquat (`reqeusts` vs `requests`) |
| What permissions does it need? | postinstall scripts, native binaries |
| Does it phone home? | Unexpected network calls in docs |

### 3. Known vulnerabilities

Check (or recommend checking):

```bash
npm audit
pip-audit / safety check
govulncheck ./...
cargo audit
trivy fs .
```

Note: audit tools have false negatives — still review risky packages manually.

### 4. Lockfile integrity

- [ ] Lockfile committed and updated atomically with manifest
- [ ] No `--no-lockfile` or `npm install package@latest` without lock in CI
- [ ] CI uses `npm ci` / frozen lockfile installs

### 5. Supply chain attack vectors

- **Dependency confusion:** private package name published publicly
- **Compromised maintainer:** sudden patch with obfuscated code
- **Git URL dependencies:** `npm install github:user/repo#branch` — pins to commit?
- **CDN scripts without SRI:** `<script src="https://cdn.example/lib.js">`

### 6. Docker base images

```dockerfile
FROM node:latest          # BAD: floating tag, large attack surface
FROM node:20.11-alpine    # BETTER: pinned minor, minimal image
```

- Pin digests for production: `node:20.11-alpine@sha256:...`
- Scan with Trivy/Grype

### 7. GitHub Actions pinning

```yaml
# BAD
uses: actions/checkout@v4

# BETTER (supply chain hardening)
uses: actions/checkout@8f4b7f84864484a7bf06670dae9bbc8b3cf3507a # v4.2.2
```

## Severity guidance

| Finding | Severity |
|---------|----------|
| Known Critical CVE in prod dependency | Critical |
| Known High CVE with exploit in scope | High |
| Unpinned major version of security lib | Medium |
| DevDependency CVE only | Low (note) |

## Output format

```markdown
### [DEPS-001] Critical CVE in lodash (transitive)
- **Severity:** High
- **Location:** `package-lock.json` — lodash@4.17.15
- **CVE:** CVE-2021-23337 (command injection via template)
- **Reachable:** Yes — used in `src/utils/format.ts`
- **Fix:** Upgrade to lodash@4.17.21+; run `npm audit fix`
```

If unable to run audit tools, state: "Manual CVE check recommended — run `npm audit` in CI."
