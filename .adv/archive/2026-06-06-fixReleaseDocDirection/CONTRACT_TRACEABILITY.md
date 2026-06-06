# Contract Traceability

**Change ID:** fixReleaseDocDirection
**Contract Version:** 1
**Rigor:** minimal
**Reviewed:** 2026-06-06T20:03:51.847Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | ci-standard.md '### Release automation' (renamed from '...& ruleset bypass'): tag-only is the default/required (semantic-release tags, no commit to main, ruleset strict bypass_actors[]); App bypass demoted to labeled escape hatch. grep: no preferred/recommended-bypass framing remains. heading present at line 257. |
| AC2 | acceptance_criterion | pass | test | apply-ruleset.sh header+usage describe --no-release-bypass as NORMAL tag-only path, --bypass-* as escape hatch; guard message reframed to 'release mode not specified'. shellcheck PASS; guard still exit 2; all flags + bypass-injection logic retained (capability unchanged). |
| AC3 | acceptance_criterion | pass | test | README release-automation blockquote: tag-only default + --no-release-bypass, bypass escape hatch, points to #release-automation. ci-standard conformance-checklist items updated to tag-only default + verify-tag/staging-stamp; admin-enforcement bullet updated (no 'only permitted bypass is release identity'). |
| AC4 | acceptance_criterion | pass | test | shellcheck PASS, actionlint PASS, self-test presence parity ok; grep confirms no preferred/recommended bypass framing (only unrelated optional-conventions line) and tag-only present in both docs. |
| C1 | constraint | respected | static_check | Docs/messaging only: apply-ruleset.sh flags (--bypass-app-id/team/user, --no-release-bypass) + guard logic + python bypass-injection unchanged; ruleset JSON untouched. |
| C2 | constraint | respected | static_check | No security-gate workflows or composites modified; only docs/ci-standard.md, scripts/apply-ruleset.sh wording, README.md. |
| DONT1 | avoidance | respected | review | Bypass capability retained as documented escape hatch (flags + injection logic present); not removed. |
| DONT2 | avoidance | respected | review | Guard not no-opped — still requires an explicit release-mode choice and exits 2 when neither --no-release-bypass nor a --bypass-* flag is given; ruleset enforcement unchanged. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-94df2d3e0a15 | AC1 |  | C1, DONT1 |  |
| tk-5749a69c3901 | AC2, AC3 |  | C1, DONT2 |  |
| tk-8d909dd6fa2c |  | AC1, AC2, AC3, AC4 |  |  |
