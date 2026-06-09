# Executive Summary — Prune unused CI workflows

## Outcome

Follow-up to `retireVestigialCodeql`: the systematic "stop running Actions we don't need" sweep. Cut to the dead/unwanted workflows on the two standard-governed app repos, added a hygiene rule to the standard, and — critically — did NOT blindly delete the "5 disabled workflows" the naive read suggested.

## What the diligence prevented

The naive cleanup ("delete all 5 disabled_manually PokeEdge workflows") would have **destroyed load-bearing infra**. Investigation reclassified them:

- **2 were already-deleted ghosts** (`codecov-ai.yml`, `compose.ci.override.yml`) — files gone from main, only stale registry records remain (no GitHub delete API → they age out).
- **2 were load-bearing-but-failing** (`ops-audit.yml` = prod migration-drift + sync-health; `nightly-merge-gate.yml` = T3 perf/fuzz/Bicep) — disabled *because failing*, not worthless.
- **2 were genuinely dead** (`opencode.yml`, `pr_agent.yml`).

## Delivered

- **PokeEdge PR #354** (armed auto-merge) — deletes 4 files: the 2 dead experiments + the 2 failing-infra workflows the user explicitly chose to remove (informed override; recoverable via `git revert`; capability captured in this change's record).
- **`docs/ci-standard.md`** — new `### Workflow hygiene` rule (ca68982): delete disabled workflow files; managed scan features (Code Quality, security CodeQL, Copilot coding agent) stay off unless adopted; ghost records age out harmlessly.
- **PokeEdge-Web Copilot coding agent** — investigated, **left as-is**: the org has **0 Copilot seats** so it's already inert, and the only disable path is a disproportionate org-wide Copilot policy change. User decision.

## Verification

- PR #354 deletions verified via PR API + branch commits; required check remains `Sharperflow CI Gate` only on both repos; no active workflow references the deleted files.
- Contract matrix: 12/12 pass/respected, 0 failing.

## Scope discipline

Held to PokeEdge + PokeEdge-Web (the standard-governed repos). Other org repos surveyed and confirmed trivial/out-of-standard — untouched.

## Gotchas banked

- `gh api -f ref=X` silently switches GET→POST and the contents API ignores the body `ref` (queries the default branch) → false results. Use the PR files API or `?ref=` in the URL as source of truth.
- GitHub "Code Quality" ≠ security CodeQL (separate APIs/gating) — promoted to project wisdom in the prior change.

## Follow-ups (unchanged)

- `deepenSastDataflow` — dataflow SAST decision (parked).
- If anyone wants ops-audit / nightly-merge-gate back: `git revert` the deletion commits and fix the underlying prod-access failures.