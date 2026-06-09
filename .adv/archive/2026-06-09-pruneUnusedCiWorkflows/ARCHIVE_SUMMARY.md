# Archive: Prune unused CI workflows

**Change ID:** pruneUnusedCiWorkflows
**Archived:** 2026-06-09T03:33:01.659Z
**Created:** 2026-06-09T02:52:08.543Z

## Tasks Completed

- ✅ Add workflow-hygiene rule to docs/ci-standard.md
  > Task checkpoint completed
- ✅ Delete 4 dead/disabled workflow files on PokeEdge via squash PR
  > Task checkpoint completed
- ✅ Disable PokeEdge-Web Copilot coding agent (managed)
  > Task checkpoint completed
- ✅ Confirm ghost records + final verification
  > Task checkpoint completed

## Specs Modified


## Wisdom Accumulated

- **[gotcha]** GitHub "Code Quality" (public preview) is a SEPARATE feature from security CodeQL/code-scanning — do not conflate. Both run the same `dynamic/github-code-scanning/codeql` workflow (runs show as workflowName "CodeQL", run-name "Code Quality: ..."), but they have different APIs and gating:
- Security code scanning: `code-scanning/default-setup` API is GHAS-gated → returns `403 Code Security must be enabled` on private+Team+no-GHAS. Cannot manage via CLI. Actions `disable` endpoint also refuses dynamic workflows (`422`).
- Code Quality: `code-quality/setup` API is NOT paywalled → `gh api -X PATCH repos/{o}/{r}/code-quality/setup -f state=not-configured` disables it cleanly via CLI. `GET` returns {state,languages,schedule,runner_type}.
To identify which mechanism runs a CodeQL scan: `gh api repos/{o}/{r}/actions/runs/{id} --jq .path` → `dynamic/github-code-scanning/codeql` + `event:dynamic` = GitHub-managed (no committed .yml). Code Quality is preview/free-now but bills at GA and burns Actions minutes; reports to a hosted dashboard.
