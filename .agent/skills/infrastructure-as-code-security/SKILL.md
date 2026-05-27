---
name: infrastructure-as-code-security
description: >-
  Reviews Terraform, CloudFormation, Kubernetes, and Dockerfile security
  misconfigurations. Use when IaC, deployment manifests, or cloud resource
  definitions change.
---

# Infrastructure-as-Code Security

Misconfigured cloud resources are a leading cause of data breaches. IaC changes define your security perimeter.

## When to use

- Terraform (`.tf`), Pulumi, CloudFormation, Bicep
- Kubernetes manifests, Helm charts
- Dockerfiles, docker-compose
- GitHub Actions workflow permissions
- IAM policies, security groups

## Terraform / CloudFormation

### Storage exposure

```hcl
# CRITICAL
resource "aws_s3_bucket" "data" {
  acl = "public-read"  # or missing public access block
}
```

Verify: S3 public access block, bucket policies, Azure blob public access disabled.

### Network exposure

```hcl
# BAD
ingress {
  cidr_blocks = ["0.0.0.0/0"]
  from_port   = 22
}
```

- [ ] SSH/RDP not open to 0.0.0.0/0
- [ ] Databases not publicly accessible
- [ ] Security groups least-privilege

### IAM overly permissive

```json
// CRITICAL
"Action": "*",
"Resource": "*"
```

- [ ] No `*` actions on `*` resources for human or workload roles
- [ ] Separate roles per service (not one super-role)
- [ ] Instance metadata v2 required (AWS IMDSv2)

### Secrets in state/plan

- [ ] No passwords in `.tf` files — use secrets manager / variables marked sensitive
- [ ] Terraform state encrypted and access-controlled

## Kubernetes

```yaml
# HIGH RISK
securityContext:
  privileged: true
  runAsUser: 0
```

Checklist:

- [ ] `runAsNonRoot: true` where possible
- [ ] `readOnlyRootFilesystem: true`
- [ ] Drop ALL capabilities; add only needed
- [ ] NetworkPolicies restrict pod-to-pod traffic
- [ ] Secrets not in ConfigMaps
- [ ] Image from trusted registry with digest pin
- [ ] RBAC: no cluster-admin for app service accounts

## Dockerfile

```dockerfile
# BAD
FROM ubuntu
COPY . .
RUN chmod 777 /app
USER root
ENTRYPOINT ./start.sh

# BETTER
FROM gcr.io/distroless/nodejs20-debian12
COPY --chown=nonroot:nonroot . .
USER nonroot
```

- [ ] Multi-stage builds; no build tools in runtime image
- [ ] No secrets in ENV or ARG
- [ ] `.dockerignore` excludes `.git`, `.env`

## CI/CD (GitHub Actions)

```yaml
permissions:
  contents: read  # least privilege

# BAD: PR from fork with secrets access
on: pull_request_target
```

- [ ] Workflows pin action SHAs
- [ ] `pull_request_target` not used with untrusted code + secrets
- [ ] OIDC for cloud deploy (not long-lived keys)

## Output format

```markdown
### [IAC-001] Public S3 bucket for user uploads
- **Severity:** Critical
- **Location:** `terraform/storage.tf:12`
- **Issue:** `acl = "public-read"` on `user_uploads` bucket
- **Impact:** All uploaded files world-readable
- **Fix:** Remove public ACL; use CloudFront signed URLs or presigned GET
```

If no IaC in scope, output: "IAC N/A — no infrastructure files in review scope."
