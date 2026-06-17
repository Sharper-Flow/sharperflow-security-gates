# Acceptance

Reviewed at: 2026-06-17T18:39:33.720Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| OOS1 | out_of_scope | PokeEdge-Web full fast-gate join (Fix B) — separate change | respected | PokeEdge-Web ci.yml uses Fix C (always() + result != 'failure'), NOT Fix B (full fast-gate join). No new fast-gate job introduced; test/build needs: only added commit-lint. Verified by reviewing commit 9fde4af1. |
| OOS2 | out_of_scope | Backend lane consolidation (Design C) — rejected | respected | Stage-3 lanes kept as separate jobs (migration-chain, integration, e2e, acceptance). NOT merged into one job. No consolidation introduced. Verified by reviewing commit b943ea1c6. |
| OOS3 | out_of_scope | Push trigger changes — defensible post-merge verification | respected | ci.yml on: block (push, pull_request, merge_group) unchanged. Only test/build/notify/heartbeat needs: and if: changed. Verified by diff on 9fde4af1 — no on: changes. |
| OOS4 | out_of_scope | Path-scope expansion to commit-lint (low value) | respected | commit-lint job definition (line 230-289) unchanged. Only its result is referenced by test/build/notify/heartbeat. No path-scope expansion added to commit-lint itself. Verified by diff on 9fde4af1. |
| OOS5 | out_of_scope | Job ID renames — preserves cache hits | respected | All job IDs preserved: pr-gate, commit-lint, fast-gate, test, build, security, ci-gate, integration, e2e, acceptance, migration-chain, contract, api-compat, notify-failure, heartbeat. Only stage-3-gate is new. Diff verified. |
| OOS6 | out_of_scope | BuildKit cache cleanup, Stage-3 sibling isolation, deploy-chain — unchanged from prior changes | respected | No BuildKit cache changes. No deploy-chain changes. No Stage-3 sibling isolation (e.g., per-lane runners) added. The intra-stage gate is via needs: in the same workflow, not isolation. |
| OOS7 | out_of_scope | Adding new scanner or threshold changes — C1/C5 | respected | No scanner removed, no severity threshold raised. security job unchanged on both repos (only the ci.yml pin was already bumped to v0.4.1 in the parent change). |
| OOS8 | out_of_scope | PokyEdge backend pin (stale v0.3.2) — separate change | respected | PokeEdge backend pin (cb39edcd # v0.3.2) untouched. Diff verified — only pr-gate.yml changed on PokeEdge. |
| OOS9 | out_of_scope | Advance pilot `@v0` floating tag — different gap class | respected | Advance repo not touched. Only sharperflow-security-gates (docs), PokeEdge-Web (ci.yml), PokeEdge (pr-gate.yml) modified. |

