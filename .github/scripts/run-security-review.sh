#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${COPILOT_GITHUB_TOKEN:-}" ]]; then
  echo "::error::Missing COPILOT_GITHUB_TOKEN. Add a repository secret (fine-grained PAT with Copilot Requests). See README.md."
  exit 1
fi

report_path="${REPORT_PATH:-security-reports/security-review-report.md}"
mkdir -p "$(dirname "$report_path")"

echo "Running Security Reviewer via Copilot CLI (scope: ${REVIEW_SCOPE:-unknown})..."
bash .github/scripts/build-security-review-prompt.sh | copilot \
  -s \
  --no-ask-user \
  --allow-tool='shell(git:*)' \
  --allow-tool="write(${report_path})"

if [[ ! -f "$report_path" ]]; then
  echo "::warning::Copilot finished but report file was not created at ${report_path}"
  exit 1
fi

echo "Report written to ${report_path} ($(wc -l < "$report_path") lines)"
