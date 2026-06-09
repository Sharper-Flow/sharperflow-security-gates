# Contract Traceability

**Change ID:** optimizeCiTestActions
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-09T04:39:34.207Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | PokeEdge PR #356: changes job outputs code, tests, migrations, openapi. Integration/E2E/acceptance/contract-live skip on workflow-only change. CI confirms 6 jobs skipped. |
| AC2 | acceptance_criterion | pass | test | PokeEdge PR #356: 4 jobs (integration, e2e, acceptance, contract-live) have draft PR check in if: clause. Pattern: (github.event_name != 'pull_request' || !github.event.pull_request.draft) |
| AC3 | acceptance_criterion | pass | test | sharperflow-security-gates PR #16: actions/cache@v5.0.5 added to setup-bun-node, keyed on bun.lock, skipped on install-mode=none. Actionlint clean. |
| AC4 | acceptance_criterion | pass | test | PokeEdge-Web PR #134: fast-checks replaced with parallel lint (1m3s) + typecheck (51s). CI confirms both run in parallel. |
| AC5 | acceptance_criterion | pass | test | PokeEdge-Web PR #134: integration E2E skipped on workflow-only change (tests output false). CI confirms skipping. |
| AC6 | acceptance_criterion | pass | test | All 3 PRs pass actionlint. sharperflow-security-gates CI: actionlint pass, shellcheck pass, docs/config checks pass. |
| AC7 | acceptance_criterion | pass | test | PokeEdge PR #356: Sharperflow CI Gate pass (required check reports terminal). PokeEdge-Web PR #134: ci-gate pending (waiting for unit tests). No behavior change to required status check. |
| C1 | constraint | respected | static_check | No merge-queue or ruleset changes. merge_group override pattern preserved. |
| C2 | constraint | respected | static_check | Sharperflow CI Gate remains sole required check. Summary job still checks all leaf jobs. |
| C3 | constraint | respected | static_check | Path-scope outputs default true for merge_group via ternary pattern. |
| C4 | constraint | respected | static_check | setup-bun-node composite change is additive (new cache step). No input changes. Backward-compatible. |
| C5 | constraint | respected | static_check | actions/cache@27d5ce7 (v5.0.5) SHA-pinned with version comment. |
| DONT1 | avoidance | respected | review | PokeEdge pr-gate monolithic test job NOT split. |
| DONT2 | avoidance | respected | review | Security jobs unchanged. |
| DONT3 | avoidance | respected | review | ci-quality.yml not modified. |
| DONT4 | avoidance | respected | review | No workflow_dispatch triggers added. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-6645ae75f53a | AC1 | AC6, AC7 | C1, C2, C3, C5 |  |
| tk-0e12630ee89f | AC3 | AC6 | C3, C5 |  |
| tk-805fda947d80 | AC2 | AC6, AC7 | C1, C2 |  |
| tk-63da8231f23b | AC4 | AC6, AC7 | C1, C2, C5 |  |
| tk-64fea8278baf | AC5 | AC6, AC7 | C1, C2 |  |
