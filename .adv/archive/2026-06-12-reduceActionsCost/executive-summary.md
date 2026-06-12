# Executive Summary — Reduce Actions cost

## Outcome

The GitHub Actions cost cleanup moved from audit to validated implementation across the reusable gates repo plus explicitly approved direct PokeEdge and PokeEdge-Web target worktrees.

## What Changed

### sharperflow-security-gates

- Reusable Python and JavaScript SBOM Trivy steps now explicitly use `scanners: vuln,misconfig` so SBOM generation does not fall back to Trivy's `vuln,secret` default.
- All reusable SBOM artifact uploads now set `retention-days: 14`.
- Documentation/examples now reflect current scanner partition and verified `v0.3.2` pin.
- `docs/actions-cost-cleanup-dry-run.md` records cache cleanup candidates and destructive deletion boundaries.

### PokeEdge

- Draft PRs skip the heavyweight `PR Gate (unit + api + arch)` job.
- `coverage-fast` artifact retention is reduced to 7 days.
- Auto-triggered production deploys skip redundant `verify-staging` polling while manual deploy safety remains.

### PokeEdge-Web

- Unused coverage artifact upload removed.
- `ci-quality` now uses the cached Bun composite.
- Pinned `oasdiff` binary is cached.
- BuildKit cache export mode changed from `max` to `min` in staging/production deploy workflows.
- Renovate semantic-commit config added to reduce commit-lint churn.

## Verification

- Local exact `actionlint` passed.
- PokeEdge structural `actionlint` passed and `git diff --check` passed.
- PokeEdge-Web structural `actionlint` passed, `git diff --check` passed, and `renovate.json` syntax validation passed.
- Contract matrix has 16/16 pass/respected rows and 0 failing rows.
- Independent review verdict: READY.

## Remaining Boundaries

- No cache/artifact deletion was performed; deletion remains approval-gated after dry-run evidence.
- PokeEdge and PokeEdge-Web changes are local branch commits and still need push/PR/release integration.
- Target repos still have pre-existing shellcheck style/info noise in full actionlint; changed workflow files passed structural validation.
