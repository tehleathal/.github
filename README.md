# tehleathal/.github

Special repository for [@tehleathal](https://github.com/tehleathal).

- **`profile/README.md`** — GitHub profile README (shown on your profile page)
- **Community health defaults** — fallback files for repos that do not define their own

See [GitHub's docs on default community health files](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file).

## Contents

| Path | Purpose |
|------|---------|
| `profile/README.md` | Profile page README |
| `CONTRIBUTING.md` | Default contribution guidelines |
| `CODE_OF_CONDUCT.md` | Default code of conduct |
| `SECURITY.md` | Default security policy |
| `.github/ISSUE_TEMPLATE/` | Default issue templates |
| `.github/PULL_REQUEST_TEMPLATE.md` | Default pull request template |
| `.github/agents/security-reviewer.agent.md` | Security Reviewer custom agent |
| `.github/workflows/security-review.yml` | Copilot CLI security review on push/PR |
| `.agent/skills/` | Security review skills (methodology, report format, domains) |

## Automated security review (Copilot CLI)

On **pull requests**, **pushes to `main`**, and **manual dispatch**, the [Security Review](.github/workflows/security-review.yml) workflow runs the Security Reviewer agent via [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-copilot-cli/automate-with-actions).

### One-time setup

1. **Copilot subscription** on the account that owns the token (Pro+ / Business / Enterprise as required by your org).
2. **Fine-grained personal access token** with **Copilot Requests** (read-only is enough for review-only runs). See [Authenticate Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/set-up-copilot-cli/authenticate-copilot-cli).
3. Repository secret **`COPILOT_GITHUB_TOKEN`** (or **`PERSONAL_ACCESS_TOKEN`**) — paste the PAT:
   - Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
   - Name: `COPILOT_GITHUB_TOKEN`
   - Value: your fine-grained PAT

If the workflow fails immediately with "Missing repository secret", this step was skipped or the secret name does not match.

### What you get

- Markdown report at `security-reports/security-review-report.md` (artifact + job summary)
- Job **fails** if the report includes `SECURITY_REVIEW_BLOCK_CRITICAL`, `SECURITY_REVIEW_BLOCK_MERGE`, or recommends **Block merge**

### Run manually

Actions → **Security Review** → **Run workflow**.

### Reuse in other repositories

Copy `.github/workflows/security-review.yml`, `.github/scripts/`, `.github/agents/security-reviewer.agent.md`, and `.agent/skills/`, then add the `COPILOT_GITHUB_TOKEN` secret.
