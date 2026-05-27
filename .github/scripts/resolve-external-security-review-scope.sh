#!/usr/bin/env bash
# Emits review_scope and review_diff_cmd for external repository audits.
set -euo pipefail

target_repo="${TARGET_REPOSITORY:?TARGET_REPOSITORY is required (owner/repo)}"
target_ref="${TARGET_REF:-main}"
target_dir="${TARGET_REPO_DIR:-target-repo}"

if [[ ! -d "${target_dir}/.git" ]]; then
  echo "Missing cloned repository at ${target_dir}" >&2
  exit 1
fi

short_sha="$(git -C "${target_dir}" rev-parse --short HEAD)"
{
  echo "review_scope=External repository full audit (${target_repo}@${target_ref}, ${short_sha})"
  echo "review_diff_cmd=git -C ${target_dir} log -1 --stat"
} >> "${GITHUB_OUTPUT:?}"
