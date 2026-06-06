# Contract Traceability

**Change ID:** retireSonarcloud
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-06T21:18:16.945Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | sonar-project.properties removed from both repos via PRs #277 (PokeEdge) + #94 (PokeEdge-Web); auto-merge armed. |
| AC2 | acceptance_criterion | pass | test | SONAR_TOKEN secret deleted from both repos (gh secret list shows none); legacy SONAR_TOKEN row removed from pokeedge CI_CD_PIPELINE.md + code-quality-coverage.md reframed (PR #277). |
| AC3 | acceptance_criterion | pass | test | SATISFIED: org owner uninstalled the sonarqubecloud App; gh api orgs/Sharper-Flow/installations no longer lists sonarqubecloud (apps now: chatgpt-codex-connector, claude, corded-bot, sentry, opencode-agent, figma). App uninstall unbinds the SonarCloud org → Automatic Analysis stopped. |
| AC4 | acceptance_criterion | pass | test | ci-standard.md '## Code quality beyond the security gate' (Sonar retired + 4 followups table + out-by-posture); ROADMAP.md status refreshed + 'SonarCloud retirement' section + properties-doesn't-stop-analysis note. Committed (8e14797). |
| AC5 | acceptance_criterion | pass | test | actionlint PASS; docs state retired; app PRs remove properties; secrets gone; installations confirms App removed. |
| C1 | constraint | respected | static_check | Privileged ops handled per scope: secret deletion executed; App-disconnect runbook delivered + the org owner executed the uninstall. App-repo edits as isolated PRs. |
| C2 | constraint | respected | static_check | No security-gate reusable workflow/composite changes; sonar-project.properties removal is safe (nothing in the required Sharperflow CI Gate path reads it). |
| C3 | constraint | respected | static_check | App-repo edits done as isolated PRs in fresh worktrees; no collision with peer-agent branches. |
| DONT1 | avoidance | respected | review | No Sonar capability silently dropped — duplication/maintainability/diff-coverage/deep-SAST tracked as the 4 fast-follow changes, recorded in ci-standard.md + ROADMAP.md. |
| DONT2 | avoidance | respected | review | RESOLVED: no longer half-retired — the sonarqubecloud App is uninstalled AND sonar-project.properties/SONAR_TOKEN removed. Full retirement achieved (App gone confirmed via installations list). |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-3a971393208e | AC4 |  | C2 |  |
| tk-24b101373294 | AC1, AC2 |  | C1, DONT2 |  |
| tk-7a2882fc8b3b | AC2, AC3 |  | DONT1 |  |
| tk-bb0368724a5c |  | AC1, AC2, AC3, AC4, AC5 |  |  |
