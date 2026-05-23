# PokeEdge Backend Pilot

Goal: prove a no-GHAS/no-Sonar security package on a smaller reusable repo
before changing PokeEdge backend CI.

## Phase 1: package validation

- Validate reusable workflow syntax with `actionlint`.
- Keep defaults high signal:
  - Bandit: high severity + high confidence only.
  - Trivy: HIGH/CRITICAL only, ignore unfixed.
  - Semgrep: Python + FastAPI rules.
- Avoid SARIF upload assumptions because private-repo GitHub code scanning is
  not enabled.

## Phase 2: PokeEdge backend dry run

Add a non-required workflow in PokeEdge:

```yaml
name: Security Gates Pilot

on:
  workflow_dispatch:
  pull_request:
    branches: [main]

jobs:
  python-security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@main
    with:
      python-version: "3.13"
      scan-paths: "api services clients models core common repositories integrations utils"
      lockfile-path: "uv.lock"
      bandit-config: "configs/security/bandit.yaml"
```

Do not make it required until:

1. false positives are triaged,
2. suppressions are reviewed,
3. runtime is measured,
4. failure modes are documented.

## Phase 3: production deploy gate

After the PokeEdge deploy workflow builds an image, call:

```yaml
jobs:
  image-security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/container-security-gate.yml@main
    with:
      image-ref: "ghcr.io/Sharper-Flow/pokeedge-api:${{ github.sha }}"
```

## Known tradeoffs

- No CodeQL taint/dataflow equivalent without GitHub Code Security.
- No hosted security dashboard by default.
- Gitleaks is CLI-based; GitHub Secret Protection push blocking is not replaced.
- Semgrep CE is mostly intra-file/intra-function compared with paid engines.
