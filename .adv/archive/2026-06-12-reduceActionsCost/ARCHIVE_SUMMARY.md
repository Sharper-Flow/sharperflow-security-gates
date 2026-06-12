# Archive: Reduce Actions cost

**Change ID:** reduceActionsCost
**Archived:** 2026-06-12T19:48:36.155Z
**Created:** 2026-06-12T04:22:58.166Z

## Tasks Completed

- ✅ Patch reusable SBOM scanner and retention behavior
  > Updated `.github/workflows/python-security-gate.yml`, `javascript-security-gate.yml`, and `container-security-gate.yml` to make SBOM scanner partition explicit and bound SBOM artifact retention. No job names, inputs, default source scan behavior, or scanner coverage removed.
- ✅ Patch local docs and example references for scanner partition/pins
  > Updated README, ROADMAP, CI standard docs, pilot docs, and examples to reflect current scanner partition and verified v0.3.2 release pin. Archive historical references left untouched.
- ✅ Implement direct PokeEdge-Web workflow cleanup
  > Task checkpoint completed
- ✅ Implement direct PokeEdge workflow cleanup
  > Task checkpoint completed
- ✅ Prepare bounded cache/artifact cleanup dry-runs
  > Created a durable read-only cleanup report with cache classes, counts, sizes, example candidate IDs, and explicit deletion boundaries requiring future approval before any destructive API call.
- ✅ Final verification and contract evidence matrix
  > Verified all touched repositories and recorded final evidence. Local repo has exact actionlint pass; app repos have structural actionlint pass because full actionlint reports pre-existing shellcheck style/info outside introduced changes. Target worktrees are clean/ahead one commit each after checkpoint/rebase.
- ✅ Release-readiness sweep after all cleanup evidence
  > Confirmed execution evidence is complete and ready for acceptance review. All AC1-AC10 and constraints C1-C6 have persisted pass/respected evidence. Outstanding destructive cleanup remains approval-gated; `docs/actions-cost-cleanup-dry-run.md` provides candidate bounds.

## Specs Modified

