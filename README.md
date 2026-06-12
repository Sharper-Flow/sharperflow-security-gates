# Sharper Flow Security Gates

Reusable, low-cost CI security gates **and the org CI standard** for Sharper Flow
repositories.

The CI contract every Sharper Flow app conforms to is defined in
**[`docs/ci-standard.md`](docs/ci-standard.md)**. This repo is the source of truth
for that standard: the reusable workflows, the shared setup composites, and the
org branch-protection ruleset all live here.

## Targets

- Python API repositories (PokeEdge backend).
- JavaScript/TypeScript web repositories (PokeEdge Web).

## Gates included

| Area | Tool | Purpose |
|---|---|---|
| SAST | Semgrep CE | Python/FastAPI (or JS/TS) security rules + repo custom rules |
| Python security lint | Bandit | High-severity/high-confidence Python AST checks |
| Dependencies | OSV Scanner | Known vulnerabilities from lockfiles |
| Secrets | Gitleaks CLI | Hardcoded secret detection without GitHub Secret Protection |
| Filesystem/container | Trivy | CVEs, IaC misconfig, secrets, image deploy gate |

The security gate is **permanent and required** under the standard — not a pilot.
Apps invoke it as a job inside their CI workflow and require only the single
`Sharperflow CI Gate` summary check (see the standard).

## Reusable workflows

Pin with a full commit SHA plus a `# vX.Y.Z` version comment (see
[Pin policy](docs/ci-standard.md#5-pin-policy-lbp-supply-chain)). The dependency
updater — Renovate or Dependabot, one per ecosystem per repo (see
[Dependency updates](docs/ci-standard.md#dependency-updates-renovate-or-dependabot))
— maintains both.

```yaml
jobs:
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@5afaf289aafeebc18466ca19621ad4d7e9289139  # v0.3.2
    permissions:
      contents: read
    with:
      python-version: "3.13"
      scan-paths: "api services clients models core common repositories integrations utils"
      lockfile-path: "uv.lock"
```

JavaScript/TypeScript:

```yaml
permissions: {}

jobs:
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/javascript-security-gate.yml@5afaf289aafeebc18466ca19621ad4d7e9289139  # v0.3.2
    permissions:
      contents: read
    with:
      scan-paths: "src scripts infra"
      lockfile-path: "bun.lock"
```

Container image gate (deploy-time):

```yaml
jobs:
  image-security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/container-security-gate.yml@5afaf289aafeebc18466ca19621ad4d7e9289139  # v0.3.2
    with:
      image-ref: "ghcr.io/OWNER/IMAGE:${{ github.sha }}"
```

## Shared setup composites

Setup is defined once and consumed cross-repo (never copy-pasted):

```yaml
- uses: Sharper-Flow/sharperflow-security-gates/.github/actions/setup-python-uv@5afaf289aafeebc18466ca19621ad4d7e9289139  # v0.3.2
  with:
    python-version: "3.13"
    sync-args: "--all-groups"
```

| Composite | Path |
|---|---|
| Python + uv | `.github/actions/setup-python-uv` |
| Bun + Node | `.github/actions/setup-bun-node` |

## Branch protection (org ruleset)

Protection is applied once as an org-level Ruleset, not per-repo by hand:
`rulesets/sharperflow-app-protection.json` + `scripts/apply-ruleset.sh`. Required
check = `Sharperflow CI Gate` only; **non-strict + squash-only** (PRs merge serially
via native auto-merge; no branch-up-to-date churn — see
[Merge serialization](docs/ci-standard.md#merge-serialization-strict-off-squash-only-auto-merge));
enforced for admins; no required human review. **Precondition:** every targeted repo
must have `allow_squash_merge: true` before applying, or all merges block. See the
[standard](docs/ci-standard.md#6-branch-protection-org-rulesets).

> **Release automation:** the default is **tag-only** — semantic-release pushes a
> tag, not a commit to the default branch, so the ruleset keeps `bypass_actors: []`
> (no bypass).
> Apply with `scripts/apply-ruleset.sh --no-release-bypass`. A ruleset bypass
> (`--bypass-app-id <App ID>`) is an **escape hatch** only for repos that must push
> release commits to `main`. See
> [Release automation](docs/ci-standard.md#release-automation).

## Design posture

- Fail only on high-signal issues by default.
- Prefer repo-owned config over hosted dashboards.
- No paid GitHub Advanced Security dependency. No SonarCloud LOC usage.
- Pin org `uses:` by SHA + version comment.

See **[`docs/ci-standard.md`](docs/ci-standard.md)** for the full contract and the
[conformance checklist](docs/ci-standard.md#conformance-checklist-for-an-app-repo).
