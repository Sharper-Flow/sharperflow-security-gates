#!/usr/bin/env bash
# Gitleaks gate wrapper for the Sharperflow security gates.
#
# Runs the Gitleaks container as the runner uid (a container-uid mismatch makes
# Gitleaks report ~0 bytes scanned with exit 0) and scans either the whole
# history (MODE=full) or one commit range (MODE=diff with BASE..HEAD).
#
# Fails closed. Gitleaks exits 0 with "0 commits scanned" on an empty or
# invalid range (observed on v8.30.0), so the exit code alone is not trusted:
# the scan must cover exactly the commits git reports as scannable. Merge
# commits, merge-resolution commits, and --allow-empty commits carry no patch
# and Gitleaks does not count them, so the expected count is the number of
# non-merge commits that change at least one file (git diff-tree), not the raw
# rev-list count.
set -euo pipefail

mode="${MODE:-full}"
base="${BASE:-}"
head="${HEAD:-}"
image="${GITLEAKS_IMAGE:?GITLEAKS_IMAGE must be set}"
config="${GITLEAKS_CONFIG:-}"

scannable_commits() {
  # Counts non-merge commits that change at least one file.
  local count=0 commit
  while IFS= read -r commit; do
    if [[ -n "$(git diff-tree --no-commit-id --name-only -r --root "${commit}")" ]]; then
      count=$((count + 1))
    fi
  done < <(git rev-list --no-merges "$@")
  echo "${count}"
}

log_opts=()
case "${mode}" in
  diff)
    if [[ -z "${base}" || -z "${head}" ]]; then
      echo "::error::MODE=diff requires BASE and HEAD"
      exit 1
    fi
    if ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
      echo "::error::BASE ${base} does not resolve to a commit"
      exit 1
    fi
    if ! git cat-file -e "${head}^{commit}" 2>/dev/null; then
      echo "::error::HEAD ${head} does not resolve to a commit"
      exit 1
    fi
    log_opts=("--log-opts=${base}..${head}")
    expected="$(scannable_commits "${base}..${head}")"
    if [[ "${expected}" -eq 0 ]]; then
      echo "::error::diff range ${base}..${head} has no scannable commits; refusing an empty scan"
      exit 1
    fi
    ;;
  full)
    expected="$(scannable_commits HEAD)"
    ;;
  *)
    echo "::error::MODE must be 'diff' or 'full', got '${mode}'"
    exit 1
    ;;
esac

config_args=()
if [[ -n "${config}" ]]; then
  if [[ ! -f "${config}" ]]; then
    echo "::error::gitleaks-config path '${config}' does not exist in caller repository"
    exit 1
  fi
  echo "Using caller gitleaks config: ${config}"
  config_args+=(--config "/repo/${config}")
fi

output="$(mktemp)"
trap 'rm -f "${output}"' EXIT

set +e
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$PWD:/repo" \
  --workdir /repo \
  "${image}" git --no-banner --redact --exit-code=1 \
  ${log_opts[@]+"${log_opts[@]}"} \
  ${config_args[@]+"${config_args[@]}"} \
  /repo >"${output}" 2>&1
gitleaks_status=$?
set -e

cat "${output}"

scanned="$(grep -oE '[0-9]+ commits? scanned' "${output}" | grep -oE '[0-9]+' | tail -n 1 || true)"
if [[ -z "${scanned}" ]]; then
  echo "::error::could not read the gitleaks scan count; failing closed"
  exit 1
fi
if [[ "${scanned}" -ne "${expected}" ]]; then
  echo "::error::gitleaks scanned ${scanned} commits but git reports ${expected} scannable commits; failing closed"
  exit 1
fi

exit "${gitleaks_status}"
