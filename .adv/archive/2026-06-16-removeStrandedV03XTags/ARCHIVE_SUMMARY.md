# Archive: Remove stranded v0.3.x tags

**Change ID:** removeStrandedV03XTags
**Archived:** 2026-06-16T02:48:14.622Z
**Created:** 2026-06-16T00:47:51.963Z

## Tasks Completed

- ✅ Harden auto-release.yml base-version selection + idempotency
  > Replaced `git describe --tags --abbrev=0` base selection in `.github/workflows/auto-release.yml` with an ancestor-restricted highest-semver scan (loop over `git tag` filtered by `git merge-base --is-ancestor`, max via `sort -V`). Added an idempotency guard before tagging that sets skip=true if the computed NEW_TAG already exists. Verified with actionlint and a local logic test.
- ✅ Document version-line jump + auto-release behavior
  > Added 'Release line & versioning (this repo)' subsection to docs/ci-standard.md (Pin policy section): auto-release on merge, highest-semver-ancestor base selection, v0.3.x stranding cause, v0.4.0 forward jump (leave v0.3.x installable), consumer SHA-pin + Renovate retarget guidance. Fixed the stale `@5afaf289 # v0.3.2` pin example to `# v0.4.0` and corrected the PokeEdge/PokeEdge-Web consumer matrix (PR #109 closed, alerts enabled, retarget to v0.4.x).
- ✅ Seed v0.4.0 release from fixed main + roll floating v0 (operator release op)
  > Created GitHub release v0.4.0 via `gh release create --target 4606d05` (fixed main HEAD, quoted composite), making it the highest semver tag superseding the stranded broken v0.3.2. Rolled floating v0 ref to 4606d05 via `gh api PATCH .../git/refs/tags/v0`. Recorded release id 339871391 and prior v0 sha f365a1b for reversibility. v0.3.x left installable per OOS1.
- ✅ Verify version-line jump, hardening, and consumer retarget
  > Acceptance + harden verification/remediation: refreshed all live docs/examples/ROADMAP pins to `4606d0547f41ea7edacfd40ff90c7b71d3449e3f # v0.4.0`; tightened auto-release stable semver filtering and strict shell mode; aligned `project.md` and auto-release release notes with SHA-pin-first policy. Verification passed: actionlint, ruleset invariant, file presence invariant, stale-pin exact search, and policy-phrase searches. Latest checkpoint `690048ec0c3256c380ecbca141ec6b1f0ac23c29`. AC2 remains async, tracked by `ag-kuscC15R`.

## Specs Modified


## Wisdom Accumulated

- **[gotcha]** In GitHub Actions `run: |` blocks, heredocs (`<<EOF`) break because the terminator must be column-0 but YAML indents everything; `<<-EOF` only strips tabs, not the spaces YAML uses. Use a bash here-string (`done <<< "$VAR"`) instead — it runs the while-loop in the current shell (so loop-set variables persist) and has no indentation-sensitive terminator. For "latest maintained release," select the highest-semver tag that is an ANCESTOR of HEAD (`git merge-base --is-ancestor` + `sort -V | tail -1`), not nearest-ancestor `git describe --abbrev=0`, which silently regresses when higher-semver tags strand on older commits.
