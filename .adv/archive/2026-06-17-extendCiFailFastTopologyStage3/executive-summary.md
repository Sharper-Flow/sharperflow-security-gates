# Executive Summary: Extend CI fail-fast topology (stage-3 gate + commit-lint)

## Outcome
Closed the intra-stage fail-fast gap that the parent change (`fixCiFailFastTopology`) missed: backend stage-3 lanes now skip when `pr-gate` fails; Web `test`/`build`/`notify-failure`/`heartbeat` now gate on `commit-lint`; standard documents all three patterns.

## What shipped

### sharperflow-security-gates (committed `c8400c6` in ADV worktree)
- `docs/ci-standard.md` § "Intra-stage sibling gating" — 118 lines documenting:
  - Stage-3-gate join pattern (with skip-cascade mandatory requirement)
  - Commit-lint `always()` pattern (with full behavior matrix for pr/push/merge_group)
  - Notification-gap pattern (notify/heartbeat needs: + HEARTBEAT_STATUS expression)
  - Cross-references to backend pr-gate.yml and web ci.yml as canonical examples

### PokeEdge-Web (PR #211, head `9fde4af1`)
- `ci.yml:163-164, 189-190`: test/build `needs:` += `commit-lint`; `if:` uses `always() && !cancelled() && needs.changes.outputs.code == 'true' && needs.commit-lint.result != 'failure'`
- `ci.yml:334, 365`: notify-failure/heartbeat `needs:` += `commit-lint`
- `ci.yml:380`: `HEARTBEAT_STATUS` expression includes `|| needs.commit-lint.result == 'failure'`
- actionlint clean (EXIT:0)
- CI: Lint ✓, Security all 4 ✓, Changes ✓, Commit Check ✓, **Type Check ✗ (pre-existing openapi.json drift)**, Build pending, Unit Tests pending

### PokeEdge (PR #512, head `b943ea1c6`)
- `pr-gate.yml:411` (new): `stage-3-gate: needs: [fast-gate, pr-gate]`, `if: !cancelled()`, case-loop on `needs.*.result` accepting `success|skipped`
- `pr-gate.yml:415, 507, 557, 579`: migration-chain/integration/e2e/acceptance `needs: [fast-gate, stage-3-gate]` (keep `fast-gate` for path-scope outputs)
- `pr-gate.yml:605`: `ci-gate` `needs:` += `stage-3-gate`
- `contract` and `api-compat` unchanged (A2)
- actionlint clean (EXIT:0)
- Pre-push hooks all passed
- CI: Sharperflow CI Gate ✓, **Stage 3 Gate ✓ in 3s**, Fast Gate ✓, Quality Chain ✓, Security all 4 ✓. Stage-3 lanes correctly SKIP on this workflow-only PR (path-scope working).

## Trade-off
**Backend `stage-3-gate` adds +160s (+17%) to success-path wall-time** (924s → 1,084s). User explicitly accepted in C9. On failure: 411s runner-seconds saved per pr-gate failure.

## Estimated savings
- Backend: **$13.15/mo** (240 pr-gate failures × 411s × $0.008/min)
- Web commit-lint: **$3.85/mo** (35 incidents × 530s × $0.008/min)
- Web build→test gate: **$1.60/mo** (200s × 311 failures × 0.57 × $0.008/min)
- **Total: $18.60/mo (8.6% of $217/mo budget)**

## Constraints honored
- C1-C6 (carried from reduceActionsCost): all respected
- C7 (cross-repo execution approval): user-approved at execution gate
- C8 (worktree isolation): ADV worktree for this repo, manual worktrees for app repos
- C9 (trade-off surfaced+accepted): implementation did not optimize away the wall-time penalty
- C10 (skip-cascade mandatory): fast-gate retained in every stage-3 lane's `needs:`; case-loop is complement, not replacement

## Out of scope (per OOS1-OOS9)
- PokeEdge-Web Fix B (full fast-gate join)
- Backend lane consolidation (Design C)
- Push trigger changes
- Path-scope expansion to commit-lint
- Job ID renames
- BuildKit/deploy-chain
- New scanner or threshold changes
- PokeEdge backend pin (stale v0.3.2)
- Advance pilot `@v0`

## Remaining (post-merge evidence, AC4)
- Web: next commit-lint failure PR run → test/build SKIPPED in <60s
- Backend: next pr-gate failure run → integration/e2e/acceptance/migration SKIPPED in <5s
- Both require PRs to merge first

## Pre-existing issue surfaced
**PokeEdge-Web `docs/openapi.json` is out of sync with backend `openapi.json` main.** Type Check & API Drift fails on any PR opened against current main. This is **NOT in scope** for this change and is a separate maintenance task. PR #211 will be blocked by this until someone regenerates `docs/openapi.json` from backend main. Options for the user:
1. Regenerate `docs/openapi.json` as a separate commit on PR #211 (small YAML regeneration)
2. Land `docs/openapi.json` regeneration as a separate PR first, then rebase #211
3. Land the commit-lint changes in a follow-up PR after regeneration
