#!/usr/bin/env bash
# Emits review_scope and review_diff_cmd for GITHUB_OUTPUT (used by security-review workflow).
set -euo pipefail

event="${GITHUB_EVENT_NAME:-}"

if [[ "$event" == "pull_request" ]]; then
  base="${PR_BASE_SHA:-}"
  head="${PR_HEAD_SHA:-${GITHUB_SHA:-}}"
  if [[ -z "$base" || -z "$head" ]]; then
    echo "Missing PR base/head SHAs" >&2
    exit 1
  fi
  {
    echo "review_scope=Pull request diff (${base:0:7}..${head:0:7})"
    echo "review_diff_cmd=git diff ${base}..${head}"
  } >> "${GITHUB_OUTPUT:?}"
elif [[ "$event" == "push" ]]; then
  if git rev-parse HEAD~1 >/dev/null 2>&1; then
    {
      echo "review_scope=Latest push commit range (HEAD~1..HEAD)"
      echo "review_diff_cmd=git diff HEAD~1..HEAD"
    } >> "${GITHUB_OUTPUT:?}"
  else
    {
      echo "review_scope=Initial commit (full tree at HEAD)"
      echo "review_diff_cmd=git show --stat HEAD"
    } >> "${GITHUB_OUTPUT:?}"
  fi
else
  {
    echo "review_scope=Manual workflow_dispatch (full repository)"
    echo "review_diff_cmd=git log -1 --stat"
  } >> "${GITHUB_OUTPUT:?}"
fi
