# Contract Traceability

**Change ID:** addSharperflowCiStandard
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-05T16:17:55.339Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | docs/ci-standard.md authored: pipeline shape, single 'Sharperflow CI Gate' summary contract, always-report rule, hardened summary snippet (!cancelled/leaf-needs/fail-on-failure+cancelled/skipped=Success), permanent+required security gate folded as workflow_call job, SHA+comment pin policy, org-ruleset protection+coexistence+auth, optional conventions, app-owned gates, conformance checklist. |
| AC2 | acceptance_criterion | pass | test | .github/actions/setup-python-uv/action.yml composite (inputs python-version/sync-args/cache-key-suffix); setup-python@SHA #v6, setup-uv@SHA #v7; actionlint PASS. |
| AC3 | acceptance_criterion | pass | test | .github/actions/setup-bun-node/action.yml composite (inputs node-version/bun-version/install-mode + invalid-mode guard); setup-bun@SHA #v2, setup-node@SHA #v6; actionlint PASS. |
| AC4 | acceptance_criterion | pass | test | rulesets/sharperflow-app-protection.json (active, bypass_actors[], ~DEFAULT_BRANCH, repository_name protected:true, pull_request review_count 0, required_status_checks strict + context 'Sharperflow CI Gate', non_fast_forward) — JSON assertions PASS; scripts/apply-ruleset.sh idempotent GET-by-name→PUT/POST + --dry-run, auth=admin:org/App documented — shellcheck PASS. |
| AC5 | acceptance_criterion | pass | test | README/ROADMAP/pokeedge-backend-pilot/pokeedge-web-next reframed permanent+required; examples converted to conformant ci.yml (security folded under summary, SHA-pinned, real actions/checkout@df4cb1c #v6); old pilot examples removed; floating-pin scan clean (only the prose rule mentions @v0/@main); reviewer-fixed ROADMAP link committed. |
| AC6 | acceptance_criterion | pass | test | self-test.yml extended: presence of ci-standard.md + both composites + ruleset + script, ruleset JSON validation, shellcheck job; checkout SHA-pinned. Local sweep: actionlint PASS, 13 presence PASS, ruleset JSON PASS, shellcheck PASS. |
| C1 | constraint | respected | static_check | No GHAS/Sonar/hosted-dashboard introduced; standard references only existing reusable gates (Semgrep/Bandit/OSV/Gitleaks/Trivy). |
| C2 | constraint | respected | static_check | Heartbeat/notify documented as optional in §7; no required per-app secrets added. |
| C3 | constraint | respected | static_check | App-owned gates (coverage, migration-chain, contract, complexity) explicitly excluded from the standard in 'App-owned gates' section. |
| C4 | constraint | respected | static_check | Composites take only generic inputs; no app-specific paths/assumptions baked in. |
| C5 | constraint | respected | static_check | Additive: existing python/javascript/container security-gate workflows unchanged; new composites/ruleset/docs do not alter consumer behavior. |
| C6 | constraint | respected | static_check | Reusable security job names documented as a frozen published contract in §3. |
| DONT1 | avoidance | respected | review | No monolithic single-reusable-CI-workflow mandated; standard ships a documented summary-job pattern + composites, apps keep repo-specific jobs. |
| DONT2 | avoidance | respected | review | apply-ruleset.sh header + ci-standard §6 require admin:org PAT / App Administration:write; explicitly state GITHUB_TOKEN insufficient. |
| DONT3 | avoidance | respected | review | All org uses: in examples/docs SHA-pinned with version comments; grep for @main/@v0 finds only the prose rule, no actual floating pins. |
| DONT4 | avoidance | respected | review | No app conformance implemented here; pokeedge change reframed as separate Change B (blocked on A); web is Change C. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-ca83cc5f2c19 | AC1 |  | C1, C3, DONT1, DONT2, DONT3 |  |
| tk-2b22fe2aae29 | AC2 | AC2 | C4 |  |
| tk-3e0650f7bb30 | AC3 | AC3 | C4 |  |
| tk-05deb73f9248 | AC4 | AC4 | DONT2 |  |
| tk-fd80791e92b9 | AC5 |  | DONT3 |  |
| tk-4827cbb4e065 | AC6 | AC2, AC3, AC4, AC6 |  |  |
