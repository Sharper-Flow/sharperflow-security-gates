# Acceptance

Reviewed at: 2026-06-09T04:39:34.207Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | **PokeEdge `pr-gate.yml`** has additional path-scope outputs beyond `code`: at minimum `tests` (unit/API/E2E tests), `migrations` (integration/migration jobs), `openapi` (contract-gate/contract-live). Jobs that only need a subset are gated on their specific output. | pass | PokeEdge PR #356: changes job outputs code, tests, migrations, openapi. Integration/E2E/acceptance/contract-live skip on workflow-only change. CI confirms 6 jobs skipped. |
| AC2 | acceptance_criterion | **PokeEdge `pr-gate.yml`** integration, E2E, acceptance, and contract-live jobs skip on `github.event.pull_request.draft == true`. | pass | PokeEdge PR #356: 4 jobs (integration, e2e, acceptance, contract-live) have draft PR check in if: clause. Pattern: (github.event_name != 'pull_request' || !github.event.pull_request.draft) |
| AC3 | acceptance_criterion | **`setup-bun-node` composite action** (this repo) caches `node_modules` using `actions/cache` keyed on `bun.lock` hash. New `install-mode: none` continues to work without cache. | pass | sharperflow-security-gates PR #16: actions/cache@v5.0.5 added to setup-bun-node, keyed on bun.lock, skipped on install-mode=none. Actionlint clean. |
| AC4 | acceptance_criterion | **PokeEdge-Web `ci.yml`** fast-checks split into at least 2 parallel jobs (format+lint | typecheck) or 3 (format | lint | typecheck) with shared changes dependency. | pass | PokeEdge-Web PR #134: fast-checks replaced with parallel lint (1m3s) + typecheck (51s). CI confirms both run in parallel. |
| AC5 | acceptance_criterion | **PokeEdge-Web `ci.yml`** integration E2E gated on `tests/` or `src/` path changes. | pass | PokeEdge-Web PR #134: integration E2E skipped on workflow-only change (tests output false). CI confirms skipping. |
| AC6 | acceptance_criterion | All changes pass `actionlint` validation. | pass | All 3 PRs pass actionlint. sharperflow-security-gates CI: actionlint pass, shellcheck pass, docs/config checks pass. |
| AC7 | acceptance_criterion | No required status check behavior changes — `Sharperflow CI Gate` still reports terminal result on every PR/push. | pass | PokeEdge PR #356: Sharperflow CI Gate pass (required check reports terminal). PokeEdge-Web PR #134: ci-gate pending (waiting for unit tests). No behavior change to required status check. |
| C1 | constraint | No change to the merge-queue trigger or ruleset 17335746 | respected | No merge-queue or ruleset changes. merge_group override pattern preserved. |
| C2 | constraint | `Sharperflow CI Gate` must remain the sole required check | respected | Sharperflow CI Gate remains sole required check. Summary job still checks all leaf jobs. |
| C3 | constraint | Path-scope outputs must default `true` for merge_group events (same as current `code` output) | respected | Path-scope outputs default true for merge_group via ternary pattern. |
| C4 | constraint | Composite action changes must be backward-compatible (existing callers unaffected) | respected | setup-bun-node composite change is additive (new cache step). No input changes. Backward-compatible. |
| C5 | constraint | SHA-pin all new action references with version comments | respected | actions/cache@27d5ce7 (v5.0.5) SHA-pinned with version comment. |
| DONT1 | avoidance | Do not split the PokeEdge pr-gate monolithic test job into sub-jobs (setup overhead may negate savings) | respected | PokeEdge pr-gate monolithic test job NOT split. |
| DONT2 | avoidance | Do not remove or gate security jobs (they're already fast and reusable-gate-controlled) | respected | Security jobs unchanged. |
| DONT3 | avoidance | Do not change `ci-quality.yml` (Lighthouse is already non-blocking and infrequent) | respected | ci-quality.yml not modified. |
| DONT4 | avoidance | Do not add `workflow_dispatch` triggers for manual test runs | respected | No workflow_dispatch triggers added. |

