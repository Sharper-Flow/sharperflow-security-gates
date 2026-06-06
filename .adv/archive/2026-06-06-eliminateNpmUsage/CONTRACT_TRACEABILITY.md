# Contract Traceability

**Change ID:** eliminateNpmUsage
**Contract Version:** 1
**Rigor:** minimal
**Reviewed:** 2026-06-06T21:59:42.722Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | pokeedge-web executable+high-value surfaces npm/npx→bun: package.json + scripts (#97), AGENTS.md + CONTRIBUTING.md + test-file headers + playwright.config*.ts + ci-workflows spec flipped to forbid npm (#97); CI-path npm version (#96). rg confirms zero npm/npx in those surfaces. |
| AC2 | acceptance_criterion | pass | test | pokeedge run_live.sh + sync_frontend.sh npm run→bun run (#281); rg zero npm/npx in pokeedge scripts. |
| AC3 | acceptance_criterion | pass | test | Zero npm/npx across executable + high-value surfaces (verified). Long-tail human-doc prose intentionally deferred (docs don't execute; ~zero security value). Legit refs excluded per agreement: Dockerfile bun-bootstrap, npm-audit historical reporting, SETUP pnpm-install option, slop-smells detection rule, acp-mux package, benchmark-temporal usage comment. |
| C1 | constraint | respected | static_check | Replaced with each repo's standard tool (web→bun); no new package manager introduced. |
| C2 | constraint | respected | static_check | Script behavior preserved (flags/args; dev-stack process detection keys on 'vite dev', unaffected; version stamp logic equivalent). |
| C3 | constraint | respected | static_check | No CI 'no-npm' guard added (declined). Discipline is by convention + the separate enforceLifecycleScriptBlocking change for the real defense. |
| DONT1 | avoidance | respected | review | No npm/npx introduced in executable/high-value surfaces. |
| DONT2 | avoidance | respected | review | No package manager changed; bun/pnpm/uv standard preserved. |
| DONT3 | avoidance | respected | review | Legit references NOT corrupted — Dockerfile bun-bootstrap, npm-audit reporting, pnpm-install option, slop detection rule all left intact; blind prose sweep deliberately avoided. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-7faa0c26ebe5 | AC1 |  | C1, C2, DONT1 |  |
| tk-006f27ec73e4 | AC2 |  | C1, C2, DONT1 |  |
| tk-0c295ca1d4e5 |  | AC1, AC2, AC3 |  |  |
