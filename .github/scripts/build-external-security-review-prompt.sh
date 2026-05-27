#!/usr/bin/env bash
# Prints the Copilot prompt for auditing a cloned external repository.
set -euo pipefail

target_repo="${TARGET_REPOSITORY:?}"
target_ref="${TARGET_REF:-main}"
target_dir="${TARGET_REPO_DIR:-target-repo}"
review_scope="${REVIEW_SCOPE:?}"
review_diff_cmd="${REVIEW_DIFF_CMD:?}"
report_path="${REPORT_PATH:?}"

if [[ ! -d "${target_dir}" ]]; then
  echo "Target repository directory not found: ${target_dir}" >&2
  exit 1
fi

target_sha="$(git -C "${target_dir}" rev-parse HEAD)"
target_url="https://github.com/${target_repo}"

cat <<'CONSTRAINTS'
You are running in CI as the Security Reviewer agent. This is a read-only security audit of a third-party open-source repository.

Rules:
- Do NOT modify source code, configs, or dependencies in the cloned target repository.
- Do NOT modify files in the parent workflow repository except the security report at the path given below.
- You MAY read any file under the target repository directory.
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
Workflow repository: ${GITHUB_REPOSITORY:-unknown}
Target repository: ${target_repo}
Target URL: ${target_url}
Target ref: ${target_ref}
Target commit: ${target_sha}
Target directory: ${target_dir}/
Review scope: ${review_scope}
Diff command: ${review_diff_cmd}

--- Task ---
1. Change into or reference files under ${target_dir}/ for the entire review. This is a full-repository audit, not a PR diff.
2. Start with ${review_diff_cmd} and explore the repository tree. Prioritize security-sensitive paths: CLI entrypoints, parsers, file I/O, network transport, credential handling, exposure-catalog loading, MCP config parsing, CI/CD workflows, and release/build scripts.
3. Perform a complete security review per the agent workflow. For supply-chain inventory tools, pay special attention to: path traversal during scans, symlink handling, parsing untrusted lockfiles/manifests, credential redaction in output, catalog injection, and privilege assumptions of a fleet-deployed endpoint scanner.
4. Write the final report to: ${report_path}
   Use the security-review-report markdown template. Set **Target:** to "${target_repo} (${target_ref}, ${target_sha:0:7})". Include executive summary, findings table, Critical/High details, threat model, OWASP table, out of scope, and merge recommendation.
5. Do not ask clarifying questions; state assumptions in the report if needed.
EOF
