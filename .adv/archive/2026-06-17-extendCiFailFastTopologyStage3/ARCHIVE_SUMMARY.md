# Archive: Extend CI fail-fast topology (stage-3 gate, commit-lint)

**Change ID:** extendCiFailFastTopologyStage3
**Archived:** 2026-06-17T20:21:29.239Z
**Created:** 2026-06-17T18:09:49.854Z

## Tasks Completed

- ✅ Add "Intra-stage sibling gating" subsection to `docs/ci-standard.md`
  > Task checkpoint completed
- ✅ PokeEdge-Web ci.yml: notification gap fix (commit-lint in notify/heartbeat `needs:` + HEARTBEAT_STATUS)
  > Task checkpoint completed
- ✅ PokeEdge-Web ci.yml: add `commit-lint` to test/build `needs:` + `always()` `if:` (Fix C)
  > Task checkpoint completed
- ✅ PokeEdge pr-gate.yml: add `stage-3-gate` join job
  > Task checkpoint completed
- ✅ PokeEdge pr-gate.yml: update 4 stage-3 lanes `needs:` to include `stage-3-gate`
  > Task checkpoint completed
- ✅ PokeEdge pr-gate.yml: add `stage-3-gate` to `ci-gate` `needs:` list
  > Task checkpoint completed
- ✅ Verify all changes: actionlint clean across 3 repos + collect post-merge CI evidence
  > Task checkpoint completed

## Specs Modified

