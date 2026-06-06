# V1 Roadmap

Planning entrypoint for making these reusable security gates safe to roll out
across Sharper Flow repos.

> **Status update:** the pilot phase is complete. The reusable security gate is
> now **permanent and required** under the **[Sharperflow CI Standard](docs/ci-standard.md)**.
> Both flagship apps conform: pokeedge backend (`hardenCiGateContract`, archived)
> and pokeedge-web (#92). Releases are **tag-only** (adhere to the org ruleset, no
> bypass). A **test-tier restructure** (PR-fast vs nightly) is in flight in both
> apps. **SonarCloud is being retired** — see
> [SonarCloud retirement](#sonarcloud-retirement) below. Remaining items are
> follow-ups, not blockers.

Source of truth: workflow YAML and CI override this roadmap if they conflict.
Update this file when executable behavior changes.

## Current state

- `python-security-gate.yml` is a reusable `workflow_call` for Python/FastAPI
  repos. It runs Semgrep + Bandit, OSV lockfile scan, Gitleaks, and optional
  Trivy filesystem scan.
- Python defaults are intentionally high-signal: Python `3.13`, scan path `.`,
  `uv.lock`, Semgrep `p/python p/fastapi`, Semgrep excludes
  `tests scripts migrations`, Bandit high severity + high confidence, Trivy
  `HIGH,CRITICAL`, and `ignore-unfixed`.
- Python filesystem Trivy scans `vuln,secret,misconfig`; container image Trivy
  scans `vuln,secret` only.
- OSV warns and skips when the configured lockfile is missing.
- Gitleaks runs the pinned container image directly with
  `detect --source=/repo --redact --exit-code=1`; the reusable workflow does
  not currently pass `configs/gitleaks/gitleaks.toml`.
- `configs/trivy/trivy.yaml` is for local experiments; workflow gate behavior is
  controlled by YAML inputs.

## V1 goals

- Prove the reusable workflow package before making it a required gate in
  downstream repos.
- Keep defaults high-signal enough for required CI after pilot evidence exists.
- Preserve a no-GHAS/no-Sonar/no-hosted-dashboard path for smaller repos.
- Keep PokeEdge-specific tuning in examples until the backend pilot shows what
  is reusable.

## V1 non-goals

- Paid GitHub Advanced Security dependency.
- CodeQL or SARIF upload assumptions.
- SonarCloud or other hosted dashboard requirement.
- GitHub Secret Protection push-blocking replacement.
- PokeEdge Web reusable workflow before the backend pilot stabilizes.

## Milestones

### Reusable workflow readiness

- [x] Provide Python reusable workflow with Semgrep, Bandit, OSV, Gitleaks, and
  optional Trivy filesystem scan.
- [x] Provide container image reusable workflow that scans a supplied image ref;
  it does not build or publish images.
- [x] Add self-test workflow for actionlint and required docs/config presence.
- [x] Tag stable release refs (latest `v0.3.1`); callers pin by SHA + version
  comment instead of `@main`.
- [ ] Document expected caller-owned suppressions and config paths as findings
  accumulate.

### PokeEdge backend conformance (was: pilot)

- [x] Keep example wiring in `examples/pokeedge-python/`.
- [x] Run the Python gate as CI in PokeEdge backend (pilot).
- [x] Promote the gate to **permanent + required** via the CI standard.
- [x] Conform PokeEdge backend CI to the standard (`hardenCiGateContract`, archived) —
  single `Sharperflow CI Gate` summary, folded security, shared composite, org ruleset.
- [ ] Triage false positives and review suppressions as they surface.

### Container deploy gate

- [x] Provide a deploy-time image scan workflow that accepts `image-ref`.
- [ ] Wire it into PokeEdge only after the deploy workflow has a built image ref.
- [ ] Record image scan runtime and common failure handling before making it
  required.

### V1 hardening candidates — separate changes

These are roadmap items, not behavior changes in this docs-only update.

- [ ] Decide whether `configs/gitleaks/gitleaks.toml` should be passed by the
  reusable workflow or remain local/reference config.
- [ ] Decide whether Trivy local config should stay experimental or become a
  supported caller input.
- [ ] Decide whether absent lockfiles should keep skip-with-warning behavior or
  become configurable hard failures.
- [ ] Decide release/tag pinning guidance for downstream callers.

### PokeEdge Web conformance — Change C

- [x] JS/TS reusable gate exists and runs in PokeEdge Web (pilot).
- [x] Conform PokeEdge Web CI to the standard (#92) — single `Sharperflow CI Gate`
  summary, folded security, `setup-bun-node` composite, org ruleset, real
  fast-checks/test/build required. Releases converted to tag-only (#93).
- [ ] Decide whether frontend deploy scan targets an image or static artifact.
- [ ] Preserve existing web lint/type/test commands; do not invent new
  verification flow.

### Test-tier restructure (in flight)

- [ ] pokeedge `restructureCiTestTiers`: PR-required fast lane + promoted
  integration/e2e/acceptance; `@slow`/perf/fuzz/Bicep → nightly (no merge queue —
  unavailable on Team/private).
- [ ] pokeedge-web `parallelizeWebUnitTests`: drop `--maxWorkers=1` + optional
  shard; state-based waits in the mocked suite.
- [ ] pokeedge-web `hardenIntegrationE2eSuite` (peer): fix + promote the
  real-backend integration-e2e job.

### SonarCloud retirement

- [ ] `retireSonarcloud`: disconnect the `sonarqubecloud` App + disable Automatic
  Analysis, remove `sonar-project.properties` + `SONAR_TOKEN` from both apps,
  reconcile docs to "no Sonar". (Removing the properties file alone does NOT stop
  analysis — Sonar ignores it under Automatic Analysis.)
- Capability-gap followups (research → decide → implement):
  - [ ] `addDuplicationDetection` — jscpd/CPD or accept-drop.
  - [ ] `addMaintainabilityMetrics` — bounded complexity/maintainability or rely on review.
  - [ ] `addDiffCoverageGate` — `diff-cover` on existing coverage artifacts (no dashboard).
  - [ ] `deepenSastDataflow` — Semgrep taint-mode / Opengrep, or accept Semgrep-CE ceiling.

## Verification for this repo

Run the same workflow lint as CI:

```bash
docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7
```

CI also checks that these files exist:

- `README.md`
- `docs/pokeedge-backend-pilot.md`
- `.github/workflows/python-security-gate.yml`
- `.github/workflows/container-security-gate.yml`
- `configs/python/bandit.yaml`
- `configs/gitleaks/gitleaks.toml`
- `configs/trivy/trivy.yaml`
