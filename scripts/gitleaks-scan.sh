#!/usr/bin/env bash
# Gitleaks gate wrapper for the Sharperflow security gates.
#
# Runs the Gitleaks container as the runner uid (a container-uid mismatch makes
# Gitleaks report ~0 bytes scanned with exit 0) and scans either the whole
# history of all refs (MODE=full; Gitleaks' default population is
# git log --full-history --all) or one commit range (MODE=diff with
# BASE..HEAD).
#
# Fails closed. Gitleaks exits 0 with "0 commits scanned" on an empty or
# invalid range (observed on v8.30.0), so the exit code alone is not trusted:
# the scan must cover exactly the commits that yield scanner fragments, not
# every changed-file commit. The pinned scanner counts text hunks in surviving
# files, even removal-only hunks; binary archives yield none at default depth 0.
set -euo pipefail

mode="${MODE:-full}"
base="${BASE:-}"
head="${HEAD:-}"
image="${GITLEAKS_IMAGE:?GITLEAKS_IMAGE must be set}"
config="${GITLEAKS_CONFIG:-}"

scannable_commits() {
  # Parse patch structure, not added-line counts: a surviving file can yield an
  # empty addition fragment. Patch bodies stay in the pipe, never in gate logs.
  git log -p -U0 --format='commit %H' --no-merges "$@" | awk '
    /^commit [0-9a-f]+$/ { count += scannable; scannable = 0 }
    /^diff --git / { deleted = 0 }
    /^\+\+\+ \/dev\/null$/ { deleted = 1 }
    /^@@ / && !deleted { scannable = 1 }
    END { print count + scannable }
  '
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
    # Full mode must count the same all-ref population Gitleaks scans by
    # default, not only commits reachable from HEAD.
    expected="$(scannable_commits --full-history --all --diff-filter=tuxdb)"
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
