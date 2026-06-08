# Archive: Fix merge collision strategy

**Change ID:** fixMergeCollisionStrategy
**Archived:** 2026-06-08T21:28:25.671Z
**Created:** 2026-06-08T19:14:37.759Z

## Tasks Completed

- ✅ Edit org ruleset JSON: strict-off + squash-only
  > Task checkpoint completed
- ✅ Update self-test.yml ruleset-JSON assertions
  > Task checkpoint completed
- ✅ Amend ci-standard.md §6 (branch protection) + add Tier-3 escalation playbook
  > Task checkpoint completed
- ✅ Amend ci-standard.md §Dependency-updates: Renovate-OR-Dependabot equal path
  > Task checkpoint completed
- ✅ Add canonical cross-repo OpenAPI contract-gate section to ci-standard.md + refresh examples
  > Task checkpoint completed
- ✅ Audit PokeEdge-Web contract-sync conformance to documented standard
  > Task checkpoint completed
- ✅ Update README.md pointers for changed standard sections
  > Task checkpoint completed
- ✅ Run self-test suite locally (actionlint + ruleset JSON + docs/config + shellcheck)
  > Task checkpoint completed
- ✅ PRE-APPLY GUARD: verify/normalize repo merge settings before ruleset apply
  > Task checkpoint completed
- ✅ Apply org ruleset (dry-run preview → apply)
  > Task checkpoint completed
- ✅ Fix PokeEdge live drift: remove stale sonarcloud.yml + confirm Dependabot conformance
  > Task checkpoint completed
- ✅ Live post-apply verification (both repos + ruleset)
  > Task checkpoint completed

## Specs Modified


## Wisdom Accumulated

- **[gotcha]** Discovery: examples/ in sharperflow-security-gates are STALE vs live caller CI. Example ci.yml files lack merge_group: triggers, but live PokeEdge-Web ci.yml HAS merge_group: (line 23) plus existing cross-repo OpenAPI drift detection ("Generated API Drift Check", "Backend Contract Sync Check (PR)"). So Tier 2 (oasdiff contract gate) is NOT greenfield on the web side — there is existing contract-sync machinery to standardize/build on. PokeEdge backend ci.yml not at .github/workflows/ci.yml (likely pr-gate.yml per source ticket) — locate before scoping backend changes. merge_group: triggers are now dead weight (native merge queue impossible on Team+private) but harmless.
- **[gotcha]** DISCOVERY reshapes proposal scope (proposal was built on stale source tickets). Backend PokeEdge is far more built-out than tickets implied: (1) oasdiff contract gate ALREADY SHIPPED — archived change ciContractGateRunContractTests (2026-05-10) added contract-gate job in pr-gate.yml running check-api-compat.yml (oasdiff: backend openapi.json vs frontend's committed docs/openapi.json baseline) + bin/oc-test contract, path-filtered on openapi.json, already required in branch protection. So Tier 2 (oasdiff) is NOT greenfield — org-wide work = promote existing backend pattern into ci-standard.md + replicate to other repos. (2) Backend pr-gate.yml already has merge_group: + Sharperflow CI Gate summary. (3) Backend auto-merge.yml uses Dependabot[bot] with --auto --squash (so backend STILL runs Dependabot despite adoptRenovateOrgWide claiming removal — drift). (4) sonarcloud.yml still present on backend despite retireSonarcloud archived — drift. Root collision cause confirmed unchanged: org ruleset strict_required_status_checks_policy=true. Real change = Tier1 strict-off+squash-only+auto-merge (the actual fix) + standardize-existing-oasdiff (Tier2) + reconcile standard for Dependabot-equal-path (user reversal of adoptRenovateOrgWide one-updater rule) + flag live drift (dependabot still running, sonarcloud still present).
- **[convention]** oasdiff VALIDATED as org-standard OpenAPI breaking-change gate (user approved on merits, not faith). Apache-2.0 Go CLI, actively maintained (v1.18.5 2026-06-08), 1M+ docker pulls, de-facto standard; main rival Optic archived Jan 2026. Gate via `--fail-on ERR` (high-signal first, matches repo's fail-on-high-signal posture). CORRECTNESS GOTCHA: use CLI (as PokeEdge check-api-compat.yml already does) or the NEW oasdiff/oasdiff-action — NEVER the deprecated Tufin/oasdiff-action. Version-pin + Renovate-bump. Complements (not replacements): Spectral (design lint), Schemathesis (runtime contract test). No better fit for a small FastAPI+frontend shop. Design must use CLI/new-action only.
- **[gotcha]** GitHub ruleset mechanics (validator-corrected): (1) `non_fast_forward` rule ONLY blocks force-pushes — it does NOT forbid merge commits. The merge-commit blocker is `required_linear_history` (a DIFFERENT rule). So squash-only enforcement comes SOLELY from pull_request rule param `allowed_merge_methods:["squash"]` (org-level since GH changelog 2024-12-04), which excludes both merge-commit AND rebase. (2) HARD HAZARD: a squash-only ruleset against a repo with allow_squash_merge=false = empty merge-method intersection = ALL merges hard-block ("Merge methods set on the repository that conflict with the merge method rule will prevent merging"). MUST verify allow_squash_merge=true on every targeted repo BEFORE applying — pre-apply guard, not cosmetic. apply-ruleset.sh --no-release-bypass passes ruleset JSON verbatim as PUT --input (allowed_merge_methods safe, not stripped).
