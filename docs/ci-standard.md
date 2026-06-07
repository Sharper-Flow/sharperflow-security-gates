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

---

## 3. Security gate: permanent and required

The reusable Sharperflow security gate is **permanent and required** — not a
pilot. The "measure before making it required" phase is over.

- Apps invoke the gate as a **job** inside their CI workflow, named `security`,
  listed in the summary `needs`:

  ```yaml
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@<sha>  # v0.3.1
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

---

## 4. Shared building blocks

Setup is defined once in this repo and consumed cross-repo, never copy-pasted.

| Composite | Path | Inputs |
|---|---|---|
| Python + uv | `.github/actions/setup-python-uv` | `python-version` (def `3.13`), `sync-args` (def `--all-groups`), `cache-key-suffix` |
| Bun + Node | `.github/actions/setup-bun-node` | `node-version` (def `24`), `bun-version`, `install-mode` (`ci`\|`install`) |

Consumed from an app workflow:

```yaml
- uses: Sharper-Flow/sharperflow-security-gates/.github/actions/setup-python-uv@<sha>  # v0.3.1
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
uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@e21e07a7faa2396662875fac9679f08b6b4efc9d  # v0.3.1
```

- The **SHA** is immutable — supply-chain safe, not movable by a re-tagged release.
- The **`# vX.Y.Z` comment** keeps the human-readable version local and visible
  (Locality of Behavior): the reader sees exactly which release is running without
  resolving the SHA.
- **Renovate maintains both** — `helpers:pinGitHubActionDigests` bumps the SHA and
  keeps the trailing version comment current (see
  [Dependency updates](#dependency-updates-renovate)).
- **No floating tags or branches** (`@v0`, `@main`) in app workflows or in this
  repo's examples.

---

## Dependency updates (Renovate)

Sharper Flow uses **Renovate** (one updater, org-wide) — **not Dependabot** — for
automated dependency updates across all ecosystems (uv via `pep621`, bun, pnpm,
`github-actions`, docker). One tool covers them all, with the best bun support and
a built-in supply-chain cooldown.

- **Shared preset.** All repos extend one org preset:
  ```json
  { "extends": ["github>Sharper-Flow/sharperflow-security-gates"] }
  ```
  The preset lives at `default.json` in this repo. Repo-specific tweaks go in each
  repo's `renovate.json`.
- **Cooldown (supply-chain).** `minimumReleaseAge: "7 days"` — newly-published
  versions wait 7 days before Renovate installs them (most malicious releases are
  pulled within an hour). **Security fixes are exempt** (they skip the line).
- **Automerge is gated on the required check, and only merges green.** Renovate
  uses GitHub native auto-merge (`platformAutomerge` + top-level `automerge: true`),
  so a PR merges **only after** the repo's required check passes — never on red.
  Where the required check is a real functional test suite (`Sharperflow CI Gate`
  on pokeedge/web rolls up unit + integration + e2e + contract; `self-test`
  actionlint here), **all update types automerge on green — including majors and
  production dependencies**. The test suite *is* the review: a breaking update
   fails the suite, the PR stays open red, and Renovate never merges it. Combined
   with the 7-day cooldown, every auto-merged release already survived a week in
   the wild.
- **Major updates require Dependency Dashboard approval.** Breaking majors (e.g.
   `python 3.x`, framework majors) never go green on their own and would otherwise
   re-run the full CI suite on every rebase forever. The preset gates `major`
   updates behind an explicit human opt-in in the dashboard (`dependencyDashboardApproval`),
   so they create **no PR/CI churn** until someone commits to the migration.
   Minor/patch/digest updates still flow hands-off.
- **Repos without a functional gate do not automerge.** advance has no
  `Sharperflow CI Gate` yet (deferred until `conformAdvanceCi` lands one), so its
  `renovate.json` sets `automerge: false` — Renovate opens PRs but never merges
  them unreviewed.
- **One updater per repo.** Do not run Dependabot alongside Renovate (duplicate
  PRs + lockfile conflicts). Renovate ignores Dependabot PRs; remove
  `.github/dependabot.yml` after Renovate onboarding.
- **Install.** Renovate is the Mend GitHub App (org-admin install); each repo gets
  a one-time onboarding PR. Enable "Allow auto-merge" in repo settings for the
  automerge policy to take effect.

---

## 6. Branch protection: org Rulesets

Protection is defined **once** as an organization-level Ruleset, not configured
per-repo by hand. The canonical policy lives at
[`rulesets/sharperflow-app-protection.json`](../rulesets/sharperflow-app-protection.json)
and is applied via [`scripts/apply-ruleset.sh`](../scripts/apply-ruleset.sh).

Policy:

- **Required status checks**: `Sharperflow CI Gate` only, `strict` (branch must be
  up to date before merging).
- **Enforced for admins**: `enforcement: active` and `bypass_actors: []` — no one
  bypasses, including org owners and repo admins. Releases adhere to the ruleset
  via [tag-only release](#release-automation) (the default); a bypass actor is an
  escape hatch only for repos that must push release commits to `main`.
- **No required human review**: `required_approving_review_count: 0`. Automated
  gates are the merge authority; this keeps Renovate auto-merge clean. PRs are
  still required (no direct pushes to the default branch).
- **Targeting**: by `repository_name.include` with `protected: true` (resists
  rename-evasion). Switch to a `repository_property` custom property as the app set
  grows.
- **Optional hardening**: add `integration_id` to the required status check to bind
  it to the GitHub Actions app and prevent a write-capable actor from spoofing the
  context.

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

---

## App-owned gates

The standard does **not** standardize, and apps keep ownership of:

- Coverage thresholds and which suites are blocking.
- Migration-chain / schema-integrity validation.
- Spec/contract gates (e.g. OpenAPI drift, API compatibility).
- Complexity/size gates (Lizard, etc.).
- Deploy/release workflows.

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
- [ ] All org `uses:` SHA-pinned + version comment; Renovate enabled
      (`renovate.json` extends the org preset).
- [ ] Org ruleset applied (`apply-ruleset.sh --no-release-bypass` for the default
      tag-only release; `--bypass-app-id <App ID>` only if the repo must push
      release commits to `main`); classic required-check contexts removed.
- [ ] Release is tag-only (semantic-release tags but pushes no commit to `main`)
      — verify a release lands the tag and the staging promote stamps the version.
