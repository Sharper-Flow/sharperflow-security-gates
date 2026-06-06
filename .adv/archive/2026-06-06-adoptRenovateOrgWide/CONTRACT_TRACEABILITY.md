# Contract Traceability

**Change ID:** adoptRenovateOrgWide
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-06T23:42:38.199Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | default.json on main (PR #7, #8). renovate-config-validator: 'Config validated successfully against 2 files'. Extends config:recommended+pinGitHubActionDigests+docker:pinDigests; minimumReleaseAge 7d (null'd for lockFileMaintenance/pin/replacement); platformAutomerge; lockFileMaintenance; vulnerabilityAlerts. |
| AC2 | acceptance_criterion | pass | test | All 4 default branches verified: security-gates extends local>Sharper-Flow/sharperflow-security-gates; pokeedge/web/advance extend github>Sharper-Flow/sharperflow-security-gates. advance adds pnpm-subpackage grouping. Merged: #283 (pokeedge), #100 (web), #146 (advance). |
| AC3 | acceptance_criterion | pass | test | Org ruleset 'Sharperflow App Protection' (active) requires check 'Sharperflow CI Gate' on default branch (pokeedge/web). allow_auto_merge: pokeedge=true, web=true, security-gates=true, advance=false. platformAutomerge waits for required check → merges only green. Majors/prod now automerge on green (amended); advance deferred (automerge:false + allow_auto_merge off). |
| AC4 | acceptance_criterion | pass | test | Renovate (Mend) App installed on org — confirmed by live pokeedge dependency dashboard (user screenshot). Onboarding PRs N/A: each repo had renovate.json before Renovate's first run, so Renovate skipped onboarding and went straight to scanning. Preset now resolves from main (original 'Cannot find preset' error was pre-#7-merge). |
| AC5 | acceptance_criterion | pass | test | pokeedge .github/dependabot.yml absent: gh api contents 404, .github/ listing has no dependabot.yml, code search empty. Renovate is sole updater. |
| AC6 | acceptance_criterion | pass | test | docs/ci-standard.md '## Dependency updates (Renovate)' updated: shared preset, 7d cooldown (security-exempt), automerge-only-merges-green + test-suite-as-review for majors/prod, advance deferral, one-updater rule. README pin-policy line → Renovate. Stale 'Dependabot maintains pins' replaced. |
| C1 | constraint | respected | static_check | dependencyDashboard:true = in-repo GitHub issue. Mend hosted dashboard is convenience, not a requirement; no workflow depends on it. |
| C2 | constraint | respected | static_check | pokeedge Dependabot absent; Renovate sole updater across all 4 repos. |
| C3 | constraint | respected | static_check | config:recommended auto-detects pep621(uv)/bun/npm(pnpm)/github-actions/docker. advance pnpm-subpackage grouping added; subdirs auto-detected. |
| C4 | constraint | respected | static_check | minimumReleaseAge lives only in the Renovate preset; not duplicated in enforceLifecycleScriptBlocking. |
| DONT1 | avoidance | respected | review | No repo runs two updaters: pokeedge dependabot.yml removed/absent; Renovate is the only configured updater everywhere. |
| DONT2 | avoidance | respected | review | AMENDED by explicit user decision. Original 'do not automerge major/prod unreviewed' is upheld in spirit: updates are NOT unreviewed — every automerge is gated on 'Sharperflow CI Gate' (full functional suite: unit+integration(pgvector)+e2e(playwright)+contract on pokeedge/web), and Renovate merges only green. The test suite is the review (machine, not human, per user). A breaking major/prod update fails the suite → PR stays red → never merges. 7-day cooldown means every merged release survived a week. advance (no functional gate) double-guarded: automerge:false + allow_auto_merge off. |
| DONT3 | avoidance | respected | review | platformAutomerge uses GitHub native auto-merge which cannot bypass the required 'Sharperflow CI Gate' check. No --admin bypass wired into automerge path. |
| DONT4 | avoidance | respected | review | Only renovate.json/default.json + docs touched. No release.yml or tag-trigger workflow modified across any repo. Tag-only release flow intact. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-75a2f3c95402 | AC1, AC2 |  | C1, C3 |  |
| tk-59f72493ef6f | AC3, AC4 |  | C2, DONT2, DONT3 |  |
| tk-20506d4ec821 | AC6 |  | C2 |  |
| tk-3f2bcdfdf267 | AC2 |  | C1, C3, DONT1 |  |
| tk-eef3d08d97f4 | AC5 |  | DONT1 |  |
| tk-1944ef3dff3e |  | AC1, AC2, AC3, AC4, AC5, AC6 |  |  |
