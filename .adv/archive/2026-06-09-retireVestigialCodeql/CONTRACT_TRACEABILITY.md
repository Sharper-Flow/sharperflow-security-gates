# Contract Traceability

**Change ID:** retireVestigialCodeql
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-09T02:48:34.468Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | docs/ci-standard.md § Code quality beyond the security gate now has an explicit CodeQL-retired block (commit ed4d601) accurately distinguishing GitHub Code Quality (preview/hosted-dashboard/bills-at-GA/CLI-disablable) from security CodeQL/code-scanning (GHAS-gated 403). Forward-links deepenSastDataflow (line 664). SonarCloud paragraph + followup table intact. |
| AC2 | acceptance_criterion | pass | test | PokeEdge Code Quality disabled: gh api PATCH code-quality/setup state=not-configured → GET confirms state=not-configured. Orphan .github/codeql/codeql-config.yml deleted via PR #353 (MERGED) → 404 on main. No CodeQL runs after ~02:45Z cutover (last run 01:59Z). |
| AC3 | acceptance_criterion | pass | test | PokeEdge-Web confirmed CodeQL-free: code-quality/setup state=not-configured; zero CodeQL workflow runs in history; no .github/codeql config (404). |
| AC4 | acceptance_criterion | pass | test | Org ruleset 17335746 required_status_checks = ['Sharperflow CI Gate'] only, for both PokeEdge and PokeEdge-Web (verified live post-change). dynamic/github-code-scanning/codeql never a required context. |
| AC5 | acceptance_criterion | pass | test | deepenSastDataflow followup change opened (parent_change_id=retireVestigialCodeql, origin triage), framing a/b/c decision; linked from ci-standard.md followup table. Parked at proposal-pending. |
| C1 | constraint | respected | static_check | No GHAS/Code Security purchase, no SARIF, no dashboard, no Sonar introduced. Disable used the free code-quality API; security Code Security remains Enable (off) per screenshot. |
| C2 | constraint | respected | static_check | Sharperflow CI Gate frozen required-check unchanged — still sole required context both repos (ruleset 17335746). |
| C3 | constraint | respected | static_check | All steps reversible: Code Quality re-enable via state=configured; PR #353 revertable; doc revert. No irreversible action taken. |
| C4 | constraint | respected | static_check | dynamic/github-code-scanning/codeql context never entered required-check list; verified absent from ruleset 17335746 required_status_checks post-change. |
| DONT1 | avoidance | respected | review | Dataflow replacement NOT decided here — deferred to deepenSastDataflow followup change. |
| DONT2 | avoidance | respected | review | CodeQL/Code Quality not wired into Sharperflow CI Gate needs: — it was disabled/retired, not adopted. |
| DONT3 | avoidance | respected | review | Did not assume API behavior: empirically probed security code-scanning API (403) AND Actions disable (422), THEN found the correct code-quality API (worked). No guessing — all paths tested live. |
| DONT4 | avoidance | respected | review | Only PokeEdge touched for removal (the only repo running Code Quality). PokeEdge-Web confirm-clean only (no change). This repo (public, no app code) untouched for removal — docs-only. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-9f58917915a2 | AC1 |  | C1, C2 |  |
| tk-264e4295c492 | AC2 |  | C3, C4, DONT3 |  |
| tk-14aac79920ce | AC2 |  | C3, DONT2 |  |
| tk-f563c14ba26c | AC3, AC4 |  | C2, C4 |  |
| tk-7e0964f00791 | AC5 |  | DONT1 |  |
