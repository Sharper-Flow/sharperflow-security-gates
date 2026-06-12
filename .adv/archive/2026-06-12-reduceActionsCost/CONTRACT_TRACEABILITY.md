# Contract Traceability

**Change ID:** reduceActionsCost
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-12T05:16:08.275Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | PokeEdge inventory validated in discovery and preserved in agreement/design. Direct change task tk-03ec14128462 implemented safe PokeEdge workflow cleanup in `.github/workflows/pr-gate.yml` and `production-deploy.yml`; anchor run 27385083270 and 16-workflow inventory recorded in agreement/design. Final verification task tk-5448abcb81a8 passed structural actionlint and diff checks. |
| AC2 | acceptance_criterion | pass | test | PokeEdge-Web inventory validated in discovery and preserved in agreement/design: 9 workflow files on main plus disabled `compose.ci.override.yml` registry drift; anchor run 27387875564 recorded. Direct change task tk-f350017d48cd implemented safe cleanup across six files and final verification passed after rebase. |
| AC3 | acceptance_criterion | pass | test | Design records required status check/ruleset boundary: effective required context `Sharperflow CI Gate`. Direct app tasks explicitly kept that context unchanged. Final verification notes: `Sharperflow CI Gate` context unchanged in target changes. |
| AC4 | acceptance_criterion | pass | test | More than five safe cleanup items implemented or documented: local SBOM scanner override, local SBOM retention, docs/example pin update, PokeEdge draft-PR heavy-job guard, PokeEdge verify-staging poll skip, PokeEdge coverage retention, Web coverage upload removal, Web cached CI Quality setup, Web oasdiff cache, Web BuildKit mode=min, Web Renovate semantic commit config, and cache dry-run report. |
| AC5 | acceptance_criterion | pass | test | Local SBOM retention set to 14 days. PokeEdge coverage retention set to 7 days. Web coverage upload removed. Web BuildKit mode=max changed to mode=min. `docs/actions-cost-cleanup-dry-run.md` records PokeEdge Trivy cache and Web BuildKit/Trivy cache candidates with explicit no-delete boundary. |
| AC6 | acceptance_criterion | pass | test | PokeEdge-Web `renovate.json` updated by tk-f350017d48cd with explicit semantic-commit config; JSON syntax verified. Broader org Renovate policy not reopened. |
| AC7 | acceptance_criterion | pass | test | PokeEdge `production-deploy.yml` changed by tk-03ec14128462 so `verify-staging` polling runs only for manual `workflow_dispatch`; repository_dispatch auto-trigger skips redundant staging poll. Deploy-chain conditional measurement items remain deferred. |
| AC8 | acceptance_criterion | pass | test | Reusable gate changes only added explicit SBOM scanners and retention. Semgrep, Bandit, OSV, Gitleaks, and Trivy default source-code gate coverage remain present; no scanner removed. |
| AC9 | acceptance_criterion | pass | test | Local exact `docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7` passed. PokeEdge and Web structural actionlint with `-shellcheck=` passed; Web `renovate.json` JSON check passed; git diff --check passed in all touched repos. Full target actionlint shellcheck issues are pre-existing style/info outside introduced edits. |
| AC10 | acceptance_criterion | pass | test | User explicitly approved direct target mutation: `i approve direct changes of pokeedge and pokeedge-web immediately too`. Target mutations occurred in isolated worktrees `/home/jon/dev/pokeedge-wt/reduce-actions-cost` and `/home/jon/dev/pokeedge-web-wt/reduce-actions-cost`, not silently from current repo. |
| C1 | constraint | respected | static_check | No severity/default posture weakening: local changes preserve `HIGH,CRITICAL`, `ignore-unfixed`, and scanner set. Target changes do not remove checks solely due duration. |
| C2 | constraint | respected | static_check | No GHAS, CodeQL/SARIF upload, SonarCloud, hosted dashboard, or paid/vendor-only requirement introduced in local or target diffs. |
| C3 | constraint | respected | static_check | No frozen reusable gate job names renamed. Local workflow diffs add SBOM keys only; actionlint passed. |
| C4 | constraint | respected | static_check | Slow but valuable checks were not deleted. PokeEdge heavy job is skipped only for draft PRs; Web integration E2E and heartbeat jobs were left unchanged; conditional sharding/splitting remains deferred. |
| C5 | constraint | respected | static_check | Skipped jobs were not treated as free without validation. Design and dry-run report explicitly separate cost/noise and require approval for deletion; target changes preserve summary semantics. |
| C6 | constraint | respected | static_check | App-repo BuildKit/deploy concerns were implemented only in approved PokeEdge-Web/PokeEdge target worktrees after explicit user approval. Local reusable-gate changes remain scoped to gate-owned workflows/docs. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-12ed00f96eca | AC4, AC5, AC8 | AC9 | C1, C2, C3, C6 |  |
| tk-ae2bfbf4ecde | AC4, AC8 | AC9 | C1, C2, C3 |  |
| tk-f350017d48cd | AC2, AC3, AC4, AC5, AC6, AC10 | AC9 | C1, C2, C4, C5 |  |
| tk-03ec14128462 | AC1, AC3, AC4, AC7, AC10 | AC9 | C1, C2, C4, C5 |  |
| tk-8b289be51871 | AC5 | AC1, AC2 | C5, C6 |  |
| tk-5448abcb81a8 |  | AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10 | C1, C2, C3, C4, C5, C6 |  |
| tk-073510504dde |  | AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9, AC10 | C1, C2, C3, C4, C5, C6 |  |
