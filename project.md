# sharperflow-security-gates

Reusable GitHub Actions security gate workflows for the Sharper-Flow org.

## What this repo is

- **Product**: 3 reusable `workflow_call` workflows + baseline configs/examples/docs.
- **Consumers**: `Sharper-Flow/Advance`, `Sharper-Flow/pokeedge`, `Sharper-Flow/pokeedge-web`, and any future Sharper-Flow repo.
- **Not in scope**: application source, package manifests, build/publish logic. The product is the YAML.

## Tech stack

- GitHub Actions (`workflow_call`) — primary surface
- Pinned third-party scanners: Semgrep, Bandit (Python), OSV-Scanner, Gitleaks, Trivy
- `actionlint:1.7.7` (containerized) for local + CI workflow validation
- No language runtime — no Python/Node/Go code lives here

## Repo conventions

| Convention | Details |
|---|---|
| Default branch | `main` |
| Release model | Conventional commits → auto-release (`feat:` minor, `fix:` patch, `feat(scope)!:` major) |
| Tag scheme | `vX.Y.Z` immutable + `vX` floating major tag (auto-rolled) |
| Caller pinning | Recommend `@v0` (floating major); allow `@v0.Y.Z` (immutable) or `@<sha>` |
| Branch protection | `main` requires Self Test (actionlint + docs/config checks) |
| Workflow validation | actionlint must pass; reusable-workflow callers may NOT add `continue-on-error: true` (invalid syntax, silently breaks pilots) |
| Non-blocking pilot semantics | Driven by NOT being in branch protection's required checks, never by a YAML flag |

## Active gates

| Gate | File | Purpose |
|---|---|---|
| `python-security-gate.yml` | Python repos | Semgrep + Bandit, OSV lockfile, Gitleaks, Trivy fs (vuln/secret/misconfig) |
| `javascript-security-gate.yml` | JS/TS repos | Semgrep, OSV lockfile, Gitleaks, Trivy fs |
| `container-security-gate.yml` | Any repo with a built image | Trivy image scan (vuln/secret) |

All three accept a `trivy-ignorefile` input (added in `v0.2.0`) for `.trivyignore.yaml`-based FP suppression.

Python and JavaScript gates additionally accept (added in `v0.3.0`):
- `gitleaks-config` — caller's `.gitleaks.toml` is mounted and passed via `--config`, honoring `[allowlist]` rules.
- `sbom-format` — when set to `cyclonedx` or `spdx`, Trivy emits an SBOM uploaded as a workflow artifact (`sbom-<format>`).

Container gate accepts `sbom-format` for image SBOMs.

## Domain knowledge

- **Trivy and ARM templates**: Trivy cannot statically evaluate ARM `format()` functions. Misconfigs derived from `format()` parameters (e.g. AZU-0013 on Azure Key Vault networkAcls) report as FPs. Suppress via caller's `.trivyignore.yaml` + the `trivy-ignorefile` input.
- **Private repo callers and `GITHUB_TOKEN` scope**: GitHub's default `GITHUB_TOKEN` cannot resolve a reusable workflow from a private repo unless the org has Enterprise (Internal visibility) or the consumer adds a PAT secret. This repo is **public** to avoid that friction.
- **pokeedge-web action-reference-policy test**: that repo's `tests/workflows/action-reference-policy.test.ts` blocks `@main`, `@master`, `@latest` refs across all workflows. Always pin to `@v0` or newer in examples and PR templates.

## Design posture to preserve

- **High signal**: gates fail only on `HIGH,CRITICAL` severity, `ignore-unfixed: true` by default. Resist adding noisy required gates until FP rate, runtime, and failure modes are understood per consumer.
- **No external dashboards**: do not introduce assumptions that require GitHub Advanced Security, CodeQL/SARIF upload, SonarCloud, or any hosted dashboard.
- **Locality over reuse**: PokeEdge-specific scan paths live in `examples/pokeedge-python/` and the consumer repo, not in the reusable workflow defaults. Promote to reusable defaults only after a 2nd consumer adopts the same pattern.
- **Caller controls suppressions**: scanner ignore files live in the consumer repo (e.g. `.trivyignore.yaml`, `.gitleaks.toml`). The reusable workflow exposes inputs to forward them but never embeds suppressions.

## ADV usage

ADV is initialized lightly. Routine YAML edits (bumping scanner pins, tweaking defaults) can use ordinary feature branches + PRs. Use ADV gates (`/adv-proposal` etc.) for substantive changes: adding a new gate workflow, breaking the input contract, changing default severity, etc.
