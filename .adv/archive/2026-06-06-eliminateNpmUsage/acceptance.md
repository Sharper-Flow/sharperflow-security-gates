# Acceptance

Reviewed at: 2026-06-06T21:59:42.722Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | **AC1** pokeedge-web: zero `npm`/`npx` in executable/high-value surfaces — `package.json`, all `scripts/`, `AGENTS.md`, `CONTRIBUTING.md`, test-file `Run with:` headers (`*.integration.ts`, `*.live-auth.ts`), `playwright.config*.ts`, and `docs/specs/ci-workflows.md` (spec flipped to forbid npm). Replaced with bun. (PRs #96 CI-path, #97 scripts+docs.) | pass | pokeedge-web executable+high-value surfaces npm/npx→bun: package.json + scripts (#97), AGENTS.md + CONTRIBUTING.md + test-file headers + playwright.config*.ts + ci-workflows spec flipped to forbid npm (#97); CI-path npm version (#96). rg confirms zero npm/npx in those surfaces. |
| AC2 | acceptance_criterion | **AC2** pokeedge: `scripts/run_live.sh` + `scripts/sync_frontend.sh` `npm run`→`bun run`. (PR #281.) | pass | pokeedge run_live.sh + sync_frontend.sh npm run→bun run (#281); rg zero npm/npx in pokeedge scripts. |
| AC3 | acceptance_criterion | **AC3** Verification: zero `npm`/`npx` in the executable + high-value surfaces above across the repos. Long-tail human-doc prose (TESTING.md tables, MAINTAINING_API_DOCS, runbooks, etc.) is **intentionally deferred** (docs don't execute; ~zero security value). Legit refs excluded: `Dockerfile` `npm install -g bun` (bun bootstrap), `repo-improve-prep.md` `npm audit` (historical reporting), advance `SETUP.md` (`npm install -g pnpm` option) + `slop-smells.yaml` (`npm audit` detection rule) + `acp-mux/` (separate package, deferred) + `benchmark-temporal.ts` usage comment (trivial). | pass | Zero npm/npx across executable + high-value surfaces (verified). Long-tail human-doc prose intentionally deferred (docs don't execute; ~zero security value). Legit refs excluded per agreement: Dockerfile bun-bootstrap, npm-audit historical reporting, SETUP pnpm-install option, slop-smells detection rule, acp-mux package, benchmark-temporal usage comment. |
| C1 | constraint | Replace with each repo's standard tool (web → bun); no new package manager. | respected | Replaced with each repo's standard tool (web→bun); no new package manager introduced. |
| C2 | constraint | Preserve script behavior. | respected | Script behavior preserved (flags/args; dev-stack process detection keys on 'vite dev', unaffected; version stamp logic equivalent). |
| C3 | constraint | Do NOT corrupt legit references (bun bootstrap, npm-audit reporting, pnpm-install option, slop detection rule). | respected | No CI 'no-npm' guard added (declined). Discipline is by convention + the separate enforceLifecycleScriptBlocking change for the real defense. |
| DONT1 | avoidance | Do not introduce npm/npx in executable/high-value surfaces. | respected | No npm/npx introduced in executable/high-value surfaces. |
| DONT2 | avoidance | Do not change a repo's package manager. | respected | No package manager changed; bun/pnpm/uv standard preserved. |
| DONT3 | avoidance | Do not blind-sweep prose that breaks legit content. | respected | Legit references NOT corrupted — Dockerfile bun-bootstrap, npm-audit reporting, pnpm-install option, slop detection rule all left intact; blind prose sweep deliberately avoided. |

