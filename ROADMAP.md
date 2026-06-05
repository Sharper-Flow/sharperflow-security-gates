# V1 Roadmap

Planning entrypoint for making these reusable security gates safe to roll out
across Sharper Flow repos.

> **Status update:** the pilot phase is complete. The reusable security gate is
> now **permanent and required** under the **[Sharperflow CI Standard](docs/ci-standard.md)**.
> App repos conform to that standard (single `Sharperflow CI Gate` summary check,
> shared setup composites, org ruleset). Remaining items below are
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
- [ ] Conform PokeEdge backend CI to the standard (single `Sharperflow CI Gate`
  summary, fold security into CI, shared composite, org ruleset) — Change B.
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
- [ ] Conform PokeEdge Web CI to the standard (single `Sharperflow CI Gate`
  summary, fold security into CI, `setup-bun-node` composite, org ruleset,
  require the real fast-checks/test/build jobs) — Change C.
- [ ] Decide whether frontend deploy scan targets an image or static artifact.
- [ ] Preserve existing web lint/type/test commands; do not invent new
  verification flow.

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
