# GitHub Actions Cost Audit — June 2026

**Date:** 2026-06-17
**Org:** Sharper-Flow (GitHub Team plan, 15 private repos, 0 self-hosted runners)
**Source data:** `gh api /orgs/Sharper-Flow/settings/billing/usage` (granular line items) + per-repo run history.

## Top-line burn

| Month | Repo | Min | Cost |
|---|---|---:|---:|
| Jan 2026 | PokeEdge | 4,846 | $8.15 |
| Feb 2026 | Corded | 14,895 | $67.74 |
| Mar 2026 | PokeEdge-Web | 22,618 | $112.34 |
| Apr 2026 | PokeEdge | 8,462 | $26.66 |
| May 2026 | PokeEdge | 23,990 | $108.95 |
| **Jun 2026 (17d)** | **PokeEdge** | **51,986** | **$284.19** |
| (recurring) | GHAS Code Security | 1 user | $30/mo |

**Projected end-of-June: ~$500/mo on PokeEdge + $30/mo GHAS = ~$530/mo total.** **10× growth Jan→Jun 2026.**

## Per-workflow consumption (PokeEdge, last 30d)

| Workflow | Runs | Avg wall | Total min (wall) |
|---|---:|---:|---:|
| PR Gate | 20 | 13.5 min | 271 min |
| Deploy → Production | 11 | **22.5 min** | 247 min |
| Staging Deploy | 9 | 7.3 min | 66 min |
| Promote to Staging | 12 | 3.8 min | 46 min |
| Semantic Release | 12 | 0.8 min | 10 min |
| Auto Merge, PR Size Labeler, Dep Review, Sync OpenAPI | ~30 | <1 min | ~7 min |

**Heavy hitters:** `PR Gate` (per-PR cost), `Deploy → Production` (per-deploy cost). Most heavy lifting is `PokeEdge`; `PokeEdge-Web` is well-tuned (down from $112/mo in March to ~$0 today).

## Audit items ranked by estimated savings

### Tier 1 — Mechanical (no architecture change)

| # | Action | Status | Est. monthly save |
|---|---|---|---:|
| 1 | **Disable GHAS Code Security** in org Settings | **Manual — user action** | $30 |
| 2 | **Reduce `pr-gate` timeout 25 → 20 min** in PokeEdge | **Done: PR #516** | $5-15 |
| 3 | **Add `paths:` filter to PokeEdge-Web CI `push:` trigger** | **Already in place** via internal `changes` job (per `ci-standard.md`). No-op. | $0 |
| 4 | **Drop Firefox install from PokeEdge-Web integration job** | **No-op** — Firefox is required by `--project=integration` per `playwright.config.ts` | $0 |
| 5 | **Consolidate 4 security scans in PokeEdge-Web CI** | **Already in place** — uses `sharperflow-security-gates/.github/workflows/javascript-security-gate.yml` (one reusable workflow_call). No-op. | $0 |
| 6 | **Skip `verify-staging` when `repository_dispatch`** in PokeEdge `prod-deploy` | **Already in place** — the polling step has `if: github.event_name == 'workflow_dispatch'`. No-op. | $0 |

### Tier 2 — Structural (small refactor)

| # | Action | Status | Est. monthly save |
|---|---|---|---:|
| 7 | **Parallelize `prod-deploy` final 4 jobs** (finalize, sentry, create-release, trigger-frontend) | **Done: PR #516** | $5-12 (22-44 min/mo) |
| 8 | Cancel prod-deploy on stale dispatch (concurrency group) | Not done | $0 (rare) |
| 9 | Reduce prod-deploy image build to single arch (linux/amd64 only) | Not done | $2-5 |

### Tier 3 — Strategic (requires planning + decisions)

| # | Action | Est. monthly save | Tradeoff |
|---|---|---:|---|
| 10 | **Self-hosted runner on Azure D2s_v5 spot** (1 VM, 24/7) | **~$470** | Spot eviction (rare for D-series in East US). 1-2 hr/mo mgmt. |
| 11 | **GitHub Team → Enterprise upgrade** | ~$266 | Annual contract, harder to roll back. Includes SAML/SCIM/audit. |
| 12 | **Microsoft for Startups** ($5k Azure credits) | Runner cost → $0 | 10-min application, new MfS Azure sub. |
| 13 | **Visual Studio Subscription Azure credit** ($50-150/mo) | Runner cost → $0 | Requires VS Standard sub, separate VS-Offer Azure sub. |
| 14 | Re-introduce PokeEdge-Web integration E2E as smoke (1min) + full (on-demand) | Test coverage gain | Deferred per user decision — see [open questions]. |

See [`runner-options-research.md`](./runner-options-research.md) for the full strategic analysis.

## Already-optimized patterns (do not regress)

- `concurrency: cancel-in-progress: true` on PR-triggered workflows (PokeEdge `pr-gate.yml`, PokeEdge-Web `ci.yml`)
- Internal `changes` job using `dorny/paths-filter` to skip expensive lanes on docs-only changes (PokeEdge-Web `ci.yml` lines 39-78)
- `needs: changes.outputs.code == 'true'` gating on all heavy jobs
- `timeout-minutes:` set on every job (no infinite runners)
- No large matrix strategies (single runner per job)
- Reusable workflow calls for security gates (no per-repo scan duplication)
- Trivy cache (`cache-trivy-*`, 67MB, reused daily)

## Open questions / future work

- [ ] Re-introduce PokeEdge-Web integration E2E (smoke 1 min + full on-demand). Tests were retired in #138 as "chronically red" and the job removed in #193. Add to agenda after finding a best-practice way to bring back the test DB infra.
- [ ] Audit the **May→Jun 3× spike in PokeEdge** (8462 → 23990 → 51986 min/mo). `git log --since="2026-04-15" .github/workflows/` in PokeEdge — what heavy workflow was added?
- [ ] Prune stale `change/*` worktrees in PokeEdge (100+ from prior ADV changes). Many are merged but unremoved.

## Related docs

- [`runner-options-research.md`](./runner-options-research.md) — full self-hosted runner + GH Enterprise + MfS + VS credit analysis with sources.
- [`actions-cost-cleanup-dry-run.md`](./actions-cost-cleanup-dry-run.md) — prior cache/artifact cleanup (2026-06).
- [`ci-standard.md`](./ci-standard.md) — CI workflow invariants (required for `Sharperflow CI Gate` context).
