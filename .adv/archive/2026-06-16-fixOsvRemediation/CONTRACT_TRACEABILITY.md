# Contract Traceability

**Change ID:** fixOsvRemediation
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-16T00:08:49.705Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| SC1 | success_criterion | pass | review | `default.json` keeps `vulnerabilityAlerts.enabled` + `labels:["security"]`; docs state next Renovate run timing and prerequisites; PokeEdge-Web missing alerts documented as prerequisite gap. |
| SC2 | success_criterion | pass | review | OSV Scanner action retained in both reusable gates; only help text added; missing lockfile skip unchanged; docs state findings remain blocking unless fixed/ignored. |
| SC3 | success_criterion | pass | review | Workflow help steps add local reproduction command; docs specify OSV Scanner step log + advisory/package/version/fixed-version target; table output remains terminal-readable. |
| SC4 | success_criterion | pass | review | `docs/ci-standard.md` documents Dependency graph/Dependabot alerts/Renovate permission prerequisites, next-run timing, and direct-vs-transitive limitations. |
| SC5 | success_criterion | pass | review | PokeEdge/PokeEdge-Web matrix documents lockfile/gate version, alert setting, auto-merge path, and follow-up; PokeEdge-Web alert gap and PR #109 noted. |
| AC1 | acceptance_criterion | pass | test | Renovate config validator passed. `default.json` retains stable `vulnerabilityAlerts` baseline; docs identify GitHub alert prerequisites and next-run behavior. |
| AC2 | acceptance_criterion | pass | test | Actionlint passed; both reusable gates still invoke `google/osv-scanner-action/...# v2.3.8` gated on lockfile existence with no failure suppression. |
| AC3 | acceptance_criterion | pass | test | Both gates write `$GITHUB_STEP_SUMMARY` remediation help with local `osv-scanner --lockfile=... --format=table`; docs direct maintainers to OSV Scanner step log for advisory/package/version/fixed-version. |
| AC4 | acceptance_criterion | pass | test | `docs/ci-standard.md` lines around Renovate security remediation include prerequisites, “next Renovate run”, and direct/transitive fallback guidance. |
| AC5 | acceptance_criterion | pass | test | Design and docs record `osvVulnerabilityAlerts` evaluated and deferred due experimental/direct-dep scope and indirect-churn risk. |
| AC6 | acceptance_criterion | pass | test | `bunx --package renovate renovate-config-validator default.json renovate.json` passed; `docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7` passed after review remediation. |
| AC7 | acceptance_criterion | pass | test | Consumer verification: PokeEdge alerts HTTP 204; PokeEdge-Web alerts HTTP 404; docs table includes PokeEdge `python-security-gate.yml@v0.3.2`, PokeEdge-Web `javascript-security-gate.yml@v0.2.1` + PR #109, auto-merge path, follow-up. |
| C1 | constraint | respected | static_check | OSV scanner action retained; docs state lockfile vulnerabilities remain blocking unless fixed or intentionally ignored. |
| C2 | constraint | respected | static_check | Diff does not rename `Sharperflow CI Gate`; actionlint passed. |
| C3 | constraint | respected | static_check | No workflow-level `paths:` filters added; review diff limited to reusable gate job steps and docs/config. |
| C4 | constraint | respected | static_check | Renovate config change validated by `renovate-config-validator`; behavior not prose-only. |
| C5 | constraint | respected | static_check | Workflow summary help and docs provide actionable GitHub Actions/job-log remediation path. Preview URL proof: not_applicable; agreement `visual_surface:false`, touched files are config/workflows/docs only, no browser-visible output. |
| C6 | constraint | respected | static_check | Docs and review evidence cover PokeEdge Python/uv and PokeEdge-Web Bun/Node flows separately. |
| DONT1 | avoidance | respected | review | OSV failures remain blocking; no conversion to warnings or continue-on-error. |
| DONT2 | avoidance | respected | review | Docs say security fixes move on next Renovate run, not weekly normal-update schedule; `vulnerabilityAlerts` retained. |
| DONT3 | avoidance | respected | review | Docs identify Renovate/security PR path and manual fallback; not ad-hoc feature/archive PR bumps as primary path. |
| DONT4 | avoidance | respected | review | Docs retain one-updater-per-ecosystem rule; no Dependabot config added. |
| DONT5 | avoidance | respected | review | PokeEdge-Web disabled vulnerability alerts and stale gate pin PR #109 are explicitly documented in consumer table and follow-up. |
| OOS1 | out_of_scope | not_applicable | not_applicable | No dependency updater replacement; Renovate remains baseline. |
| OOS2 | out_of_scope | not_applicable | not_applicable | No broad dependency policy redesign; changes target vulnerability remediation visibility/timing only. |
| OOS3 | out_of_scope | not_applicable | not_applicable | No manual dependency bumps in caller repos performed. |
| OOS4 | out_of_scope | not_applicable | not_applicable | No branch-protection/check-name posture changes; `Sharperflow CI Gate` preserved. Preview URL not_applicable because no visual surface changed. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-1c369c0c01bc | AC1, AC5 | AC1, AC5, AC6 | C1, C4, DONT1, DONT2, DONT4 |  |
| tk-6c5a7a980538 | AC2, AC3 | AC2, AC3, AC6 | C1, C2, C3, C5, DONT1 |  |
| tk-c2eeaed7dd87 | AC7 | SC5, AC1, AC7 | C2, C6, DONT3, DONT5 |  |
| tk-a454ae410fb8 | SC1, SC3, SC4, SC5, AC1, AC3, AC4, AC5, AC7 | AC3, AC4, AC5, AC7 | C1, C2, C3, C5, C6, DONT1, DONT2, DONT3, DONT4, DONT5, OOS1, OOS2, OOS3, OOS4 |  |
| tk-1fdb1f88bb10 |  | SC1, SC2, SC3, SC4, SC5, AC1, AC2, AC3, AC4, AC5, AC6, AC7 | C1, C2, C3, C4, C5, C6, DONT1, DONT2, DONT3, DONT4, DONT5, OOS1, OOS2, OOS3, OOS4 |  |
