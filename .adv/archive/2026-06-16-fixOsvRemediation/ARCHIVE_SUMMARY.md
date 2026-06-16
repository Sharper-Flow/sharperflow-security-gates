# Archive: Fix OSV remediation

**Change ID:** fixOsvRemediation
**Archived:** 2026-06-16T00:27:59.561Z
**Created:** 2026-06-15T21:16:00.562Z

## Tasks Completed

- ✅ Evaluate stable Renovate vulnerability-alert baseline in default.json
  > Updated `default.json` to keep stable GitHub `vulnerabilityAlerts` baseline while removing redundant per-alert `minimumReleaseAge`. Verified config with Renovate validator.
- ✅ Improve OSV scanner failure visibility in reusable gates
  > Updated Python and JavaScript reusable security gates to write `$GITHUB_STEP_SUMMARY` guidance with local reproduction command while keeping OSV scanner output as terminal-friendly `--format=table`. Kept OSV action fail semantics and missing-lockfile warning/skip behavior unchanged; added `set -euo pipefail` in help steps.
- ✅ Verify PokeEdge and PokeEdge-Web remediation prerequisites and follow-ups
  > Ran GitHub API/PR checks for PokeEdge and PokeEdge-Web. No repo files changed. Confirmed PokeEdge-Web has a functional prerequisite gap (alerts disabled) and stale gate pin update pending; PokeEdge has alerts enabled but no relevant security remediation PR open.
- ✅ Document Renovate security-remediation behavior and rapid-dev consumer paths
  > Added `Renovate security remediation` and `OSV dependency-gate remediation` sections to `docs/ci-standard.md`, including caller prerequisites, `security` label expectation, default-off `osvVulnerabilityAlerts` rationale, local OSV reproduction commands for `uv.lock` and `bun.lock`, direct/transitive fallback guidance, and consumer-specific PokeEdge/PokeEdge-Web matrix.
- ✅ Run full verification for Renovate config, workflows, and contract coverage
  > Final verification plus review remediation. Updated workflow help text and docs to address review issues; committed checkpoint 9f1eef36. Validators passed after remediation.

## Specs Modified


## Wisdom Accumulated

- **[gotcha]** For Renovate `vulnerabilityAlerts`, shared preset consumption is not enough: caller repo GitHub vulnerability alerts must be enabled. `gh api -i /repos/{owner}/{repo}/vulnerability-alerts` returns HTTP 204 when enabled and 404 with `Vulnerability alerts are disabled.` when not. Treat disabled alerts as a functional remediation gap, not hygiene.
- **[pattern]** For reusable security-gate docs, pair Renovate remediation timing with OSV local reproduction commands by ecosystem (`uv.lock`, `bun.lock`) and a direct-vs-transitive limitation note. This prevents callers from interpreting a strict OSV failure as a weakened gate or as a guaranteed automatic Renovate PR for every lockfile-only transitive vulnerability.
