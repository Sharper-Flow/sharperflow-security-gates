# Archive: Fix CI fail-fast topology

**Change ID:** fixCiFailFastTopology
**Archived:** 2026-06-17T01:53:00.752Z
**Created:** 2026-06-16T23:14:03.089Z

## Tasks Completed

- ✅ Document `security → test/build` fail-fast edge in `docs/ci-standard.md` §2
  > Task checkpoint completed
- ✅ Demonstrate `security → test/build` fail-fast edge in both example CI workflows
  > Task checkpoint completed
- ✅ PokeEdge-Web ci.yml: add `security` to test/build needs: + remove `integration` job
  > Task checkpoint completed
- ✅ PokeEdge-Web: bump security-gates pin v0.2.1 → v0.4.1 (7 uses, 6 after T3 removes integration)
  > Task checkpoint completed
- ✅ PokeEdge pr-gate.yml: add fail-fast `-x` to unit + api pytest lanes
  > Task checkpoint completed
- ✅ PokeEdge dependency-review.yml: add concurrency block
  > Task checkpoint completed
- ✅ Verify all changes: actionlint clean across 3 repos + collect post-merge CI evidence
  > Task checkpoint completed

## Specs Modified

