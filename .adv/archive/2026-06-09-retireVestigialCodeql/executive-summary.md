# Executive Summary — Retire vestigial CodeQL

## Outcome

PokeEdge was running a GitHub-managed CodeQL scan on every push/PR, burning Actions minutes with no payoff. It is now **disabled**, the orphan config is **deleted**, and the org CI standard now **explicitly documents** the decision so no future repo re-inherits it.

## What the investigation uncovered (the real story)

The initial premise ("vestigial security CodeQL, results paywalled") was *half* right — and the diligence corrected it mid-flight:

- The scan actually running was **GitHub Code Quality** (public preview), **not** security CodeQL. Two distinct GitHub features that share the `dynamic/github-code-scanning/codeql` workflow.
- **Code Quality**: preview, **not billed yet but bills at GA**, burns Actions minutes now, reports to a **hosted dashboard**, available on Team plan (hence running without GHAS). Results *are* visible — so the original "false assurance / invisible" framing was wrong for this feature and was corrected in the doc.
- **Security CodeQL / code scanning**: genuinely paywalled on private + Team + no-GHAS (`403`), never usable here.

Both retired under the standard's frozen posture (no GHAS, no SARIF, no hosted dashboard, no Sonar).

## The gh-CLI alignment question (resolved correctly)

User pushed to "align via gh CLI" rather than manual UI. Empirically exhausted the wrong API first (`code-scanning/default-setup` → 403; Actions `disable` → 422 for dynamic workflows), then found the **correct, non-paywalled** path: the dedicated **Code Quality API** —
`gh api -X PATCH repos/<org>/<repo>/code-quality/setup -f state=not-configured`.
Clean CLI disable, no UI handoff. Verified `state=not-configured`.

## Delivered

- `docs/ci-standard.md` — accurate CodeQL-retired block distinguishing both features, with the CLI disable command + forward-pointer to the deferred dataflow gap (commit ed4d601).
- **PokeEdge** — Code Quality disabled (CLI); orphan `.github/codeql/codeql-config.yml` removed via **PR #353 (merged)**.
- **PokeEdge-Web** — confirmed already clean (no change).
- **deepenSastDataflow** followup change opened — the genuine interprocedural-taint gap CodeQL leaves (Semgrep CE is intraprocedural; cross-function = Pro-only), parked for a decision session.

## Verification

- Code Quality `not-configured` on both app repos; no CodeQL runs after the ~02:45Z cutover.
- PR #353 merged → config file 404 on `main`.
- `Sharperflow CI Gate` remains the sole required check on both repos (ruleset 17335746); the `codeql` context was never and is never required.
- Contract matrix: 13/13 pass/respected, 0 failing.

## Reversibility

Every step reversible: Code Quality re-enable (`state=configured`), PR revert, doc revert. No irreversible action.

## Follow-ups

- `deepenSastDataflow` — dataflow SAST decision (Semgrep taint-mode / Opengrep / accept CE ceiling).
- Separate workflow-hygiene change (pending) — clean up unnecessary GitHub Actions/workflows across app repos (5 `disabled_manually` PokeEdge workflows seeded + active-workflow review + PokeEdge-Web sweep).