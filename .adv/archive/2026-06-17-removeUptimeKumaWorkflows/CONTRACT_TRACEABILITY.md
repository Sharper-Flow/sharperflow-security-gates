# Contract Traceability

**Change ID:** removeUptimeKumaWorkflows
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-17T21:14:43.615Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | heartbeat removed from ci.yml/staging-deploy.yml/release.yml; heartbeat+postdeploy-heartbeat removed from production-deploy.yml. git commit e1c28a04, 242 deletions. |
| AC2 | acceptance_criterion | pass | test | tests/workflows/uptime-kuma-heartbeat.test.ts deleted (git status D). tests/workflows/ now empty. |
| AC3 | acceptance_criterion | pass | test | grep -riE 'uptime|kuma' .github/workflows/ STATUS.md → 0 hits. |
| AC4 | acceptance_criterion | pass | test | grep for needs: referencing heartbeat → 0 hits. Heartbeats were leaf jobs. |
| AC5 | acceptance_criterion | pass | test | ci.yml actionlint EXIT:0. Deploy-workflow shellcheck info/style warnings pre-existing on main (21 on staging), not introduced. |
| AC6 | acceptance_criterion | pass | test | bun run check 0 errors/warnings. bun run test 296 files 4807 tests pass (was 297/4809, deleted test had 2). |
| AC7 | acceptance_criterion | pass | test | CHANGELOG.md not in the 6-file diff. Untouched. |
| C1 | constraint | respected | static_check | Heartbeats confirmed leaf jobs; no gate/summary logic references them (AC4 grep). Deploy/release flows unaffected. |
| C2 | constraint | respected | static_check | notify-failure (Discord) job unchanged in ci.yml. Only heartbeat removed. |
| C3 | constraint | respected | static_check | Only heartbeat job blocks deleted; no other deploy/release logic touched. Diff = 242 deletions, 0 insertions. |
| C4 | constraint | respected | static_check | Work done in isolated worktree /home/jon/dev/pokeedge-web-rmkuma. |
| DONT1 | avoidance | respected | review | No code edits to GitHub secrets/vars (not possible via PR). Listed in PR #215 body for manual cleanup. |
| DONT2 | avoidance | respected | review | CHANGELOG.md untouched (not in diff). |
| DONT3 | avoidance | respected | review | No refactor of deploy/release workflows beyond heartbeat job deletion. |
| DONT4 | avoidance | respected | review | notify-failure (Discord) untouched — verified in ci.yml diff. |
| OOS1 | out_of_scope | respected | not_applicable | GitHub secrets/vars manual removal noted in PR, not attempted via code. |
| OOS2 | out_of_scope | respected | not_applicable | No changes to PokeEdge backend or Advance repos. |
| OOS3 | out_of_scope | respected | not_applicable | No replacement monitor added. Pure removal. |
| OOS4 | out_of_scope | respected | not_applicable | Deploy/release logic unchanged beyond heartbeat removal. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-40e8f70e24e7 | AC1, AC2, AC3 |  | C2, C3, DONT2, DONT4 |  |
| tk-b568dc996a2e |  | AC4, AC5, AC6, AC7 |  |  |
| tk-fcdc368953a7 |  |  |  | Commit/push/PR task; verified by PR creation + CI. |
