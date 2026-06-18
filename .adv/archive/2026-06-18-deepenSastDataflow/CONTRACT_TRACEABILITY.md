# Contract Traceability

**Change ID:** deepenSastDataflow
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-18T06:07:30.000Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| SC1 | success_criterion | pass | review | docs/ci-standard.md now states selected posture: packaged Semgrep CE FastAPI taint rules; README and backend pilot updated. Reviewer verdict READY. |
| SC2 | success_criterion | pass | review | docs/ci-standard.md and README state intraprocedural CE scope and cross-file/interprocedural taint remains uncovered; Opengrep advisory/revisit. |
| SC3 | success_criterion | pass | review | Semgrep rule test duration 2.820s in latest verification tr_mqj3k774; earlier full verification 1.872s tr_mqj384ju. Both <180s. |
| AC1 | acceptance_criterion | pass | test | Static docs check tr_mqj36ph1/tr_mqj3834o passed; docs/ci-standard.md replaces deferred row with decided posture and coverage truth. |
| AC2 | acceptance_criterion | pass | test | Workflow static checks tr_mqj34m5y/tr_mqj3k51k passed: default `p/python p/fastapi` remains; `semgrep-additional-configs` defaults to packaged rule path; Semgrep configs are additive. |
| AC3 | acceptance_criterion | pass | test | Semgrep rule tests passed 2/2 in 2.820s (tr_mqj3k774), below 180s. No new scanner process beyond existing Semgrep job; added config only. |
| AC4 | acceptance_criterion | pass | test | actionlint passed tr_mqj3k5k5; forbidden executable-surface scan tr_mqj38bjo found no CodeQL/SARIF/Sonar/GHAS terms in changed executable surfaces; no new check/job outside existing security job. |
| AC5 | acceptance_criterion | pass | test | Design KD2 records first source→sink priority: direct FastAPI request input to process execution and outbound network/SSRF sinks. Implemented in configs/semgrep/python/fastapi-taint.yml and tests pass 2/2. |
| C1 | constraint | respected | static_check | No branch-protection or summary check context changed; actionlint passed. Existing `Sharperflow CI Gate` contract untouched. |
| C2 | constraint | respected | static_check | Changed executable surfaces contain no CodeQL/SARIF/Sonar/GHAS additions (tr_mqj38bjo). Docs keep no-hosted-dashboard posture. |
| C3 | constraint | respected | static_check | Rules are severity ERROR, metadata confidence HIGH, narrow direct FastAPI request input to process/network sinks; Semgrep tests include safe ok cases. |
| C4 | constraint | respected | static_check | Latest Semgrep rule-test runtime 2.820s (tr_mqj3k774) <180s. |
| C5 | constraint | respected | static_check | python-security-gate.yml keeps `semgrep-configs` default `p/python p/fastapi` and adds separate `semgrep-additional-configs`; static checks passed. |
| C6 | constraint | respected | static_check | Only `.github/workflows/python-security-gate.yml` changed inside existing reusable security job; no app workflow topology or summary requirements changed. |
| DONT1 | avoidance | respected | review | Rule messages and docs explicitly say Semgrep CE tracks intraprocedurally only and does not claim cross-function/cross-file coverage. |
| DONT2 | avoidance | respected | review | No Opengrep workflow/config added. Docs say Opengrep remains advisory/revisit. |
| DONT3 | avoidance | respected | review | No app-level scanner jobs added. Coverage ships inside reusable Python gate as packaged additive Semgrep config. |
| DONT4 | avoidance | respected | review | No second job/check context added; existing `Semgrep + Bandit` job remains within reusable workflow and app summary unchanged. |
| DONT5 | avoidance | respected | review | No CodeQL/GHAS/SARIF/SonarCloud workflow or dependency introduced; docs continue rejecting them as the answer to this gap. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-1daaa4d1645b | AC2, AC5 | AC5 | C2, C3, C4, C5, DONT1, DONT5 |  |
| tk-ee0c85444c8d | AC2 | AC2, AC4 | C1, C2, C5, C6, DONT3, DONT4, DONT5 |  |
| tk-8683301bc272 | SC1, SC2, AC1 | AC1 | C1, C2, DONT1, DONT2, DONT4, DONT5 |  |
| tk-22b85e541760 |  | SC1, SC2, SC3, AC1, AC2, AC3, AC4, AC5, C1, C2, C3, C4, C5, C6, DONT1, DONT2, DONT3, DONT4, DONT5 | C1, C2, C3, C4, C5, C6, DONT1, DONT2, DONT3, DONT4, DONT5 |  |
