# Repository Instructions

## What this repo is

- Reusable GitHub Actions security gates for Sharper Flow repos; current target is Python/FastAPI repos, especially PokeEdge backend.
- There is no application source or package manifest here. The product is the reusable workflow YAML under `.github/workflows/`, plus baseline configs/docs/examples.

## Verify changes

- Run the same workflow lint as CI:
  ```bash
  docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7
  ```
- CI also requires these files to exist: `README.md`, `docs/pokeedge-backend-pilot.md`, both reusable workflows, and configs under `configs/python/`, `configs/gitleaks/`, `configs/trivy/`.
- There is no npm/pnpm/uv test command in this repo; do not invent one.

## Workflow boundaries

- `python-security-gate.yml` is a reusable `workflow_call` with four jobs: Semgrep+Bandit, OSV lockfile scan, Gitleaks, and optional Trivy filesystem scan.
- Python gate defaults are intentionally high-signal: Python `3.13`, scan path `.`, lockfile `uv.lock`, Semgrep `p/python p/fastapi`, exclude `tests scripts migrations`, Trivy `HIGH,CRITICAL`, `ignore-unfixed`.
- `container-security-gate.yml` only scans a supplied image ref with Trivy `vuln,secret`; it does not build or publish images.
- PokeEdge-specific workflow wiring belongs in `examples/pokeedge-python/` until proven reusable.

## Config gotchas

- `configs/trivy/trivy.yaml` is for local experiments; the reusable workflows keep gate behavior in YAML inputs instead of reading that file.
- `bandit-config` is optional and checked with `-f` in the checked-out caller workspace; callers must pass a path that exists in their repo.
- The Python gate skips OSV with a warning when `lockfile-path` is missing; it does not fail on absent lockfiles.
- The Gitleaks job runs the pinned container image directly with `detect --source=/repo --redact --exit-code=1`; this workflow does not pass `configs/gitleaks/gitleaks.toml`.

## Design posture to preserve

- Fail only on high-signal issues by default; avoid noisy required gates until false positives, suppressions, runtime, and failure modes are understood.
- Do not add assumptions that require GitHub Advanced Security, CodeQL/SARIF upload, SonarCloud, or a hosted dashboard.
