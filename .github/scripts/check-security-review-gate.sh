#!/usr/bin/env bash
# Fails the job when the report signals blocking Critical/High findings.
set -euo pipefail

report_path="${REPORT_PATH:-security-reports/security-review-report.md}"

if [[ ! -f "$report_path" ]]; then
  echo "No security report — skipping merge gate."
  exit 0
fi

if grep -qE 'SECURITY_REVIEW_BLOCK_(CRITICAL|MERGE)' "$report_path"; then
  echo "::error::Blocking security findings detected. See the report artifact and job summary."
  grep -E 'SECURITY_REVIEW_BLOCK_(CRITICAL|MERGE)' "$report_path" || true
  exit 1
fi

# Fallback: explicit Block merge recommendation without sentinel (older runs)
if grep -qiE '^\*\*Recommendation:\*\*.*Block merge' "$report_path" \
  || grep -qiE 'Recommendation:.*Block merge' "$report_path"; then
  echo "::error::Report recommends Block merge."
  exit 1
fi

echo "No blocking security gate triggered."
