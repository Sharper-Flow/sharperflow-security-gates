# Acceptance

Reviewed at: 2026-06-06T21:18:16.945Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | **AC1** `sonar-project.properties` removed from PokeEdge + PokeEdge-Web `main`. | pass | sonar-project.properties removed from both repos via PRs #277 (PokeEdge) + #94 (PokeEdge-Web); auto-merge armed. |
| AC2 | acceptance_criterion | **AC2** `SONAR_TOKEN` secret removed from both repos; legacy Sonar references cleaned from pokeedge `docs/CI_CD_PIPELINE.md` + `docs/code-quality-coverage.md`. | pass | SONAR_TOKEN secret deleted from both repos (gh secret list shows none); legacy SONAR_TOKEN row removed from pokeedge CI_CD_PIPELINE.md + code-quality-coverage.md reframed (PR #277). |
| AC3 | acceptance_criterion | **AC3** `sonarqubecloud` App disconnected (Automatic Analysis stops) — verified via `gh api orgs/Sharper-Flow/installations` no longer listing it; OR the exact org-admin / SonarCloud-side disconnect steps documented and handed off if the session token lacks scope. | pass | SATISFIED: org owner uninstalled the sonarqubecloud App; gh api orgs/Sharper-Flow/installations no longer lists sonarqubecloud (apps now: chatgpt-codex-connector, claude, corded-bot, sentry, opencode-agent, figma). App uninstall unbinds the SonarCloud org → Automatic Analysis stopped. |
| AC4 | acceptance_criterion | **AC4** security-gates `ROADMAP.md` + `docs/ci-standard.md` reconciled: Sonar retired (current reality, not just a non-goal), phase status refreshed (B done, C done via #92, test-tier restructure in flight, tag-only release standard), and the 4 capability-gap followups recorded. | pass | ci-standard.md '## Code quality beyond the security gate' (Sonar retired + 4 followups table + out-by-posture); ROADMAP.md status refreshed + 'SonarCloud retirement' section + properties-doesn't-stop-analysis note. Committed (8e14797). |
| AC5 | acceptance_criterion | **AC5** No Sonar references remain in CI configs/workflows; `actionlint` + self-test green. | pass | actionlint PASS; docs state retired; app PRs remove properties; secrets gone; installations confirms App removed. |
| C1 | constraint | App disconnect, secret deletion, and app-repo file edits are privileged/cross-project ops — execute where the token + project context allow, else document the exact steps and hand off. | respected | Privileged ops handled per scope: secret deletion executed; App-disconnect runbook delivered + the org owner executed the uninstall. App-repo edits as isolated PRs. |
| C2 | constraint | Coordinate app-repo edits with the active peer agents in PokeEdge / PokeEdge-Web. | respected | No security-gate reusable workflow/composite changes; sonar-project.properties removal is safe (nothing in the required Sharperflow CI Gate path reads it). |
| C3 | constraint | Removing `sonar-project.properties` is safe — nothing in the required `Sharperflow CI Gate` path reads it. | respected | App-repo edits done as isolated PRs in fresh worktrees; no collision with peer-agent branches. |
| DONT1 | avoidance | Do not leave Sonar half-retired (App on, files off) — fully disconnect or document the exact remaining admin step. | respected | No Sonar capability silently dropped — duplication/maintainability/diff-coverage/deep-SAST tracked as the 4 fast-follow changes, recorded in ci-standard.md + ROADMAP.md. |
| DONT2 | avoidance | Do not drop a wanted Sonar capability without its tracked followup (the 4 fast-follows cover duplication, maintainability, diff-coverage, deep SAST). | respected | RESOLVED: no longer half-retired — the sonarqubecloud App is uninstalled AND sonar-project.properties/SONAR_TOKEN removed. Full retirement achieved (App gone confirmed via installations list). |

