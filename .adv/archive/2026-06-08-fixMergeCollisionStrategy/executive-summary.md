# Executive Summary — fixMergeCollisionStrategy

## What it solves
PR merge-collision loops on a small-seat org running many concurrent AI-agent/bot PRs. The verified root cause was **not** a missing merge queue — it was `strict_required_status_checks_policy: true` ("branch must be up to date") in the org ruleset, which forced endless rebase + CI-rerun churn as PRs raced.

## Key finding (reframed the whole ask)
The two source tickets assumed GitHub merge queue could be enabled. **It cannot** on this account (Team plan + private repos require GitHub Enterprise Cloud for merge queue — confirmed via `gh api`: plan=team, both repos private). The 422 errors the prior agents hit were correct rejections, not bugs. With GHEC rejected on cost, the fix is built from plan-compatible GitHub primitives.

## What was delivered
**Tier 1 — collision-loop fix (live):** org ruleset `strict=false` + `allowed_merge_methods:["squash"]`. PRs now merge serially via native auto-merge (`gh pr merge --squash --auto`) on a green `Sharperflow CI Gate` — server-side, no rebase churn, identical single- or multi-machine, Renovate/Dependabot-native. Applied live to ruleset 17335746; disk==live verified.

**Tier 2 — cross-repo contract gate (standardized):** the backend↔frontend OpenAPI drift that no merge serialization can catch is closed by **oasdiff** breaking-change detection (already shipped on PokeEdge; validated as the de-facto best-practice tool). Documented as canonical in ci-standard.md (consumer-committed-spec baseline model, `--fail-on ERR`, CLI/new-action only — never the deprecated Tufin action, >1MB Git-Blobs-API gotcha). Both example CIs refreshed to show the producer (oasdiff) and consumer (sync) halves.

**Tier 3 — escalation playbook (documented, not adopted):** if collisions persist, Mergify free tier or another AI-PR-bot — with verified caveats (bot-author billing, bot-PR config, must stay within rulesets).

**Tier 4 — Dependabot equal-path:** reversed the 2-day-old Renovate-only rule per explicit user decision. ci-standard.md now supports Renovate OR Dependabot (one updater per ecosystem per repo), with Dependabot's GA cooldown + `--auto --squash` workflow documented and a re-assessment-inputs table for the future per-repo choice.

**Tier 5 — live drift fix:** PokeEdge PR #347 opened removing the orphaned `sonarcloud.yml` (Sonar was retired org-wide), with squash auto-merge armed — itself a live demonstration of the new policy.

## Verification
- Local: actionlint clean, shellcheck clean, self-test ruleset-JSON assertions green (now assert strict-off + squash-only).
- Live: ruleset 17335746 confirmed strict=false + methods=["squash"] + bypass=[]; both repos squash-only + auto-merge on.
- Contract: 21/21 items pass/respected (8 ACs, 7 constraints, 6 avoidances), 0 failing.
- Independent design validator caught + we fixed: the false "non_fast_forward blocks merge commits" rationale (squash-only comes solely from allowed_merge_methods) and the squash-precondition hard-block hazard (pre-apply guard added).

## Design integrity
- No GHEC, no paid SaaS, no agent-side Temporal mutex (rejected: local-hardware tax + can't govern bot PRs), no native merge_queue (impossible on plan), no bypass actors (security-gates org keeps `bypass_actors: []`).
- Accepted residual risk: strict-off lets a rare green-but-incompatible PR pair break main, caught by the next PR's CI; the oasdiff gate closes the highest-value (cross-repo API) coupling.

## Follow-ups
- ag-DJe50eGl: clean residual SonarCloud doc references in PokeEdge (docs-only, out of this change's workflow-removal scope).
- Future: per-repo Renovate-vs-Dependabot re-assessment (enabled here, deferred by design).