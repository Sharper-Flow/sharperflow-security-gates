# Executive Summary — adoptRenovateOrgWide

Renovate is now the single, org-wide dependency updater across all 4 Sharper Flow repos (security-gates, pokeedge, pokeedge-web, advance), replacing the lone pokeedge Dependabot setup. One shared preset governs every repo; updates auto-merge only after the repo's real CI gate passes.

## What was built
- **Shared preset** `default.json` (security-gates root) — `config:recommended` + GitHub-Action/Docker digest pinning, **7-day supply-chain cooldown** (`minimumReleaseAge`), security fixes cooldown-exempt, `lockFileMaintenance`, `vulnerabilityAlerts`, dev-dep grouping.
- **Per-repo `renovate.json` ×4** extending the preset (advance adds pnpm-subpackage grouping).
- **`docs/ci-standard.md` + `README.md`** — documented policy; retired the stale "Dependabot maintains pins" guidance.

## Automerge policy (amended mid-flight by user decision)
Original conservative policy (automerge dev/patch-minor only; majors + production deps → human PR) was **superseded**: the preset now sets top-level `automerge: true` so **all update types — including majors and production deps — auto-merge once the repo's required check is green**.

Rationale: pokeedge and web require `Sharperflow CI Gate`, a **real functional suite** (unit + integration on pgvector Postgres + Playwright e2e + contract). Renovate merges **only green**, so a breaking update fails the suite, the PR stays open red, and never merges. The test suite is the review — a human gate nobody would actually use was adding no safety. The 7-day cooldown means every auto-merged release already survived a week in the wild.

**advance is the deliberate exception** — it has no `Sharperflow CI Gate` yet (deferred until `conformAdvanceCi`), so it is double-guarded: `automerge: false` in its config **and** repo "Allow auto-merge" off.

## Verified
- `renovate-config-validator`: preset + security-gates config validate clean.
- All 4 default branches carry the extending `renovate.json`; advance override present.
- Org ruleset `Sharperflow App Protection` requires `Sharperflow CI Gate`; `allow_auto_merge` armed on pokeedge/web/security-gates, off on advance.
- Renovate App installed (pokeedge dependency dashboard live); pokeedge Dependabot absent (one updater).

## Follow-ups (separate changes)
- **Agent dependency-PR reviewer** — optional extra signal (changelog/deprecation reading) on top of the test gate. Deferred as its own proposal; not a safety dependency.
- **advance automerge** — enable once `conformAdvanceCi` provides a functional `Sharperflow CI Gate`.