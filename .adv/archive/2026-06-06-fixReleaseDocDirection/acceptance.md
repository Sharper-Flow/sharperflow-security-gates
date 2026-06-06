# Acceptance

Reviewed at: 2026-06-06T20:03:51.847Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | **AC1** `docs/ci-standard.md` presents tag-only as the Sharperflow default (semantic-release tags but pushes no commit to main; ruleset stays strict, `bypass_actors: []`), with the GitHub App bypass demoted to a clearly-labeled escape hatch ("only if your release must push commits to main"). No language recommending bypass as the preferred approach. | pass | ci-standard.md '### Release automation' (renamed from '...& ruleset bypass'): tag-only is the default/required (semantic-release tags, no commit to main, ruleset strict bypass_actors[]); App bypass demoted to labeled escape hatch. grep: no preferred/recommended-bypass framing remains. heading present at line 257. |
| AC2 | acceptance_criterion | **AC2** `scripts/apply-ruleset.sh` help + guard messaging reframed so applying with no bypass (`--no-release-bypass`) reads as the normal tag-only path; bypass flags documented as opt-in escape hatch. Script flags/logic unchanged; shellcheck clean. | pass | apply-ruleset.sh header+usage describe --no-release-bypass as NORMAL tag-only path, --bypass-* as escape hatch; guard message reframed to 'release mode not specified'. shellcheck PASS; guard still exit 2; all flags + bypass-injection logic retained (capability unchanged). |
| AC3 | acceptance_criterion | **AC3** `README.md` release-automation pointer + the ci-standard conformance-checklist item aligned with tag-only default. | pass | README release-automation blockquote: tag-only default + --no-release-bypass, bypass escape hatch, points to #release-automation. ci-standard conformance-checklist items updated to tag-only default + verify-tag/staging-stamp; admin-enforcement bullet updated (no 'only permitted bypass is release identity'). |
| AC4 | acceptance_criterion | **AC4** self-test + actionlint + shellcheck green; grep confirms no "preferred"/recommended-bypass framing remains. | pass | shellcheck PASS, actionlint PASS, self-test presence parity ok; grep confirms no preferred/recommended bypass framing (only unrelated optional-conventions line) and tag-only present in both docs. |
| C1 | constraint | Documentation + messaging only — do NOT change apply-ruleset.sh flags/logic or the ruleset JSON. | respected | Docs/messaging only: apply-ruleset.sh flags (--bypass-app-id/team/user, --no-release-bypass) + guard logic + python bypass-injection unchanged; ruleset JSON untouched. |
| C2 | constraint | Do not alter security-gate workflows or composites. | respected | No security-gate workflows or composites modified; only docs/ci-standard.md, scripts/apply-ruleset.sh wording, README.md. |
| DONT1 | avoidance | Do not remove the bypass capability (stays as escape hatch). | respected | Bypass capability retained as documented escape hatch (flags + injection logic present); not removed. |
| DONT2 | avoidance | Do not change ruleset enforcement or no-op the guard. | respected | Guard not no-opped — still requires an explicit release-mode choice and exits 2 when neither --no-release-bypass nor a --bypass-* flag is given; ruleset enforcement unchanged. |

