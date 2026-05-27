#!/usr/bin/env bash
# Prints the full Copilot prompt to stdout.
set -euo pipefail

repo="${GITHUB_REPOSITORY:?}"
event="${GITHUB_EVENT_NAME:?}"
sha="${GITHUB_SHA:?}"
ref="${GITHUB_REF_NAME:-}"
pr_number="${PR_NUMBER:-}"
review_scope="${REVIEW_SCOPE:?}"
review_diff_cmd="${REVIEW_DIFF_CMD:?}"
report_path="${REPORT_PATH:?}"

cat <<'CONSTRAINTS'
You are running in CI as the Security Reviewer agent. This is a read-only security audit.

Rules:
- Do NOT modify application source code, configs, or dependencies.
- You MAY only create or overwrite the security report file at the path given below.
- Follow the agent definition and skills exactly.
- Execute: security-review-methodology → relevant domain skills → owasp-top-10-review → security-review-report.
- Every Critical/High finding needs file:line evidence and an exploit scenario.
- If you find any Critical severity issue, append this exact line as the final line of the report:
  SECURITY_REVIEW_BLOCK_CRITICAL
- If merge recommendation is "Block merge", append this exact line as the final line of the report:
  SECURITY_REVIEW_BLOCK_MERGE
CONSTRAINTS

echo
echo "--- Agent definition (.github/agents/security-reviewer.agent.md) ---"
cat .github/agents/security-reviewer.agent.md

echo
echo "--- Skill: security-review-methodology (run first) ---"
cat .agent/skills/security-review-methodology/SKILL.md

echo
echo "--- Skill: security-review-report (output format — run last) ---"
cat .agent/skills/security-review-report/SKILL.md

echo
echo "--- Additional skills (load from .agent/skills/ as needed for the threat model) ---"
echo "Available under .agent/skills/: business-logic-*, source-sink-*, owasp-top-10-review, threat-modeling, secrets-detection, dependency-supply-chain, api-security-review, infrastructure-as-code-security."

cat <<EOF

--- CI context ---
Repository: ${repo}
Event: ${event}
Ref: ${ref}
Commit: ${sha}
Pull request: ${pr_number:-n/a}
Review scope: ${review_scope}
Diff command: ${review_diff_cmd}

--- Task ---
1. Run: ${review_diff_cmd}  (and inspect changed files) to scope the review. For workflow_dispatch or when the diff is empty, review the full repository with emphasis on security-sensitive paths.
2. Perform a complete security review per the agent workflow.
3. Write the final report to: ${report_path}
   Use the security-review-report markdown template. Include executive summary, findings table, Critical/High details, threat model, OWASP table, out of scope, and merge recommendation.
4. Do not ask clarifying questions; state assumptions in the report if needed.
EOF
