# Executive Summary: Remove Uptime Kuma from all workflows

## Outcome
Removed Uptime Kuma entirely from PokeEdge-Web — 4 workflows, 1 test, 1 doc section. No longer used or wanted.

## What shipped (PR #215, commit e1c28a04)
- `ci.yml` — deleted `heartbeat` job
- `staging-deploy.yml` — deleted `heartbeat` job
- `production-deploy.yml` — deleted `heartbeat` + `postdeploy-heartbeat` jobs
- `release.yml` — deleted `heartbeat` job
- `tests/workflows/uptime-kuma-heartbeat.test.ts` — deleted
- `STATUS.md` — removed "Live Status Page" (Uptime Kuma dashboard) section
- 6 files, 242 deletions, 0 insertions

## Kept
- Discord `notify-failure` job (separate notification path, not Uptime Kuma)
- CHANGELOG.md (historical record)

## Verification
- `grep -riE "uptime|kuma"` across workflows + STATUS.md → 0 hits
- No job `needs:` references a deleted heartbeat (leaf jobs)
- `ci.yml` actionlint EXIT:0 (deploy-workflow shellcheck warnings pre-existing on main)
- `bun run check` → 0 errors, 0 warnings
- `bun run test` → 296 files, 4807 tests pass (was 297/4809; deleted test had 2)

## Manual follow-up (outside this PR)
GitHub repo secrets/vars to delete in Settings → Secrets and variables → Actions:
- `vars.UPTIME_KUMA_URL`
- `secrets.UPTIME_KUMA_PUSH_TOKEN_CI`
- `secrets.UPTIME_KUMA_PUSH_TOKEN_STAGING_DEPLOY`
- `secrets.UPTIME_KUMA_PUSH_TOKEN_PROD_DEPLOY`
- `secrets.UPTIME_KUMA_PUSH_TOKEN_PROD_POSTDEPLOY`
- `secrets.UPTIME_KUMA_PUSH_TOKEN_RELEASE`

Hosted Uptime Kuma instance (Azure container) — decommission separately if desired.
