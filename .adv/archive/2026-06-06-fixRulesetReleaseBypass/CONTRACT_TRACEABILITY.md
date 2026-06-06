# Contract Traceability

**Change ID:** fixRulesetReleaseBypass
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-06T17:51:38.718Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | apply-ruleset.sh: --bypass-app-id/RELEASE_BYPASS_APP_ID→Integration always; --bypass-team-id/--bypass-user-id cloud fallbacks; python-composed payload to mktemp (trap-cleaned); refuse-without-bypass guard exit 2 unless --no-release-bypass. Verified: shellcheck PASS; no-bypass→exit 2; --bypass-app-id 123 --dry-run injects {actor_id:123,Integration,always}. |
| AC2 | acceptance_criterion | pass | test | rulesets/sharperflow-app-protection.json unchanged: bypass_actors==[], required context==['Sharperflow CI Gate'], strict true. Real id injected only at apply time; no committed placeholder/fake id (hardcode scan clean). |
| AC3 | acceptance_criterion | pass | test | ci-standard.md '### Release automation & ruleset bypass': semantic-release pushes to default branch → release identity MUST be bypass actor; recommends GitHub App + create-github-app-token + {Integration, always}; App ID not install/client id; contents:write; tags unaffected (target:branch); cloud Team/User fallback. |
| AC4 | acceptance_criterion | pass | test | Runbook guidance: ci-standard.md states committed bypass_actors stays [] and apply-script refuses without a bypass; README blockquote pointer added; 2 conformance-checklist items (apply with --bypass-app-id; verify a release post-apply). App/secret/release.yml wiring noted as consumer scope. |
| AC5 | acceptance_criterion | pass | test | shellcheck PASS, actionlint PASS, self-test docs/presence PASS, ruleset JSON base assertions PASS (bypass_actors==[]). Reviewer independently re-ran all and confirmed. |
| C1 | constraint | respected | static_check | Required 'Sharperflow CI Gate' rule + normal PR gating unchanged; only apply-time bypass for the release identity added. |
| C2 | constraint | respected | static_check | Bypass scoped to release automation (App/Team/User release identity); no broad/human/OrganizationAdmin-for-everyone bypass introduced. |
| C3 | constraint | respected | static_check | No hardcoded secret/PAT/real actor id committed; ids supplied via flags/env at apply time (reviewer hardcode scan clean). |
| DONT1 | avoidance | respected | review | GitHub App path recommended as primary; bare User documented only as a non-portable cloud fallback, not relied upon. |
| DONT2 | avoidance | respected | review | No literal placeholder actor id committed; base bypass_actors stays [] and is composed at apply time. |
| DONT3 | avoidance | respected | review | Only sharperflow-security-gates files touched (apply-ruleset.sh, ci-standard.md, README.md); no pokeedge/pokeedge-web release.yml edits. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-a84256914f3e | AC1, AC2 | AC1 | C1, C2, C3, DONT2 |  |
| tk-1758649dc925 | AC3, AC4 |  | C2, DONT1, DONT3 |  |
| tk-04718f911f9d | AC5 | AC1, AC2, AC5 |  |  |
