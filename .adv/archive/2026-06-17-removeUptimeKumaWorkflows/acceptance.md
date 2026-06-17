# Acceptance

Reviewed at: 2026-06-17T21:14:43.615Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | `heartbeat` job removed from ci.yml, staging-deploy.yml, release.yml. `heartbeat` + `postdeploy-heartbeat` removed from production-deploy.yml. | pass | heartbeat removed from ci.yml/staging-deploy.yml/release.yml; heartbeat+postdeploy-heartbeat removed from production-deploy.yml. git commit e1c28a04, 242 deletions. |
| AC2 | acceptance_criterion | `tests/workflows/uptime-kuma-heartbeat.test.ts` deleted. | pass | tests/workflows/uptime-kuma-heartbeat.test.ts deleted (git status D). tests/workflows/ now empty. |
| AC3 | acceptance_criterion | No `UPTIME_KUMA` / `uptime` / `kuma` (case-insensitive) references in `.github/workflows/` or STATUS.md. | pass | grep -riE 'uptime|kuma' .github/workflows/ STATUS.md → 0 hits. |
| AC4 | acceptance_criterion | No remaining job declares `needs:` on a deleted heartbeat job (heartbeats are leaf jobs; verify). | pass | grep for needs: referencing heartbeat → 0 hits. Heartbeats were leaf jobs. |
| AC5 | acceptance_criterion | actionlint clean on all 4 touched workflows. | pass | ci.yml actionlint EXIT:0. Deploy-workflow shellcheck info/style warnings pre-existing on main (21 on staging), not introduced. |
| AC6 | acceptance_criterion | `bun run check` + `bun run test` pass. | pass | bun run check 0 errors/warnings. bun run test 296 files 4807 tests pass (was 297/4809, deleted test had 2). |
| AC7 | acceptance_criterion | CHANGELOG.md untouched (historical record). | pass | CHANGELOG.md not in the 6-file diff. Untouched. |
| C1 | constraint | Heartbeats are non-blocking leaf jobs — deletion must not affect gate/summary logic. Verify nothing `needs:` them. | respected | Heartbeats confirmed leaf jobs; no gate/summary logic references them (AC4 grep). Deploy/release flows unaffected. |
| C2 | constraint | Don't touch the Discord `notify-failure` job (separate notification path, stays). | respected | notify-failure (Discord) job unchanged in ci.yml. Only heartbeat removed. |
| C3 | constraint | Don't touch deploy/release logic beyond removing the heartbeat job. | respected | Only heartbeat job blocks deleted; no other deploy/release logic touched. Diff = 242 deletions, 0 insertions. |
| C4 | constraint | Worktree isolation. | respected | Work done in isolated worktree /home/jon/dev/pokeedge-web-rmkuma. |
| DONT1 | avoidance | Don't remove the GitHub secrets/vars via code (they live in repo settings; list for manual cleanup). | respected | No code edits to GitHub secrets/vars (not possible via PR). Listed in PR #215 body for manual cleanup. |
| DONT2 | avoidance | Don't edit CHANGELOG.md (historical). | respected | CHANGELOG.md untouched (not in diff). |
| DONT3 | avoidance | Don't refactor the deploy/release workflows beyond the heartbeat deletion. | respected | No refactor of deploy/release workflows beyond heartbeat job deletion. |
| DONT4 | avoidance | Don't touch notify-failure (Discord) — it's not Uptime Kuma. | respected | notify-failure (Discord) untouched — verified in ci.yml diff. |
| OOS1 | out_of_scope | Manual removal of GitHub repo secrets/vars (UPTIME_KUMA_*) | respected | GitHub secrets/vars manual removal noted in PR, not attempted via code. |
| OOS2 | out_of_scope | Other repos (PokeEdge backend, Advance) | respected | No changes to PokeEdge backend or Advance repos. |
| OOS3 | out_of_scope | Replacing Uptime Kuma with another monitor | respected | No replacement monitor added. Pure removal. |
| OOS4 | out_of_scope | Deploy/release logic changes beyond heartbeat removal | respected | Deploy/release logic unchanged beyond heartbeat removal. |

