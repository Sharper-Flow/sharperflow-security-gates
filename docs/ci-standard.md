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
- **The dependency updater maintains both** — Renovate
  (`helpers:pinGitHubActionDigests`) or Dependabot (`github-actions` ecosystem)
  bumps the SHA and keeps the trailing version comment current (see
  [Dependency updates](#dependency-updates-renovate--or-dependabot)).
- **No floating tags or branches** (`@v0`, `@main`) in app workflows or in this
  repo's examples.

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
[Merge serialization](#merge-serialization-strict-off--squash-only--auto-merge)),
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
  be up to date before merging — see [Merge serialization](#merge-serialization-strict-off--squash-only--auto-merge) for why.
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
      one updater per ecosystem per repo; see [Dependency updates](#dependency-updates-renovate--or-dependabot)).
- [ ] Repo merge buttons normalized: **`allow_squash_merge: true`** (load-bearing
      precondition for the squash-only ruleset — without it all merges block),
      `allow_merge_commit: false`, `allow_rebase_merge: false`, `allow_auto_merge:
      true`.
- [ ] Org ruleset applied (`apply-ruleset.sh --no-release-bypass` for the default
      tag-only release; `--bypass-app-id <App ID>` only if the repo must push
      release commits to `main`); classic required-check contexts removed.
      Ruleset is non-strict + squash-only (see [Merge serialization](#merge-serialization-strict-off--squash-only--auto-merge)).
- [ ] Auto-merge standardized: PRs merged via `gh pr merge --squash --auto`; bot
      PRs (Renovate/Dependabot) auto-merge on green `Sharperflow CI Gate`.
- [ ] Release is tag-only (semantic-release tags but pushes no commit to `main`)
      — verify a release lands the tag and the staging promote stamps the version.
