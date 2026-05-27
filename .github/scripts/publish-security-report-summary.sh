#!/usr/bin/env bash
set -euo pipefail

report_path="${REPORT_PATH:-security-reports/security-review-report.md}"
summary="${GITHUB_STEP_SUMMARY:?}"

if [[ ! -f "$report_path" ]]; then
  {
    echo "## Security Review"
    echo
    echo "No report was generated. Check the **Run Security Reviewer** step logs and \`COPILOT_GITHUB_TOKEN\` setup."
  } >>"$summary"
  exit 0
fi

{
  echo "## Security Review Report"
  echo
  echo "**Repository:** \`${GITHUB_REPOSITORY:-}\` · **Event:** \`${GITHUB_EVENT_NAME:-}\` · **SHA:** \`${GITHUB_SHA:-}\`"
  echo
  cat "$report_path"
} >>"$summary"
