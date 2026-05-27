#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${COPILOT_GITHUB_TOKEN:-}" ]]; then
  echo "::error::Copilot token is empty. Set repository secret COPILOT_GITHUB_TOKEN or PERSONAL_ACCESS_TOKEN (fine-grained PAT with Copilot Requests). See README.md."
  exit 1
fi

report_path="${REPORT_PATH:-security-reports/security-review-report.md}"
mkdir -p "$(dirname "$report_path")"

prompt_builder="${PROMPT_BUILDER:-.github/scripts/build-security-review-prompt.sh}"

echo "Running Security Reviewer via Copilot CLI (scope: ${REVIEW_SCOPE:-unknown})..."
bash "${prompt_builder}" | copilot \
  -s \
  --no-ask-user \
  --allow-tool='shell(git:*)' \
  --allow-tool="write(${report_path})"

if [[ ! -f "$report_path" ]]; then
  echo "::warning::Copilot finished but report file was not created at ${report_path}"
  exit 1
fi

echo "Report written to ${report_path} ($(wc -l < "$report_path") lines)"
