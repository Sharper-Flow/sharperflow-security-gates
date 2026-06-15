# Repository Instructions

## What this repo is

- Source of truth for Sharper Flow app PR + CI/CD workflows, not just security scans: reusable workflows, shared setup composites, org branch-protection ruleset, Renovate preset, docs, and examples.
- No root app source or root package/test manifest. Do not invent `npm`/`pnpm`/`uv` test commands for this repo.
- Normative contract: `docs/ci-standard.md`. If prose conflicts with workflow/action/ruleset YAML or JSON, trust executable files and update docs.

## Verify changes

- Workflow syntax, same as CI:
  ```bash
  docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7
  ```
- Ruleset invariant check mirrors `.github/workflows/self-test.yml`: target `branch`, enforcement `active`, `bypass_actors: []`, required check exactly `Sharperflow CI Gate`, strict checks off, squash-only.
- Shell changes: run `shellcheck scripts/apply-ruleset.sh` when touching `scripts/apply-ruleset.sh`.
- CI file-existence checks include `README.md`, `docs/ci-standard.md`, `docs/pokeedge-backend-pilot.md`, all three reusable workflows, both setup composites, configs, ruleset JSON, and `scripts/apply-ruleset.sh`.

## CI standard contracts to preserve

- App pipeline shape: `setup → fast-checks → tests + coverage → build → security → summary`.
- Branch protection requires one exact check context: `Sharperflow CI Gate`. Do not rename it.
- The summary gate must always report (`if: ${{ !cancelled() }}` or equivalent) and fail on any `needs` result other than `success`/`skipped`.
- Do not put workflow-level `paths:` filters on workflows that emit `Sharperflow CI Gate`; path-filter jobs inside the workflow instead.
- Security gate must be a job in the same app CI workflow as the summary; separate pilot security workflows cannot feed `needs:`.
- Pin org `uses:` by full commit SHA plus trailing `# vX.Y.Z` comment. No floating tags/branches in examples or app guidance unless the standard explicitly changes.

## Repo surfaces

- Reusable gates:
  - `.github/workflows/python-security-gate.yml`: Semgrep+Bandit, OSV lockfile scan, Gitleaks, optional Trivy filesystem.
  - `.github/workflows/javascript-security-gate.yml`: Semgrep JS/TS, OSV lockfile scan, Gitleaks, optional Trivy filesystem.
  - `.github/workflows/container-security-gate.yml`: Trivy scan of a supplied image ref only; it does not build/publish images.
- Shared setup composites: `.github/actions/setup-python-uv` and `.github/actions/setup-bun-node`; apps consume them cross-repo, do not copy-paste setup steps.
- App examples live under `examples/pokeedge-*`; keep PokeEdge-specific wiring there until it is reusable.
- Org protection lives in `rulesets/sharperflow-app-protection.json` and `scripts/apply-ruleset.sh`. Applying it requires `admin:org` or org `Administration: write`; `GITHUB_TOKEN` is insufficient.
- Renovate preset is `default.json`; this repo's own `renovate.json` extends it locally.

## Gate behavior gotchas

- Source-code gates partition secrets to Gitleaks; Trivy filesystem scans use `vuln,misconfig`. Container gate Trivy uses `vuln,secret`.
- Missing `lockfile-path` skips OSV with a warning; it is not a gate failure.
- `bandit-config` is optional and only used if the caller path exists. `gitleaks-config` is optional but fails if a non-empty caller path does not exist.
- Trivy ignore files and Gitleaks config paths are resolved in the checked-out caller repository, not this repo.
- Defaults are intentionally high-signal: fail on high-confidence/high-severity findings, `HIGH,CRITICAL`, `ignore-unfixed`, no GHAS/CodeQL/SonarCloud/dashboard dependency.

## Branch protection / release posture

- Ruleset requires `Sharperflow CI Gate` only, strict up-to-date checks off, squash-only merges, no bypass actors, no required human review.
- Before applying squash-only ruleset to a target repo, verify that repo has `allow_squash_merge: true`; otherwise all merges block.
- Normal release path is tag-only: use `scripts/apply-ruleset.sh --no-release-bypass`. Bypass flags are escape hatches only for repos that must push release commits to `main`.
- PR branches should come from worktrees; keep shared trunk/main checkout on default branch.
