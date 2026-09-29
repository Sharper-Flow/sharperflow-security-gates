#!/usr/bin/env bash
# Resolve the security-gate scan range for the current event.
#
# Writes mode, base, and head to $GITHUB_OUTPUT:
#   mode=diff base=<sha> head=<sha>  -> scan only the commits in base..head
#   mode=full                        -> scan the whole tree
#
# SCAN_MODE=auto (default) resolves per event:
#   pull_request -> base=HEAD^1, head=HEAD^2 (parents of the merge ref; the
#                   synthetic merge commit has no patch of its own, so
#                   HEAD^1..HEAD would scan nothing)
#   merge_group  -> base=merge_group.base_sha, head=HEAD
#   any other event, SCAN_MODE=full, or a base that does not resolve -> full
set -euo pipefail

: "${GITHUB_OUTPUT:?GITHUB_OUTPUT must be set}"
event_name="${GITHUB_EVENT_NAME:-}"
scan_mode="${SCAN_MODE:-auto}"

if [[ "${scan_mode}" != "auto" && "${scan_mode}" != "full" ]]; then
  echo "::error::scan-mode must be 'auto' or 'full', got '${scan_mode}'"
  exit 1
fi

write_outputs() {
  local mode="$1" base="${2:-}" head="${3:-}"
  {
    echo "mode=${mode}"
    echo "base=${base}"
    echo "head=${head}"
  } >>"${GITHUB_OUTPUT}"
}

resolve_commit() {
  # Prints the commit sha when it exists locally, nothing otherwise.
  git rev-parse --verify --quiet "$1^{commit}" 2>/dev/null || true
}

if [[ "${scan_mode}" == "full" ]]; then
  write_outputs full
  exit 0
fi

if [[ "${event_name}" == "pull_request" ]]; then
  base="$(resolve_commit "HEAD^1")"
  head_commit="$(resolve_commit "HEAD^2")"
  if [[ -z "${base}" || -z "${head_commit}" ]]; then
    echo "::notice::pull_request merge-ref parents did not resolve; running a full scan"
    write_outputs full
    exit 0
  fi
  write_outputs diff "${base}" "${head_commit}"
elif [[ "${event_name}" == "merge_group" ]]; then
  if [[ -z "${GITHUB_EVENT_PATH:-}" || ! -f "${GITHUB_EVENT_PATH}" ]]; then
    echo "::notice::merge_group event payload not found; running a full scan"
    write_outputs full
    exit 0
  fi
  base_sha="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("merge_group", {}).get("base_sha", ""))' "${GITHUB_EVENT_PATH}")"
  base="$(resolve_commit "${base_sha}")"
  head_commit="$(resolve_commit "HEAD")"
  if [[ -z "${base}" || -z "${head_commit}" ]]; then
    echo "::notice::merge_group.base_sha did not resolve to a local commit; running a full scan"
    write_outputs full
    exit 0
  fi
  write_outputs diff "${base}" "${head_commit}"
else
  echo "::notice::event '${event_name:-}' has no pull-request diff; running a full scan"
  write_outputs full
fi
