# Contract Traceability

**Change ID:** removeStrandedV03XTags
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-16T02:19:41.039Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| SC1 | success_criterion | pass | review | v0.4.0 release id 339871391 targets fixed main 4606d05 and is highest semver; live docs/examples remediated to v0.4.0 SHA at checkpoint 22c8462. |
| SC2 | success_criterion | pass | review | No tags deleted/repointed except floating v0; consumer SHA pins still resolve. Existing consumer refs remain immutable; live examples now point to v0.4.0 SHA. |
| SC3 | success_criterion | pass | review | auto-release.yml now selects highest stable semver tag that is an ancestor of HEAD and skips existing computed tags; actionlint passed via adv_run_test. |
| SC4 | success_criterion | pass | review | docs/ci-standard.md documents highest-semver-ancestor behavior and v0.4.0 jump; README/docs/examples/ROADMAP pins updated to v0.4.0 SHA. |
| AC1 | acceptance_criterion | pass | test | v0.4.0 release id 339871391 targets fixed main 4606d05; highest semver is v0.4.0; tag is not broken v0.3.2/5afaf289. |
| AC2 | acceptance_criterion | not_applicable | test | Renovate next-evaluation event has not occurred during this session. In-repo preconditions are satisfied (v0.4.0 highest semver, docs/examples updated); empirical consumer observation is tracked as agenda ag-kuscC15R and not polled per no-polling policy. |
| AC3 | acceptance_criterion | pass | test | No immutable consumer SHAs were rewritten; v0.3.x tags left installable; exact old-pin search remediated only local docs/examples, not consumer repos. |
| AC4 | acceptance_criterion | pass | test | auto-release highest stable semver ancestor loop and idempotency guard present; actionlint pass; review remediation added stable-tag regex and strict version-bump shell mode. |
| AC5 | acceptance_criterion | pass | test | adv_run_test actionlint exit 0; adv_run_test ruleset invariant check exit 0; exact stale-pin check exit 0 after corrected rerun. |
| AC6 | acceptance_criterion | pass | test | docs/ci-standard.md release-line section documents v0.4.0 jump and highest-semver behavior; README/docs/examples/ROADMAP live references updated to v0.4.0. |
| C1 | constraint | respected | static_check | Ruleset invariant check passed: required context exactly Sharperflow CI Gate, no bypass actors, squash-only, strict checks off. self-test/ruleset semantics not weakened. |
| C2 | constraint | respected | static_check | v0.4.0 targets 4606d05 fixed main code, not v0.3.2/5afaf289. |
| C3 | constraint | respected | static_check | No history/commit rewrite; v0.3.x releases/tags left installable; added v0.4.0 and rolled floating v0 only. |
| C4 | constraint | respected | static_check | actionlint passed on modified auto-release.yml; no required status check bypass introduced. |
| C5 | constraint | respected | static_check | Recorded v0.4.0 release id 339871391, target 4606d05, prior v0 f365a1b, and remediation checkpoint 22c8462. |
| DONT1 | avoidance | respected | review | Existing SHA-pinned consumers still resolve; no consumer repo pins hand-edited; local examples now use v0.4.0 SHA. |
| DONT2 | avoidance | respected | review | Ruleset invariant check passed; Sharperflow CI Gate contract preserved. |
| DONT3 | avoidance | respected | review | No consumer pins were manually rewritten as retarget mechanism; only this repo docs/examples refreshed. Renovate retarget remains tracked by ag-kuscC15R. |
| DONT4 | avoidance | respected | review | v0.4.0 release and docs/examples point to 4606d05 fixed main, not the broken stranded v0.3.2 line. |
| OOS1 | out_of_scope | respected | not_applicable | v0.3.0/v0.3.1/v0.3.2 tags/releases were not deleted or yanked. |
| OOS2 | out_of_scope | respected | not_applicable | Security-gate scan behavior from fixOsvRemediation was not changed; code changes limited to auto-release version selection and docs/examples pins. |
| OOS3 | out_of_scope | respected | not_applicable | No manual consumer pin rewrites performed; local docs/examples only. |
| OOS4 | out_of_scope | respected | not_applicable | Dependabot security updates were not enabled by this change. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-c196c0c113fa | SC3, AC4 | AC4, AC5 | C1, C2, C4, DONT2 |  |
| tk-9962df2728db | SC4, AC6 | AC6 | C1, OOS2 |  |
| tk-f81352e285bf | SC1, AC1 | AC1 | C2, C3, C5, DONT4, OOS1 |  |
| tk-0f33b56269c4 |  | SC1, SC2, SC3, SC4, AC1, AC2, AC3, AC4, AC5, AC6 | C1, C2, C3, C4, C5, DONT1, DONT2, DONT3, DONT4, OOS1, OOS2, OOS3, OOS4 |  |
