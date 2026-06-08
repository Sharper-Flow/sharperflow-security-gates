# Contract Traceability

**Change ID:** fixMergeCollisionStrategy
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-08T21:17:25.932Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | rulesets JSON disk: strict_required_status_checks_policy=false, pull_request.allowed_merge_methods=["squash"], non_fast_forward kept, ctx ["Sharperflow CI Gate"], bypass_actors=[]. Applied live via apply-ruleset.sh --no-release-bypass; gh api orgs/Sharper-Flow/rulesets/17335746 confirms live strict=false methods=["squash"] — disk==live. |
| AC2 | acceptance_criterion | pass | test | self-test.yml ruleset-JSON assertion block asserts strict is False AND allowed_merge_methods==["squash"] + non_fast_forward present; executes green against edited JSON (would fail on old strict=true shape). actionlint clean. |
| AC3 | acceptance_criterion | pass | test | ci-standard.md: §6 amended (strict-off + squash-only + auto-merge; non_fast_forward correctly described as force-push guard); Merge serialization subsection; Dependency-updates retitled to Renovate-OR-Dependabot equal path (supersession of adoptRenovateOrgWide + one-updater-per-ecosystem + Dependabot cooldown/--auto --squash); Cross-repo API contract gate section (oasdiff); Tier-3 escalation; conformance checklist updated. All 4 sections present; intra-doc anchors resolve. |
| AC4 | acceptance_criterion | pass | test | examples/pokeedge-python/ci.yml: producer contract-gate job (pinned oasdiff v1.18.5, fetch consumer baseline, oasdiff breaking --fail-on ERR) wired to summary needs. examples/pokeedge-web/ci.yml: consumer contract-sync job (baseline freshness vs backend main, Git Blobs API for >1MB) wired to summary needs. actionlint clean on both. |
| AC5 | acceptance_criterion | pass | test | oasdiff documented via CLI + new oasdiff/oasdiff-action; --fail-on ERR (high-signal); version-pinned (v1.18.5) + Renovate-bumpable. Deprecated Tufin/oasdiff-action appears ONLY in explicit NEVER-use warnings (ci-standard.md + example comment), never as a uses:. |
| AC6 | acceptance_criterion | pass | test | PokeEdge PR #347 (chore/remove-stale-sonarcloud) OPEN, removes orphaned .github/workflows/sonarcloud.yml (132 lines), SQUASH auto-merge armed. sonar-project.properties already absent. Required check is Sharperflow CI Gate only (no orphaned required context). Dependabot conformant: Renovate active + no dependabot.yml = one-updater-per-ecosystem. Broader sonar doc-refs surfaced as agenda follow-up ag-DJe50eGl. |
| AC7 | acceptance_criterion | pass | test | gh api live: both PokeEdge + PokeEdge-Web allow_squash_merge=true, allow_auto_merge=true, allow_merge_commit=false, allow_rebase_merge=false, default_branch=main. Required Sharperflow CI Gate intact in ruleset. Squash precondition satisfied before apply (no merge hard-block). |
| AC8 | acceptance_criterion | pass | test | README.md: dependency-updater pointer updated (Renovate-or-Dependabot one-per-ecosystem); branch-protection block updated (non-strict + squash-only + allow_squash_merge precondition + Merge-serialization link); strict/bypass disambiguated. All README->ci-standard anchors resolve (incl. pre-existing #5-pin-policy-lbp-supply-chain fixed). No broken anchors. |
| C1 | constraint | respected | static_check | No GHEC upgrade; solution uses Team-plan-compatible GitHub primitives only. |
| C2 | constraint | respected | static_check | No paid SaaS adopted; Tier-3 escalation (Mergify/AI-bot) is documentation only. |
| C3 | constraint | respected | static_check | All CI/verification stays in GitHub Actions cloud; no local-hardware verification path introduced (agent-side Temporal mutex explicitly rejected). |
| C4 | constraint | respected | static_check | Org-ruleset apply done via apply-ruleset.sh as an explicit privileged step (admin:org token), dry-run previewed first; user-authorized before firing. Not an automated CI mutation. |
| C5 | constraint | respected | static_check | PokeEdge cross-repo edit done as a PR (#347), not a direct push to main; user-authorized. |
| C6 | constraint | respected | static_check | bypass_actors=[] on disk and live; no tool added as bypass actor; escalation doc explicitly forbids bypass-actor tooling. |
| C7 | constraint | respected | static_check | oasdiff gated on --fail-on ERR (high-signal definite-breaks only); WARN advisory — matches repo fail-on-high-signal posture. |
| DONT1 | avoidance | respected | review | No agent-side Temporal merge mutex built; explicitly documented as rejected (local hardware tax, cannot govern bot PRs). |
| DONT2 | avoidance | respected | review | No merge_queue rule in ruleset (grep clean); native merge queue documented as impossible on Team+private. |
| DONT3 | avoidance | respected | review | oasdiff pattern documented + referenced (PokeEdge check-api-compat.yml as reference impl); no duplicate reusable workflow added to this repo. Examples illustrate the pattern only. |
| DONT4 | avoidance | respected | review | Both Renovate and Dependabot enabled as equal paths; the per-repo CHOICE is explicitly deferred to a future re-assessment (Choosing-the-updater table lists inputs, makes no choice). |
| DONT5 | avoidance | respected | review | bypass_actors=[] retained disk+live; ruleset not weakened. |
| DONT6 | avoidance | respected | review | Deprecated Tufin/oasdiff-action never used as an action; appears only in NEVER-use warnings. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-1a52689ce24f | AC1 |  | DONT5 |  |
| tk-a08702636908 | AC2 | AC1 |  |  |
| tk-2e620dce067a | AC3 |  | C2, C6 |  |
| tk-f43918311748 | AC3 |  | DONT4 |  |
| tk-7a3f8210f50f | AC4, AC5 |  | DONT3, DONT6, C7 |  |
| tk-7c6a6773b257 |  | AC4 | DONT6 |  |
| tk-1d45eceb0464 | AC8 |  |  |  |
| tk-3ace174c92c4 |  | AC1, AC2, AC4, AC5, AC8 |  |  |
| tk-47358256b006 | AC7 |  | C4, C5 |  |
| tk-147498c68788 | AC1 |  | C4, DONT5 |  |
| tk-ac3890c1d028 | AC6 |  | C5 |  |
| tk-992c56406f96 |  | AC1, AC6, AC7 |  |  |
