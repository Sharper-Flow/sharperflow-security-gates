# Contract Traceability

**Change ID:** pruneUnusedCiWorkflows
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-09T03:29:50.810Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | PokeEdge PR #354 deletes all 4 files (opencode.yml, pr_agent.yml, ops-audit.yml, nightly-merge-gate.yml) — verified via PR files API (pure deletions) + branch commits a121c725←0d3a25dd←d936d5a4←8e3dfa67. Squash auto-merge armed; main-removal completes on green Sharperflow CI Gate. |
| AC2 | acceptance_criterion | pass | test | Copilot coding agent: org has 0 Copilot seats (seat_management_setting=unconfigured) → already inert/non-invokable. User decided LEAVE (org-wide-only disable disproportionate for nil benefit). Documented in ci-standard hygiene rule. AC2 satisfied as already-effectively-disabled + documented. |
| AC3 | acceptance_criterion | pass | test | Ghost records codecov-ai (id 211279246) + compose.ci.override (id 269689657) confirmed state=disabled_manually with files already deleted from main. GitHub has no workflow-record delete API → terminal dormant, ages out. Documented (the not-unregisterable-with-reason branch of AC3). |
| AC4 | acceptance_criterion | pass | test | Required status checks = ['Sharperflow CI Gate'] only on both PokeEdge + PokeEdge-Web (ruleset 17335746, verified live). No active workflow references the 4 deleted files (design D1 grep). Contract untouched. |
| AC5 | acceptance_criterion | pass | test | ops-audit (daily 05:30 Azure OIDC audit of RG PokeEdge + log-pokeedge-prod: migration drift + sync-job health) and nightly-merge-gate (04:00 T3 perf/fuzz/Bicep + notify) purpose captured in agreement + design + PR #354 body before deletion. Git-revert recovery noted. |
| AC6 | acceptance_criterion | pass | test | docs/ci-standard.md gained '### Workflow hygiene' subsection (commit ca68982): delete disabled workflow files (git-recover); managed scan features (Code Quality/CodeQL/Copilot coding agent) off unless adopted; ghost records harmless/age out. |
| C1 | constraint | respected | static_check | Sharperflow CI Gate frozen required-check untouched — still sole required context both repos. |
| C2 | constraint | respected | static_check | No load-bearing active workflow removed/altered. KEEP set (dependency-review, ci/ci-quality, Dependabot dynamic, deploys/releases/contract) untouched. Only dead-experiment + user-approved failing-disabled-infra files removed. |
| C3 | constraint | respected | static_check | All deletions via squash PR #354 (git-recoverable). Copilot left unchanged (no irreversible action). Doc edit revertable. |
| DONT1 | avoidance | respected | review | Did not attempt to delete ghost-record files (they don't exist) — only confirmed their terminal disabled state. |
| DONT2 | avoidance | respected | review | Scope held to PokeEdge + PokeEdge-Web. Survey confirmed other repos (Corded=1, flowcalc=2) trivial/out-of-standard — not touched. |
| DONT3 | avoidance | respected | review | ops-audit + nightly-merge-gate capability/purpose recorded in agreement, design, and PR body BEFORE deletion. Git history + ADV archive preserve the definitions. Not silently dropped. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-68b53021314a | AC6 |  | C1 |  |
| tk-26d34ee4288e | AC1, AC5 |  | C2, C3, DONT3 |  |
| tk-a1a6355d7b80 | AC2 |  | C3 |  |
| tk-cc58b0497096 | AC3, AC4 |  | C1, C2, DONT1 |  |
