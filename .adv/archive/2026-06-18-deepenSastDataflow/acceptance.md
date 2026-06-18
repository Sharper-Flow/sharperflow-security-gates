# Acceptance

Reviewed at: 2026-06-18T06:07:30.000Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| SC1 | success_criterion | Sharper Flow has explicit post-CodeQL dataflow/taint SAST posture. | pass | docs/ci-standard.md now states selected posture: packaged Semgrep CE FastAPI taint rules; README and backend pilot updated. Reviewer verdict READY. |
| SC2 | success_criterion | Consumers can tell what gate catches, and what remains uncovered. | pass | docs/ci-standard.md and README state intraprocedural CE scope and cross-file/interprocedural taint remains uncovered; Opengrep advisory/revisit. |
| SC3 | success_criterion | Any added blocking SAST stays high-signal and adds ≤3 minutes CI runtime. | pass | Semgrep rule test duration 2.820s in latest verification tr_mqj3k774; earlier full verification 1.872s tr_mqj384ju. Both <180s. |
| AC1 | acceptance_criterion | `docs/ci-standard.md` replaces the deferred `deepenSastDataflow` note with the selected posture and cross-file/interprocedural coverage truth. | pass | Static docs check tr_mqj36ph1/tr_mqj3834o passed; docs/ci-standard.md replaces deferred row with decided posture and coverage truth. |
| AC2 | acceptance_criterion | If blocking SAST is added, default Semgrep coverage remains active and new coverage is additive. If blocking SAST is not added, docs explicitly state no added blocking SAST. | pass | Workflow static checks tr_mqj34m5y/tr_mqj3k51k passed: default `p/python p/fastapi` remains; `semgrep-additional-configs` defaults to packaged rule path; Semgrep configs are additive. |
| AC3 | acceptance_criterion | Any new blocking SAST path has measured or documented expected added runtime ≤180 seconds. | pass | Semgrep rule tests passed 2/2 in 2.820s (tr_mqj3k774), below 180s. No new scanner process beyond existing Semgrep job; added config only. |
| AC4 | acceptance_criterion | No GHAS, CodeQL, SARIF upload, SonarCloud, hosted dashboard, or second required check is introduced. | pass | actionlint passed tr_mqj3k5k5; forbidden executable-surface scan tr_mqj38bjo found no CodeQL/SARIF/Sonar/GHAS terms in changed executable surfaces; no new check/job outside existing security job. |
| AC5 | acceptance_criterion | Design records the first FastAPI source→sink priority decision; user delegated this choice to design. If no rule implementation is selected, design records why. | pass | Design KD2 records first source→sink priority: direct FastAPI request input to process execution and outbound network/SSRF sinks. Implemented in configs/semgrep/python/fastapi-taint.yml and tests pass 2/2. |
| C1 | constraint | Preserve the exact single required check context: `Sharperflow CI Gate`. | respected | No branch-protection or summary check context changed; actionlint passed. Existing `Sharperflow CI Gate` contract untouched. |
| C2 | constraint | Do not require GitHub Advanced Security, GitHub Code Security, CodeQL, SARIF upload, SonarCloud, or hosted dashboards. | respected | Changed executable surfaces contain no CodeQL/SARIF/Sonar/GHAS additions (tr_mqj38bjo). Docs keep no-hosted-dashboard posture. |
| C3 | constraint | Keep new blocking scanner behavior high-signal by default; fail only on confident findings. | respected | Rules are severity ERROR, metadata confidence HIGH, narrow direct FastAPI request input to process/network sinks; Semgrep tests include safe ok cases. |
| C4 | constraint | Keep any added blocking SAST runtime within ≤180 seconds expected added CI time. | respected | Latest Semgrep rule-test runtime 2.820s (tr_mqj3k774) <180s. |
| C5 | constraint | Preserve default Semgrep registry coverage (`p/python p/fastapi`) if adding repo-owned Semgrep rules. | respected | python-security-gate.yml keeps `semgrep-configs` default `p/python p/fastapi` and adds separate `semgrep-additional-configs`; static checks passed. |
| C6 | constraint | Keep the security gate as a job in the same app CI workflow as the summary gate. | respected | Only `.github/workflows/python-security-gate.yml` changed inside existing reusable security job; no app workflow topology or summary requirements changed. |
| DONT1 | avoidance | Do not claim full cross-file/interprocedural taint coverage unless the selected OSS path demonstrably provides it in this repo's CI shape. | respected | Rule messages and docs explicitly say Semgrep CE tracks intraprocedurally only and does not claim cross-function/cross-file coverage. |
| DONT2 | avoidance | Do not make Opengrep a required blocking gate during this change unless design finds stronger current proof than discovery found. | respected | No Opengrep workflow/config added. Docs say Opengrep remains advisory/revisit. |
| DONT3 | avoidance | Do not add app-level duplicated generic scanner jobs for coverage already owned by the reusable gate. | respected | No app-level scanner jobs added. Coverage ships inside reusable Python gate as packaged additive Semgrep config. |
| DONT4 | avoidance | Do not introduce a second branch-protection required check. | respected | No second job/check context added; existing `Semgrep + Bandit` job remains within reusable workflow and app summary unchanged. |
| DONT5 | avoidance | Do not revive CodeQL/GHAS/SARIF/SonarCloud as the answer to this gap. | respected | No CodeQL/GHAS/SARIF/SonarCloud workflow or dependency introduced; docs continue rejecting them as the answer to this gap. |

