# Executive Summary: Fix CI fail-fast topology

## Outcome
Fixed CI fail-fast topology gaps across 3 repos that were burning GitHub Actions minutes on doomed runs. Security failures now skip expensive test/build jobs instead of running them to completion. PR-gate pytest lanes stop at first failure instead of running full suites end-to-end.

## What shipped

### sharperflow-security-gates (PR #20 — CI passed)
- `docs/ci-standard.md` §1: clarified arrow notation = DAG stages, not serial chain.
- `docs/ci-standard.md` §2: new "Fail-fast edges" subsection — direct pattern, fast-gate join, anti-pattern, choosing guidance.
- `examples/pokeedge-{web,python}/ci.yml`: test/build now have `needs: [fast-checks, security]`. Anti-example eliminated.

### PokeEdge-Web (PR #193 — CI running, security+lint+typecheck passed)
- `ci.yml`: `test`/`build` `needs:` now includes `security` (fail-fast edge). Wall-clock penalty: median 0s, worst 2s (n=16).
- `ci.yml`: removed advisory `integration` job (29/29 success, 0 failures, zero gate signal) + stale 15-min-budget comment.
- `ci.yml` + `ci-quality.yml`: all pins bumped v0.2.1 → v0.4.1 (6 remaining after integration removal).

### PokeEdge (PR #498 — CI Gate passed)
- `pr-gate.yml`: `-x` (fail-fast) on unit + api pytest lanes. xdist-compatible.
- `dependency-review.yml`: `concurrency: cancel-in-progress: true` (default PR trigger includes synchronize).

## Estimated savings
- PokeEdge-Web: ~5.7 hr / 200 runs (54% failure rate, security fails at +24-28s but test/build ran ~8 min anyway).
- PokeEdge: ~7-9 hr/month on unit lane alone (227 failures/month × median 8m58s pre-fix).

## Constraints honored
- C1-C6 (carried from reduceActionsCost): all respected.
- C7 (cross-repo execution approval): user-approved at execution gate.
- C8 (worktree isolation): ADV worktree for this repo, manual worktrees for app repos.
- DONT1-DONT6: all respected (0 failing review rows).

## What was NOT changed (out of scope)
- PokeEdge backend pin (stale v0.3.2, no topology gap — separate change).
- Advance pilot floating @v0 (different gap class).
- BuildKit cache cleanup, Renovate batch, Stage-3 serialization, deploy-chain.
