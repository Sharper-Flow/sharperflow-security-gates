# Sharperflow CI Standard

The canonical CI contract every Sharper Flow application repository conforms to.

This document is **normative**: where an app's CI disagrees with this standard, the
app is wrong and should be brought into conformance. App-specific gates that this
standard does not mention stay app-owned (see [App-owned gates](#app-owned-gates)).

Source of truth precedence: the reusable workflow/action/ruleset YAML and JSON in
this repo override prose if they conflict. Update this document when that
executable behavior changes.

---

## 1. Pipeline shape

Every app CI workflow follows the same stage order:

```
setup → fast-checks (format/lint/types) → tests + coverage → build → security → summary
```

This arrow notation describes **stage ordering**, not a serial execution chain.
Stages run in parallel where the DAG allows: `fast-checks` and `security` start
concurrently, and `tests`/`build` are gated by `needs:` on upstream jobs. See
[Fail-fast edges](#fail-fast-edges) for the concrete `needs:` wiring that
enforces this ordering.

- **setup** — language toolchain + dependency install, via a shared composite
  action (§4).
- **fast-checks** — formatting, linting, type-checking. Fail fast.
- **tests + coverage** — unit/api/etc. with the app's coverage gates.
- **build** — proves the app compiles/bundles.
- **security** — the reusable Sharperflow security gate, invoked as a job (§3).
- **summary** — the single required check that aggregates everything (§2).

Apps MAY add extra jobs (integration, e2e, contract, migration, complexity). Those
are app-owned and feed the summary like any other job.

---

## 2. Required-check contract

Branch protection requires **exactly one** status check context, identical across
every Sharper Flow app:

```
Sharperflow CI Gate
```

This string is a **frozen contract**. Every consuming repo MUST emit a job whose
GitHub check name is exactly `Sharperflow CI Gate`. If a repo emits a different
name, the required check never reports and PRs wedge on
"Expected — Waiting for status to be reported".

### Why a single summary check

GitHub matches required checks by exact context string. Requiring individual job
names (e.g. `Quality Chain (lint + typecheck + security)` or reusable-workflow
contexts like `caller / reusable-job`) makes branch protection brittle: any job
rename silently breaks the required-context string, and teams compensate with
admin bypass. Requiring only the summary lets internal job topology change freely
while the protection contract stays stable.

### The summary gate (canonical form)

```yaml
ci-gate:
  name: Sharperflow CI Gate            # FROZEN required-context string — do not rename
  if: ${{ !cancelled() }}
  needs: [fast-checks, test, build, security]   # leaf jobs ONLY
  runs-on: ubuntu-latest
  steps:
    - name: Verify required jobs
      env:
        RESULTS: ${{ join(needs.*.result, ',') }}
      run: |
        echo "needs results: $RESULTS"
        IFS=','
        for r in $RESULTS; do
          case "$r" in
            success|skipped) ;;
            *) echo "::error::a required job result was '$r'"; exit 1 ;;
          esac
        done
```

Rules that make this correct:

- **`if: ${{ !cancelled() }}`** (or `always()`) — the gate must run even when an
  upstream job failed, so it can report a terminal failure instead of being
  skipped.
- **Fail on `failure` AND `cancelled`** — a plain `success()`/`failure()` check is
  insufficient under `always()`. The explicit `case` loop treats only `success`
  and `skipped` as passing.
- **A skipped job reports `Success`** in GitHub's check UI and will NOT block a
  merge on its own. Path-skipping is therefore safe to treat as `skipped` → pass,
  but it means the summary loop (not the individual jobs) is the real gate.
- **`needs` lists leaf jobs only.** In a job-level `if`, `needs.*` expands to
  direct **and transitive** dependencies. Keep the summary's `needs` to the actual
  leaf jobs you intend to gate on, and gate on named results if the graph is deep.

### Always-report rule

The workflow that contains the summary MUST trigger on **every** pull request to
the protected branch. Do **not** put a workflow-level `paths:` filter on it — a
path-filtered workflow that does not trigger leaves the required context pending
forever ("stuck Expected"), which is what drives admin-bypass culture.

Scope work by path **inside** the workflow:

```yaml
changes:
  runs-on: ubuntu-latest
  outputs:
    code: ${{ steps.filter.outputs.code }}
  steps:
    - uses: actions/checkout@<sha>  # v4
    - uses: dorny/paths-filter@<sha>  # v3
      id: filter
      with:
        filters: |
          code:
            - 'src/**'
            - 'tests/**'

build:
  needs: changes
  if: ${{ needs.changes.outputs.code == 'true' }}
  ...
```

The expensive jobs skip on out-of-scope changes; the summary still runs and
reports terminal status.

### Fail-fast edges

The arrow notation in §1 describes stage ordering, but GitHub Actions does NOT
automatically enforce it — jobs run in parallel unless `needs:` connects them.
Without explicit fail-fast edges, a `security` failure runs `test`/`build` to
completion, wasting runner minutes on a doomed run.

**Recommended pattern.** Expensive downstream jobs (`test`, `build`) MUST declare
`needs:` on fast upstream checks (`fast-checks`, `security`) so that an upstream
failure skips the expensive downstream jobs instead of running them to completion.

Two acceptable forms:

**Direct** — for simple workflows with few expensive downstream jobs:

```yaml
security:
  needs: fast-checks
  uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/...

test:
  needs: [fast-checks, security]      # security gates test

build:
  needs: [fast-checks, security]      # security gates build
```

**Fast-gate join** — for workflows with many expensive downstream jobs. Introduce
a join job that fans in the fast checks, then every expensive job needs the join:

```yaml
fast-gate:
  needs: [changes, commit-lint, quality-chain, security]
  runs-on: ubuntu-latest
  if: ${{ !cancelled() }}
  steps:
    - run: echo "Fast checks passed"

pr-gate:                              # expensive
  needs: fast-gate

migration-chain:                      # expensive
  needs: fast-gate

contract:                             # expensive
  needs: fast-gate
```

This pattern is used by PokeEdge backend (`pr-gate.yml`): `fast-gate` joins
`security` + other fast checks, and all expensive Stage-3 jobs need `fast-gate`.

**Anti-pattern.** Security as a pure leaf sibling — parallel to `test`/`build`
with no `needs:` edge — provides zero fail-fast signal. A security failure runs
expensive jobs to completion, and the summary gate reports the failure only
after the full run finishes.

```yaml
# WRONG — security is a leaf sibling, not an upstream gate
test:
  needs: [fast-checks]               # security NOT listed

build:
  needs: [fast-checks]               # security NOT listed

security:
  needs: fast-checks                  # parallel to test/build, no edge
```

**Choosing a form.** Use **direct** when the workflow has a small number of
expensive jobs (PokeEdge-Web: `test`, `build`). Use **fast-gate join** when
many expensive jobs all need the same fast-check gates (PokeEdge backend:
`pr-gate`, `migration-chain`, `contract`, `integration`, `e2e`, `acceptance`).
The fast-gate join avoids repeating the same `needs:` list on every job and
keeps the DAG readable.

### Intra-stage sibling gating

The fail-fast edges above cover **stage boundaries** (fast-checks → expensive
jobs). Once a stage is running, **siblings within a stage do not automatically
gate each other** — if one expensive lane fails, parallel siblings run to
completion unless explicitly connected via `needs:`. This section covers
patterns for closing that intra-stage gap.

Three patterns cover the common cases:

**Stage-3-gate join (for many expensive lanes under one fast-gate).** When N
expensive lanes share a fast-gate and one lane (typically the slowest, highest
failure rate) is the canary, introduce a second join job that requires both
`fast-gate` AND the canary lane. Sibling lanes depend on the second join.

```yaml
fast-gate:
  needs: [changes, commit-lint, quality-chain, security]
  if: ${{ !cancelled() }}
  # ... case-loop on needs.*.result accepting success|skipped

# pr-gate is the canary (slowest lane, highest failure rate)
pr-gate:
  needs: fast-gate
  # ... runs 16 min median

stage-3-gate:
  needs: [fast-gate, pr-gate]
  if: ${{ !cancelled() }}
  # ... case-loop on needs.*.result accepting success|skipped

integration:
  needs: [fast-gate, stage-3-gate]   # keep fast-gate for path-scope outputs
  if: ${{ needs.fast-gate.outputs.migrations == 'true' }}

e2e:
  needs: [fast-gate, stage-3-gate]
  if: ${{ needs.fast-gate.outputs.tests == 'true' }}
```

Trade-off: success-path wall-time extends by the canary's duration
(otherwise unchanged); failure-path runner-seconds drop by the siblings'
total duration. On a 33% pr-gate failure rate, this saves ~411s runner-seconds
per failure.

**Skip-cascade requirement (mandatory).** Each modified sibling lane MUST keep
`fast-gate` in its `needs:` so it can read path-scope `outputs.*` via its
`if:` condition. The stage-3-gate's case-loop alone is NOT sufficient — when
`pr-gate` is SKIPPED (path-scope clean PR), the stage-3-gate accepts `skipped`
via its case-loop, but each lane's `if: needs.fast-gate.outputs.X == 'true'`
independently skips it. actionlint enforces this (a lane that references
`fast-gate.outputs` must declare `fast-gate` in `needs:`).

Canonical example: `Sharper-Flow/PokeEdge/.github/workflows/pr-gate.yml` —
`stage-3-gate: needs: [fast-gate, pr-gate]` joins pr-gate into
integration/e2e/acceptance/migration. Pattern: `!cancelled()` + case-loop on
`needs.*.result` accepting `success|skipped`.

**Commit-lint `always()` pattern (for PR-only fast lanes gating test/build).**
When a fast lane runs only on `pull_request` (skipping on push/merge_group),
adding it to test/build `needs:` directly causes test/build to skip on non-PR
events because GitHub Actions skips downstream jobs when their `needs:` is
skipped (unless the `if:` overrides with `always()`).

Use `always()` in the `if:` so the expression evaluates even when needs are
skipped, and check `needs.X.result != 'failure'` (skipped is acceptable,
failure is not):

```yaml
test:
  needs: [changes, lint, typecheck, security, commit-lint]
  if: ${{ always() && !cancelled() && needs.changes.outputs.code == 'true' && needs.commit-lint.result != 'failure' }}
```

Behavior matrix:
- `pull_request` + commit-lint passes: `needs.commit-lint.result == 'success'` → test/build run.
- `pull_request` + commit-lint fails: `needs.commit-lint.result == 'failure'` → test/build skip.
- `push` / `merge_group`: commit-lint skipped (`if: github.event_name == 'pull_request'`) → `needs.commit-lint.result == 'skipped'` → `'skipped' != 'failure'` → test/build run normally.
- workflow cancelled: `!cancelled()` is false → test/build skip.

Canonical example: `Sharper-Flow/PokeEdge-Web/.github/workflows/ci.yml` —
`commit-lint` has `if: github.event_name == 'pull_request'`; the `always()`
pattern preserves push/merge_group behavior while skipping on PR commit-lint
failure. The summary gate (`ci-gate`) already accepts `success|skipped` for
commit-lint, so it is unaffected.

**Notification-gap pattern (commit-lint in notify/heartbeat `needs:`).**
Summary-only failures (ci-gate, commit-lint, future fast-gate joins) cause leaf
jobs to succeed and notification/heartbeat jobs to skip on their
`if: failure()` / `if: always()` conditions. Add summary-only jobs to the
notify/heartbeat `needs:` so they fire on those failures. Also include the
result in any `HEARTBEAT_STATUS` expression that gates the status report:

```yaml
notify-failure:
  needs: [lint, typecheck, test, build, security, commit-lint]   # commit-lint included
  if: failure() && github.ref == 'refs/heads/main'

heartbeat:
  needs: [lint, typecheck, test, build, security, commit-lint]   # commit-lint included
  if: always() && github.ref == 'refs/heads/main'
  env:
    HEARTBEAT_STATUS: ${{ (needs.lint.result == 'failure' || needs.typecheck.result == 'failure' || needs.test.result == 'failure' || needs.build.result == 'failure' || needs.security.result == 'failure' || needs.commit-lint.result == 'failure') && 'down' || 'up' }}
```

Canonical example: `Sharper-Flow/PokeEdge-Web/.github/workflows/ci.yml` —
`notify-failure` and `heartbeat` declare `needs: [lint, typecheck, test,
build, security, commit-lint]`. `HEARTBEAT_STATUS` includes
`|| needs.commit-lint.result == 'failure'`. Without these additions, a
commit-lint-only failure causes the leaf jobs to succeed and the configured
alerts never fire.

**Why this section.** Without intra-stage gating, a fast-gate-protected
failure cascades wasted runner-seconds across N-1 sibling lanes. The cost is
proportional to the number of siblings × their median runtime. Wall-time
penalty on success is proportional to the canary's duration; on failure, all
siblings skip in seconds.

---

## 3. Security gate: permanent and required

The reusable Sharperflow security gate is **permanent and required** — not a
pilot. The "measure before making it required" phase is over.

- Apps invoke the gate as a **job** inside their CI workflow, named `security`,
  listed in the summary `needs`:

  ```yaml
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@4606d0547f41ea7edacfd40ff90c7b71d3449e3f  # v0.4.0
    permissions:
      contents: read
    with:
      python-version: "3.13"
      scan-paths: "api services ..."
      lockfile-path: "uv.lock"
  ```

  Use `javascript-security-gate.yml` for JS/TS apps.

- **It must be a job in the same workflow as the summary.** GitHub `needs:` is
  intra-workflow only — a separately-triggered `security-gates-pilot.yml` workflow
  can never feed the summary gate. Standalone pilot workflows are retired in favor
  of folding the gate into app CI.

- **No inline duplication.** Apps must not also run their own ad-hoc OSV / generic
  Semgrep when the reusable gate already covers it. Repo-specific custom rules
  (e.g. a repo's own `.semgrep/*` rules, IaC `:latest` guardrails) are allowed as a
  thin **separate** local job under the summary.

- **Frozen reusable job names.** The security gate's internal job names
  (`Semgrep + Bandit`, `OSV dependency scan`, `Gitleaks secret scan`,
  `Trivy filesystem scan`) are published API. Renaming them changes the
  `caller / reusable-job` context strings. Apps require only the summary, but the
  job names stay stable as a contract.

- **Scanner responsibility partition.** Secret scanning is partitioned by gate
  type to avoid redundant work:

  | Gate type | Secret scanner | Rationale |
  |-----------|---------------|-----------|
  | Source-code (python, javascript) | Gitleaks | Full git history, allowlists, redaction |
  | Container image | Trivy `secret` | No git history in built images |

  Trivy in source-code gates runs `vuln,misconfig` only — Gitleaks owns secrets.
  Trivy in the container gate runs `vuln,secret` — it is the sole secret scanner
  for images. Callers that need additional secret scanning should add a local job,
  not re-enable Trivy `secret` in the reusable gate.

---

## 4. Shared building blocks

Setup is defined once in this repo and consumed cross-repo, never copy-pasted.

| Composite | Path | Inputs |
|---|---|---|
| Python + uv | `.github/actions/setup-python-uv` | `python-version` (def `3.13`), `sync-args` (def `--all-groups`), `cache-key-suffix` |
| Bun + Node | `.github/actions/setup-bun-node` | `node-version` (def `24`), `bun-version`, `install-mode` (`ci`\|`install`) |

Consumed from an app workflow:

```yaml
- uses: Sharper-Flow/sharperflow-security-gates/.github/actions/setup-python-uv@4606d0547f41ea7edacfd40ff90c7b71d3449e3f  # v0.4.0
  with:
    python-version: "3.13"
    sync-args: "--all-groups"
```

Cross-repo composite actions resolve by `owner/repo/.github/actions/<name>@<ref>`.
Same-org private access works on the org's Team plan; no manual checkout of this
repo is required.

---

## 5. Pin policy (LBP + supply-chain)

Every `uses:` of an org reusable workflow or composite action — and every action
inside the composites themselves — pins a **full commit SHA with a trailing
version comment**:

```yaml
uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@4606d0547f41ea7edacfd40ff90c7b71d3449e3f  # v0.4.0
```

- The **SHA** is immutable — supply-chain safe, not movable by a re-tagged release.
- The **`# vX.Y.Z` comment** keeps the human-readable version local and visible
  (Locality of Behavior): the reader sees exactly which release is running without
  resolving the SHA.
- **The dependency updater maintains both** — Renovate
  (`helpers:pinGitHubActionDigests`) or Dependabot (`github-actions` ecosystem)
  bumps the SHA and keeps the trailing version comment current (see
  [Dependency updates](#dependency-updates-renovate-or-dependabot)).
- **No floating tags or branches** (`@v0`, `@main`) in app workflows or in this
  repo's examples.

### Release line & versioning (this repo)

`sharperflow-security-gates` auto-releases on every merge to `main` (Auto Release
workflow, conventional-commit driven): it computes the next semver, creates the
tag + GitHub Release, regenerates the CHANGELOG, and rolls the floating major tag
(`v0`).

- **Base-version selection is the highest-semver tag that is an ancestor of
  `main`** — not the nearest-ancestor tag. Nearest-ancestor selection once let the
  version *number* regress (the `v0.3.x` tags stranded on older commits while the
  maintained line kept shipping `v0.2.x`). Because Renovate orders by **semver**,
  it then chased the stranded — and broken — `v0.3.2`. Ancestor-restricted
  highest-semver selection keeps the maintained line monotonic and immune to
  stranded higher tags.
- **Version-line realignment (2026-06-16):** rather than delete the stranded
  releases, the maintained line was **jumped forward to `v0.4.0`** (cut from fixed
  `main`), so the highest semver again points at working code. The `v0.3.0`–`v0.3.2`
  releases are intentionally **left installable** but are no longer the highest
  semver, so the default Renovate path no longer proposes them.
- **Consumers** SHA-pin with a `# vX.Y.Z` comment and let Renovate retarget to the
  highest semver (now the `v0.4.x` line). Deleting/yanking a stranded tag is **not**
  required — SHA pins resolve regardless of tag refs.

---

## Dependency updates (Renovate — or Dependabot)

Sharper Flow uses **one automated dependency updater per ecosystem per repo**. Both
**Renovate** and **GitHub Dependabot** are supported, equal paths. A repo MAY use
either; the per-repo choice is made on its own merits (see
[Choosing the updater](#choosing-the-updater)).

> **Supersession (2026-06-08).** This replaces the earlier `adoptRenovateOrgWide`
> rule of "**Renovate only, not Dependabot**". That rule was reversed by explicit
> decision: Dependabot is now a first-class equal path, and a future per-repo
> re-assessment will pick the updater for each repo once the merge pathway is
> settled. The original concerns (below) still inform that choice — they are
> design inputs, not a ban.

### The one hard rule: one updater per ecosystem per repo

Do **not** run Renovate and Dependabot on the **same ecosystem** in the **same
repo**. Both write the same manifests/lockfiles → duplicate PRs + competing
lockfile rewrites. Coexistence is only safe when strictly partitioned (different
repos, or non-overlapping ecosystems in one repo). When migrating between updaters,
remove the old one's config for that ecosystem first.

### Merge behavior (both updaters)

Both gate auto-merge on the required check and **only merge green** — the
`Sharperflow CI Gate` functional suite *is* the review. A breaking update fails the
suite, the PR stays open red, and never merges. With strict-off + squash-only (see
[Merge serialization](#merge-serialization-strict-off-squash-only-auto-merge)),
bot PRs use **`gh pr merge --squash --auto`** and merge serially on green, no
rebase churn.

- Repos with **no functional gate** do not auto-merge (e.g. advance has no
  `Sharperflow CI Gate` yet → `automerge: false` + repo "Allow auto-merge" off,
  double-guarded).
- Enable **"Allow auto-merge"** in repo settings for either updater's auto-merge to
  take effect.

### Renovate path

- **Shared preset.** All Renovate repos extend one org preset:
  ```json
  { "extends": ["github>Sharper-Flow/sharperflow-security-gates"] }
  ```
  The preset lives at `default.json` in this repo. Repo-specific tweaks go in each
  repo's `renovate.json`.
- **Cooldown (supply-chain).** `minimumReleaseAge: "7 days"` — newly-published
  versions wait 7 days before install (most malicious releases are pulled within an
  hour). **Security fixes are exempt.**
- **Automerge.** `platformAutomerge` + top-level `automerge: true` → native
  auto-merge on green required check, all update types (majors gated behind
  Dependency Dashboard approval to avoid endless rebase/CI churn).
- **Install.** Renovate is the Mend GitHub App (org-admin install); one onboarding
  PR per repo.

#### Renovate security remediation

Renovate security fixes are expected to move on the **next Renovate run**, not the
weekly normal-update schedule. The shared preset keeps the stable GitHub alert
path enabled:

```json
"vulnerabilityAlerts": {
  "enabled": true,
  "labels": ["security"]
}
```

`minimumReleaseAge` is intentionally omitted from `vulnerabilityAlerts`: Renovate
security updates bypass release-age cooldowns, so a per-alert override is a no-op.

This path is active only when the caller repo has the required GitHub-side signal:

- Dependency graph enabled.
- Dependabot alerts enabled.
- Renovate GitHub App permission to read Dependabot alerts.
- This repo's shared Renovate preset extended from `renovate.json`.

If any prerequisite is missing, do **not** wait for weekly Renovate. Enable the
missing repository setting or use the OSV reproduction command below to prepare a
manual parent/resolver bump. Security remediation PRs should carry the `security`
label; normal dependency PRs carry `dependencies`.

The experimental Renovate `osvVulnerabilityAlerts` option is intentionally **not**
enabled by the shared preset. It was evaluated and deferred because Renovate marks
it experimental, documents it as direct-dependency scoped, and has open churn risk
around indirect-dependency PR creation. Repos that explicitly want OSV-native
direct-dependency alerts may opt in locally after weighing that blast radius.

### OSV dependency-gate remediation

The reusable Python and JavaScript security gates run OSV Scanner against the
caller lockfile when `lockfile-path` exists. Missing lockfiles remain a warning and
skip the OSV dependency scan; lockfiles with known high/critical vulnerabilities
remain blocking unless the finding is fixed or intentionally ignored by caller
policy.

On failure, use the `OSV Scanner` step log for the advisory ID/URL, package,
installed version, and fixed version when available. Local reproduction commands:

```bash
# Python / uv callers, e.g. PokeEdge
osv-scanner --lockfile=uv.lock --format=table

# JavaScript / Bun callers, e.g. PokeEdge-Web
osv-scanner --lockfile=bun.lock --format=table
```

Direct dependencies with fixed versions should get a Renovate security path when
the GitHub alert prerequisites are met. Transitive lockfile-only vulnerabilities
may require updating a parent dependency, relaxing a resolver constraint, or adding
a temporary direct constraint; do not assume Renovate can always raise a safe PR for
the vulnerable transitive package itself.

Current rapid-development consumers:

| Repo | Lockfile / gate | Renovate signal | Auto-merge path | Follow-up if OSV blocks a PR |
|---|---|---|---|---|
| `Sharper-Flow/PokeEdge` | Python 3.13 + `uv.lock`; `python-security-gate.yml` (SHA-pinned) | Vulnerability alerts enabled (`204 No Content` from `/vulnerability-alerts`) | Renovate native auto-merge after `Sharperflow CI Gate` is green | Expect Renovate security PRs for supported direct dependencies; transitive failures may need parent/resolver action. Renovate retargets the gate pin to the `v0.4.x` line. |
| `Sharper-Flow/PokeEdge-Web` | Bun + Node 24 + `bun.lock`; `javascript-security-gate.yml` (SHA-pinned) | Vulnerability alerts enabled (`204 No Content` from `/vulnerability-alerts`) | Renovate native auto-merge after `Sharperflow CI Gate` is green | Enable Dependabot alerts/Dependency graph (done 2026-06-16), then expect Renovate security PRs for supported direct dependencies. Renovate retargets the gate pin to the `v0.4.x` line (the earlier `v0.3.2` bump PR was closed as a stranded/broken release). Respect local caps such as `undici <8`. |

### Dependabot path

- **Config.** `.github/dependabot.yml` with one `package-ecosystem` entry per
  ecosystem the repo uses (`uv`, `bun`, `npm` for pnpm, `github-actions`,
  `docker`).
- **Cooldown (supply-chain).** Dependabot's GA `cooldown` is the analogue of
  Renovate's `minimumReleaseAge`, with finer semver granularity:
  ```yaml
  # .github/dependabot.yml (per ecosystem)
  updates:
    - package-ecosystem: "uv"
      directory: "/"
      schedule: { interval: "daily" }
      cooldown:
        default-days: 7        # ≈ Renovate minimumReleaseAge 7d
        semver-major-days: 30
        semver-minor-days: 7
        semver-patch-days: 3
  ```
  **Cooldown applies to version updates only — NOT security updates** (security
  fixes are never delayed; same as Renovate). Note: cooldown semver tiers work for
  `uv`/`bun`/`npm` but **`docker` and `github-actions` get `default-days` only**.
- **Auto-merge** is a GitHub Actions workflow (Dependabot itself cannot enable
  auto-merge):
  ```yaml
  # .github/workflows/dependabot-auto-merge.yml
  name: Dependabot auto-merge
  on: pull_request
  permissions:
    contents: write
    pull-requests: write
  jobs:
    auto-merge:
      runs-on: ubuntu-latest
      if: github.event.pull_request.user.login == 'dependabot[bot]'
      steps:
        - id: meta
          uses: dependabot/fetch-metadata@<sha>  # pin + Renovate/Dependabot-bump
          with:
            github-token: ${{ secrets.GITHUB_TOKEN }}
        # widen/narrow which update tiers auto-merge via the if: below
        - if: ${{ steps.meta.outputs.update-type != 'version-update:semver-major' }}
          run: gh pr merge --auto --squash "$PR_URL"
          env:
            PR_URL: ${{ github.event.pull_request.html_url }}
            GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  ```
  Use `--squash` (matches the squash-only ruleset). Secrets Dependabot needs are
  **Dependabot secrets**, not Actions secrets. Keep `Sharperflow CI Gate` required
  — it is the only-merge-green guard.

### Choosing the updater

The per-repo choice is deferred to a future re-assessment. Inputs that decide it:

| Input | Renovate | Dependabot |
|---|---|---|
| Bun support maturity | strong | supported, min Bun version-gated (verify live) |
| `github-actions` SHA-pin + version-comment | `helpers:pinGitHubActionDigests`, battle-tested | pins SHA + updates comment, but has stale-comment edge cases on release-branch actions |
| Cooldown | uniform `minimumReleaseAge` | GA `cooldown` with semver tiers; **no cooldown for docker** |
| pnpm security updates | full | limited (npm v7/v8) |
| Grouping / config ergonomics | rich (shared preset, grouping rules) | `groups` + `dependabot.yml` |
| Multi-machine future | server-side (neutral) | server-side (neutral) |

Both are fully compatible with the strict-off + squash + auto-merge merge strategy;
neither has a single-machine dependency.

---

## 6. Branch protection: org Rulesets

Protection is defined **once** as an organization-level Ruleset, not configured
per-repo by hand. The canonical policy lives at
[`rulesets/sharperflow-app-protection.json`](../rulesets/sharperflow-app-protection.json)
and is applied via [`scripts/apply-ruleset.sh`](../scripts/apply-ruleset.sh).

Policy:

- **Required status checks**: `Sharperflow CI Gate` only, **non-strict**
  (`strict_required_status_checks_policy: false`). The branch does **not** have to
  be up to date before merging — see [Merge serialization](#merge-serialization-strict-off-squash-only-auto-merge) for why.
- **Squash-only merges**: the `pull_request` rule sets
  `allowed_merge_methods: ["squash"]`. This is the **sole** squash-only enforcer:
  it excludes merge-commit **and** rebase, giving a linear squash history. (The
  `non_fast_forward` rule only blocks force-pushes — it does **not** forbid merge
  commits; that would be `required_linear_history`, which this ruleset does not
  use.)
- **Force-push guard**: `non_fast_forward` prevents force-pushing the default
  branch.
- **Enforced for admins**: `enforcement: active` and `bypass_actors: []` — no one
  bypasses, including org owners and repo admins. Releases adhere to the ruleset
  via [tag-only release](#release-automation) (the default); a bypass actor is an
  escape hatch only for repos that must push release commits to `main`. **No tool
  (merge bot, queue, etc.) is ever added as a bypass actor** — protection-as-code
  on a security-gates org must not be weakened to accommodate tooling.
- **No required human review**: `required_approving_review_count: 0`. Automated
  gates are the merge authority; this keeps bot auto-merge clean. PRs are
  still required (no direct pushes to the default branch).
- **Targeting**: by `repository_name.include` with `protected: true` (resists
  rename-evasion). Switch to a `repository_property` custom property as the app set
  grows.
- **Optional hardening**: add `integration_id` to the required status check to bind
  it to the GitHub Actions app and prevent a write-capable actor from spoofing the
  context.

### Merge serialization (strict-off + squash-only + auto-merge)

The protection model is tuned for **many concurrent PRs from AI agents and bots**
(single machine today, multiple machines and Renovate/Dependabot in future) on a
small-seat org. GitHub's native merge queue is **not available** here (it requires
GitHub Enterprise Cloud for private repos; this org is on the Team plan), so the
serialization strategy is built from GitHub primitives that work on any plan and
are server-side (machine-count-independent):

- **`strict` is OFF.** Strict ("require branches to be up to date before merging")
  is what caused the collision loop: PR A merges → PR B is suddenly "not up to
  date" → B rebases + reruns CI → meanwhile C merges → B is stale again. Disabling
  strict removes that churn. PRs merge serially as their required check goes green,
  ordered by GitHub server-side.
- **Native auto-merge does the serialization.** Use
  `gh pr merge --squash --auto`. GitHub merges each PR only after
  `Sharperflow CI Gate` passes — never on red — and arbitrates ordering itself. No
  manual "update branch", no local compute, identical behavior across machines.
- **Squash-only** keeps `main` linear and each PR a single commit.
- **Residual risk (accepted):** loose checks are **not** re-evaluated against the
  new base after another PR merges, so a green-but-logically-incompatible pair can
  land and break `main`. This is caught by **the next PR's CI** (and, for the
  backend↔frontend API surface specifically, by the
  [cross-repo contract gate](#cross-repo-api-contract-gate-openapi-breaking-changes)).
  At small-team PR volume this is an acceptable trade vs the constant rebase churn
  of strict mode. If main-breaking pairs become frequent, escalate
  ([If collisions persist](#if-collisions-persist-after-strict-off)).
- **Hard precondition before applying squash-only:** every targeted repo MUST have
  **`allow_squash_merge: true`**. A squash-only ruleset against a repo whose squash
  button is disabled produces an *empty* allowed-method intersection and **blocks
  all merges**. The apply runbook verifies this first (see
  [`apply-ruleset.sh`](#release-automation) and the conformance checklist).
  Normalizing `allow_merge_commit`/`allow_rebase_merge` to `false` is recommended
  hygiene (removes dead buttons) but is not load-bearing; `allow_squash_merge:
  true` is.

### If collisions persist after strict-off

Strict-off + auto-merge + squash dissolves the rebase-churn loop without serialized
pre-merge re-testing. If, after this is in place, you still observe
**green-but-incompatible PR pairs breaking `main` often enough to hurt**, escalate
to a real serializing merge queue. Native GitHub merge queue stays unavailable on
the Team plan for private repos, so the candidates are:

- **Mergify** (free tier ≤5 active users on private repos) — speculative/batched
  queue; reads and respects existing rulesets/required checks.
- **Another AI-enabled PR-merge bot** — survey current options at adoption time
  (Trunk, Aviator, etc.).

Before adopting any of them, **verified caveats** (do not skip):

- **Confirm bot-author billing.** Free tiers count "active users"; many bot/agent
  PR authors can silently consume the free seat limit. Verify before relying.
- **Bot-PR queueing needs explicit config** (e.g. a `bot_account`) and has a
  documented regression history — test a Renovate/Dependabot PR end-to-end first.
- **Keep the tool WITHIN the ruleset — never as a bypass actor.** A security-gates
  org must not hand merge authority that skips its own gates.

This is a documented escalation path only; **no third-party queue is adopted by
this standard.** Agent-side merge serialization (e.g. a Temporal mutex) is
explicitly **not** used: it taxes local hardware and cannot govern bot PRs that
never pass through the orchestrator.

### Local branch hygiene (worktree-first PRs)

The server-side serialization above governs how PRs *merge*. This section governs
how PRs are *created locally* when many AI agents and sessions share one checkout
of a repo. It is a hard rule, not a preference.

**The trunk/main checkout of a repo MUST stay on its default branch.** Every branch
that becomes a PR — feature fix, bot-style change, or orchestrated change — is
created and pushed from a **git worktree**, never by switching the shared trunk
checkout to a feature branch.

Why: multiple agents/sessions operate against the same working directory
concurrently. A feature branch checked out in the shared trunk directory is
inherited by every other session pointed at it, causing cross-agent collisions,
stale-branch confusion, and lost work. GitHub CI does not know or care where a
branch was checked out locally — it triggers on the pushed ref + PR event — so
pushing from a worktree produces an **identical** `Sharperflow CI Gate` run to
pushing from trunk. Worktrees change only the local checkout location, removing the
contention.

```bash
# ❌ WRONG — parks the shared trunk checkout on a feature branch
git checkout -b fix/thing            # in /path/to/repo (trunk)
git push -u origin fix/thing && gh pr create

# ✅ CORRECT — trunk stays on the default branch
git worktree add ../<repo>-wt/fix-thing -b fix/thing
cd ../<repo>-wt/fix-thing
git push -u origin fix/thing && gh pr create
# after merge:
git worktree remove ../<repo>-wt/fix-thing && git branch -d fix/thing
```

Rules:

- **Trunk stays on default.** Never `git checkout -b` / `git switch -c` a feature
  branch in the main/trunk checkout.
- **Every PR comes from a worktree.** Orchestrated changes (e.g. ADV) already do
  this automatically — push + open the PR from the change worktree, not trunk.
- **Merge before worktree delete.** Never remove a worktree until its branch is
  merged to the default branch.
- **If trunk drifted onto a feature branch,** surface it; restore to default only
  after confirming the feature branch is pushed (so no work is lost), then relocate
  the work into a worktree.

Enforcement is currently **trusted-prose** (this standard + an always-on agent
instruction). A structural guard (post-checkout hook / git wrapper) was considered
and deferred to avoid intercepting all git calls and colliding with the
`pre-commit` framework that owns per-repo `.git/hooks`. Revisit a structural guard
only if drift recurs.

### Concurrent migration-version collisions

A direct consequence of strict-off + many concurrent worktree PRs: two branches that
both forked before the other merged can each claim the **same next migration
version number**. Neither branch is wrong in isolation; the collision only
materializes when the second PR merges into a `main` that already contains the
first.

This is detected, not silently merged — a migration-identity guard (e.g.
`test_migration_identity` in the consuming app) fails the PR with a
`CollisionViolation(version=..., filenames=(...))`. **Fix forward by renumbering the
later branch's migration to the next free slot** (verify the slot is free against
`origin/main`, not just locally), updating any paired test/path references, then
re-push. Do **not** force the duplicate number through.

Example (PokeEdge #349): branch added `192_add_card_var_serving.sql`; PR #344
merged `192_extend_work_items_cn_budget_classes.sql` to `main` after the branch
forked. Resolution: renumber `192 → 193` (next free slot, confirmed against
`origin/main`) + update the paired arch-test path. This is the migration-domain
instance of the accepted "loose checks not re-evaluated against new base" residual
risk above — caught by the guard, fixed forward.

### Ruleset ↔ classic protection coexistence

GitHub evaluates classic branch protection **and** rulesets together, and the
**most restrictive** version of each rule wins. A stale classic required-check
context (e.g. a renamed/ghost job) survives this aggregation and will wedge merges.

**When a repo adopts the ruleset, it MUST remove its classic required-status-check
entries** so the ruleset's `Sharperflow CI Gate` is the single source.

### Auth

Org-ruleset writes require **`admin:org`** (org-admin classic PAT) or a **GitHub
App with `Administration: write`** at org scope. `GITHUB_TOKEN` does NOT suffice.
Applying the ruleset is an explicit privileged operation (a runbook step), not an
automated CI mutation.

### Release automation

semantic-release bumps the version on a merge to the default branch. But the
default branch is protected by the ruleset (require-PR + required
`Sharperflow CI Gate`, `bypass_actors: []`), so a release **must not** push a
version-bump commit to it. The Sharperflow default **adheres to the ruleset
rather than weakening it**:

#### Default (required): tag-only release

semantic-release creates and pushes the **version tag** — tags are NOT governed
by the branch ruleset — but pushes **no commit** to the default branch:

- **JS/TS:** omit `@semantic-release/git` from `.releaserc`. The core still tags;
  `package.json`/`CHANGELOG` are simply not committed to `main` (this is the
  semantic-release maintainers' recommended setup for protected branches).
- **Python:** run `python-semantic-release` in tag-only mode (no version commit /
  no `--vcs-release`).
- The version bump is carried into the `staging` branch by the promote step
  (stamp `package.json` / `pyproject.toml` from the latest tag), so deploy
  pipelines read the correct version.

The ruleset stays strict (`bypass_actors: []`) and the org never grants a
release-bot push exception. Apply protection with:

```bash
scripts/apply-ruleset.sh --no-release-bypass
```

`--no-release-bypass` is the **normal** path for a tag-only repo — it is not a
weakening override.

#### Escape hatch (only if a release MUST push commits to main)

If a repo genuinely cannot go tag-only and must push release assets to the
default branch, grant **one** release identity a ruleset bypass — prefer a
dedicated GitHub App, never a human or org-admin:

```yaml
# release.yml — mint a short-lived App token
- uses: actions/create-github-app-token@<sha>  # vN
  id: app-token
  with:
    app-id: ${{ secrets.RELEASE_APP_ID }}
    private-key: ${{ secrets.RELEASE_APP_PRIVATE_KEY }}
# run semantic-release with GITHUB_TOKEN: ${{ steps.app-token.outputs.token }}
```

```bash
scripts/apply-ruleset.sh --bypass-app-id <App ID>   # escape hatch — prefer tag-only
```

Bypass entry (composed at apply time, not committed —
`{ "actor_id": <App ID>, "actor_type": "Integration", "bypass_mode": "always" }`).
Use the **App ID** (`gh api /app`), not the installation/client id; the App needs
`contents: write`. `Team`/`User` actors (`--bypass-team-id` / `--bypass-user-id`)
are a cloud-only, non-portable fallback. A bypass actor skips the **entire**
ruleset for that identity — which is exactly why tag-only is preferred.

The committed `rulesets/sharperflow-app-protection.json` always keeps
`bypass_actors: []`; any bypass is injected only at apply time via the escape-hatch
flags above.

---

## 7. Optional conventions

These are recommended but MUST NOT require per-app secrets to pass CI:

- **Conventional Commits** gate on PRs (enables semantic-release version bumps).
- **Heartbeat / failure notification** (Uptime Kuma, Discord, etc.) — best-effort,
  non-blocking, skipped when its secret/var is absent.

---

## Code quality beyond the security gate

**GitHub CodeQL is retired — in both of its forms.** GitHub ships CodeQL through
two *separate* features; Sharper Flow uses neither. Don't conflate them.

**1. GitHub Code Quality** (`Settings → Code quality`) — the one that actually
runs. A **public-preview** feature that runs CodeQL *quality* (maintainability)
analysis on every push/PR via the GitHub-managed `dynamic/github-code-scanning/codeql`
workflow. Findings surface on the hosted **Security and quality → Code quality**
pages. Sharper Flow does **not** use it, for three posture reasons:

- It reports through a **hosted GitHub dashboard** — the standard prefers
  repo-owned config and takes no hosted-dashboard dependency.
- It is **public preview and not billed *yet***, but **bills at GA** (premium
  requests + Actions minutes) — and it **burns Actions minutes today**.
- It is **not** part of the `Sharperflow CI Gate` contract: non-blocking,
  unwatched, and its `dynamic/github-code-scanning/codeql` context MUST never
  enter branch-protection required checks (§2).

Disable it per repo with its **dedicated API** (separate from the GHAS-gated
`code-scanning` API — this one is *not* paywalled):

```bash
gh api -X PATCH repos/<org>/<repo>/code-quality/setup -f state=not-configured
gh api repos/<org>/<repo>/code-quality/setup   # verify → state: not-configured
```

(Equivalent UI: `Settings → Code quality → Disable`.) Reversible via
`state=configured`.

**2. Security CodeQL / code scanning** (`Settings → Advanced Security → Code
Security`) — the SAST product. On a **private, Team-plan repo without GitHub
Advanced Security**, enabling it is impossible: the `code-scanning` REST API
returns `403 Code Security must be enabled`, and alerts never surface without the
paid add-on. Sharper Flow does not buy GHAS and does **not** use it. No SARIF
upload, no Code Scanning alerts surface.

Both are **isolated** from secret scanning, the dependency graph, and Dependabot
(separate features). Any committed `.github/codeql/codeql-config.yml` is an inert
orphan once Code Quality is off — delete it.

CodeQL's genuine value was **interprocedural dataflow/taint** SAST, which the OSS
gate does not replace (Semgrep CE is intraprocedural — single-function /
single-file; cross-function taint is Pro-only). That gap is **consciously
deferred**, tracked as `deepenSastDataflow` in the followup table below — not
silently dropped, and explicitly **not** a reason to buy GHAS.

**SonarCloud is retired.** Sharper Flow no longer uses SonarCloud (no hosted
dashboard, no `sonar-project.properties`, no `SONAR_TOKEN`). The required path is
the OSS gates (Semgrep, Bandit, OSV, Gitleaks, Trivy) plus app-owned coverage and
complexity gates under `Sharperflow CI Gate`.

Retiring Sonar leaves four capabilities it used to provide. Each is tracked as a
deliberate research→decision followup rather than silently dropped:

| Capability | Followup change | Likely direction |
|---|---|---|
| Duplication detection | `addDuplicationDetection` | jscpd/CPD advisory, or accept-drop |
| Maintainability/reliability ratings + tech-debt | `addMaintainabilityMetrics` | bounded complexity gate, or rely on review |
| Coverage-on-new-code | `addDiffCoverageGate` | `diff-cover` on existing coverage artifacts |
| Deep dataflow/taint SAST | `deepenSastDataflow` | Semgrep taint-mode / Opengrep, or accept CE ceiling |

Coverage **trends**, the **dashboard**, and **PR decoration** are intentionally
out of scope (no-hosted-dashboard posture).

### Workflow hygiene

Keep `.github/workflows/` to workflows that actually run.

- **Don't leave disabled workflow files committed.** A `disabled_manually`
  workflow that nobody runs is clutter and drift risk — delete the file. Git
  history is the recovery path (`git revert`); capture the intent in the change
  record if the capability may return.
- **GitHub-managed scan features stay OFF unless explicitly adopted** under this
  standard — **Code Quality** (`code-quality/setup`), **security CodeQL/code
  scanning**, and the **Copilot coding agent** (`dynamic/copilot-swe-agent`). They
  burn Actions minutes and/or report to hosted dashboards outside the
  `Sharperflow CI Gate` contract.
- **Ghost workflow records** (file deleted from the default branch but the Actions
  registry still lists the workflow as `disabled_manually`) are harmless: no file,
  no runs, no cost. GitHub has no workflow-record delete API; they age out. No
  action required.

---

## Cross-repo API contract gate (OpenAPI breaking changes)

Where one repo produces an API another repo consumes (backend OpenAPI → frontend
client), a **breaking backend change can make a *green* frontend PR wrong** — a
class of drift that no merge serialization (queue, auto-merge, or otherwise) can
catch, because it spans two repos. The standard's answer is a **contract gate**
using **oasdiff** to detect breaking OpenAPI changes pre-merge.

This is **mandatory** for repos in a producer/consumer API pair (PokeEdge ↔
PokeEdge-Web); other repos may ignore it.

### Tool: oasdiff

[oasdiff](https://github.com/oasdiff/oasdiff) is the de-facto open-source OpenAPI
breaking-change detector (Apache-2.0, actively maintained, single Go binary). Gate
on **`oasdiff breaking BASE REVISION`** — exit code `1` = breaking change found →
fail the PR. High-signal first (this repo's posture): treat **ERR** (definite
breaks) as blocking; `WARN` is advisory.

- ✅ Use the **oasdiff CLI** (download the pinned release in CI) **or** the
  maintained **`oasdiff/oasdiff-action`**.
- ⛔ **NEVER use the deprecated `Tufin/oasdiff-action`** — it is archived.
- **Pin** the oasdiff version (release tag or action SHA) and let the dependency
  updater bump it, same as any other `uses:`.

### Baseline model

The **consumer's committed spec is the baseline** ("what the consumer was built
against"); the **producer's current spec is the revision**:

- Frontend commits a copy of the spec it generates its client from (e.g.
  `docs/openapi.json`).
- The backend's contract gate fetches that committed frontend spec as `BASE`, uses
  its own `openapi.json` as `REVISION`, and runs `oasdiff breaking BASE REVISION`.
- A breaking diff means the backend change would break the frontend that exists
  today → block until coordinated.

### Canonical job shape

The gate is a job under the repo's `Sharperflow CI Gate` summary, **path-filtered**
to spec changes (skip = success so non-spec PRs are unaffected):

```yaml
contract-gate:
  name: Contract Gate (spec compat)
  needs: changes                      # dorny/paths-filter detecting openapi.json
  if: ${{ needs.changes.outputs.openapi == 'true' }}
  runs-on: ubuntu-latest
  permissions: { contents: read, pull-requests: read }
  steps:
    - uses: actions/checkout@<sha>  # v6
    - name: Install oasdiff (pinned)
      run: |  # download a pinned oasdiff release tarball to /usr/local/bin
        ...
    - name: Fetch consumer's committed spec (baseline)
      run: gh api repos/<org>/<consumer>/contents/docs/openapi.json --jq .content | base64 -d > /tmp/base.json
    - name: Compare for breaking changes
      run: oasdiff breaking /tmp/base.json openapi.json --fail-on ERR
```

**Reference implementation:** `Sharper-Flow/PokeEdge` —
`.github/workflows/check-api-compat.yml` (reusable workflow: fetch frontend spec →
normalize for oasdiff 3.1 parser compatibility → `oasdiff breaking`) invoked from
the `contract-gate` job in `pr-gate.yml`, required via `Sharperflow CI Gate`. New
producer/consumer pairs should follow that pattern rather than re-deriving it.

**Two complementary halves of the contract:**

| Side | Repo | Check | Enforces |
|---|---|---|---|
| Producer (breaking-change) | backend (PokeEdge) | `oasdiff breaking` consumer-spec vs backend spec | backend change does not break the consumer the frontend was built against |
| Consumer (spec-sync) | frontend (PokeEdge-Web) | `Backend Contract Sync Check`: canonicalized equality of committed `docs/openapi.json` vs backend `main` | the consumer's committed baseline is not stale vs the producer |

Both are required (each under its repo's `Sharperflow CI Gate`); neither replaces
the other. The producer side proves *no breaking change*; the consumer side proves
*the baseline is current*.

> **Gotcha — specs over 1 MB.** GitHub's Contents API returns **empty content for
> files larger than 1 MB**. PokeEdge's `openapi.json` crossed that threshold on
> 2026-05-23. To fetch a large spec cross-repo, resolve its blob SHA then use the
> **Git Blobs API** (handles up to 100 MB):
> ```bash
> BLOB_SHA=$(gh api 'repos/<org>/<producer>/contents/openapi.json?ref=main' --jq .sha)
> gh api "repos/<org>/<producer>/git/blobs/${BLOB_SHA}" --jq .content | base64 -d > spec.json
> ```
> The simple `gh api .../contents/...` form in the canonical job shape above is fine
> only while the spec stays under 1 MB.

**Complements (not replacements):** [Spectral](https://github.com/stoplightio/spectral)
for API *design* linting; [Schemathesis](https://github.com/schemathesis/schemathesis)
for *runtime* contract/property testing. oasdiff is the static breaking-change
differ; the others cover different layers.

---

## App-owned gates

The standard does **not** standardize, and apps keep ownership of:

- Coverage thresholds and which suites are blocking.
- Migration-chain / schema-integrity validation.
- Complexity/size gates (Lizard, etc.).
- Deploy/release workflows.

(OpenAPI breaking-change / API-compatibility gating is **standardized** — see
[Cross-repo API contract gate](#cross-repo-api-contract-gate-openapi-breaking-changes)
— not app-owned, for producer/consumer API pairs.)

These run as ordinary jobs under the app's `Sharperflow CI Gate` summary.

---

## Conformance checklist (for an app repo)

- [ ] CI workflow emits a job named exactly `Sharperflow CI Gate`.
- [ ] Summary uses `if: ${{ !cancelled() }}`, leaf-only `needs`, fails on
      failure/cancelled.
- [ ] Summary workflow has no workflow-level `paths:` filter; path scoping is
      internal.
- [ ] Security gate folded in as a `security` job (reusable `workflow_call`),
      SHA-pinned with version comment; no standalone pilot, no inline duplicate
      scanners.
- [ ] Setup via the shared `setup-python-uv` / `setup-bun-node` composite.
- [ ] All org `uses:` SHA-pinned + version comment; one dependency updater
      enabled (`renovate.json` extends the org preset, **or** Dependabot —
      one updater per ecosystem per repo; see [Dependency updates](#dependency-updates-renovate-or-dependabot)).
- [ ] Repo merge buttons normalized: **`allow_squash_merge: true`** (load-bearing
      precondition for the squash-only ruleset — without it all merges block),
      `allow_merge_commit: false`, `allow_rebase_merge: false`, `allow_auto_merge:
      true`.
- [ ] Org ruleset applied (`apply-ruleset.sh --no-release-bypass` for the default
      tag-only release; `--bypass-app-id <App ID>` only if the repo must push
      release commits to `main`); classic required-check contexts removed.
      Ruleset is non-strict + squash-only (see [Merge serialization](#merge-serialization-strict-off-squash-only-auto-merge)).
- [ ] Auto-merge standardized: PRs merged via `gh pr merge --squash --auto`; bot
      PRs (Renovate/Dependabot) auto-merge on green `Sharperflow CI Gate`.
- [ ] Local branch hygiene: trunk/main checkout stays on the default branch; every
      PR is created and pushed from a git worktree, never by switching the shared
      trunk checkout (see [Local branch hygiene](#local-branch-hygiene-worktree-first-prs)).
- [ ] Local fast-guard parity: repo provides a single discoverable local
      command (e.g. `bin/oc-fast-check`) that mirrors CI fast-checks (format,
      lint, types, drift) and is wired as a pre-push hook. Pre-push MUST be
      fast-only — no unit tests, E2E, or coverage (CI's job). See
      [Local fast-guard parity](#local-fast-guard-parity).
- [ ] Release is tag-only (semantic-release tags but pushes no commit to `main`)
      — verify a release lands the tag and the staging promote stamps the version.

---

## Local fast-guard parity

Every CI fast-check (format, lint, types, drift) MUST have a local equivalent
that runs before `git push`. This catches the most common PR failures
(formatting, lint violations, type errors, API drift) in seconds locally
instead of after a CI round-trip.

### Contract

The conformance item specifies **what**, not **how**:

- **Single discoverable command** — `bin/oc-fast-check` or equivalent. MUST be
  documented in `AGENTS.md` or `CONTRIBUTING.md`.
- **Pre-push wiring** — the command MUST be wired as a git pre-push hook
  (pre-commit framework, Husky, lefthook, or plain `.git/hooks/pre-push`).
- **Fast-only scope** — format, lint, types, drift. No unit tests, E2E, or
  coverage. Those serialize multi-agent sessions behind `oc-test-gate` and
  belong to CI.
- **Under 60 seconds** on a warm cache for incremental changes.

### Two-tier pattern

The recommended pattern splits checks across two git hook stages:

| Stage | What runs | Typical speed |
|-------|-----------|---------------|
| `pre-commit` | Format, lint (staged files only) | < 2s |
| `pre-push` | Types, import architecture, API drift, complexity | 5–30s |

This prevents taxing every commit with whole-tree scans while still catching
failures before push.repos that already have a working pre-push setup (e.g.
PokeEdge Web's Husky `fast` guard) satisfy this item by audit, not by
re-implementation.

### Tool choice is app-owned

The standard does not mandate a specific hook framework:

- **Python repos**: [pre-commit](https://pre-commit.com) framework is the
  ecosystem standard with environment isolation and reusable hook definitions.
- **JS/TS repos**: [Husky](https://typicode.github.io/husky/) + lint-staged is
  the ecosystem standard with transparent shell hooks.
- **Polyglot repos**: [lefthook](https://github.com/evilmartians/lefthook) or
  pre-commit (cross-language) are both valid.

Choose the tool that matches the repo's package manager and existing ecosystem.
The standard requires the contract (fast-check parity + pre-push wiring), not
the mechanism.

### Hard requirement

This is a hard conformance item:

- **New repos** MUST comply before their first PR.
- **Existing repos** get a tracked follow-up to adopt.
