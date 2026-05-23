# Sharper Flow Security Gates

Reusable, low-cost security gates for Sharper Flow repositories.

This repo is the test bed before integrating the package into PokeEdge backend
and PokeEdge Web.

## Initial targets

- Python API repositories, especially PokeEdge backend.
- JavaScript/TypeScript web repositories, especially PokeEdge Web.

## Gates included

| Area | Tool | Purpose |
|---|---|---|
| SAST | Semgrep CE | Python/FastAPI security rules + repo custom rules |
| Python security lint | Bandit | High-severity/high-confidence Python AST checks |
| Dependencies | OSV Scanner | Known vulnerabilities from lockfiles |
| Secrets | Gitleaks CLI | Hardcoded secret detection without GitHub Secret Protection |
| Filesystem/container | Trivy | CVEs, IaC misconfig, secrets, image deploy gate |

## Reusable workflows

```yaml
jobs:
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/python-security-gate.yml@main
    with:
      python-version: "3.13"
      scan-paths: "api services clients models core common repositories integrations utils"
      lockfile-path: "uv.lock"
```

Container image gate:

```yaml
jobs:
  image-security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/container-security-gate.yml@main
    with:
      image-ref: "ghcr.io/OWNER/IMAGE:${{ github.sha }}"
```

JavaScript/TypeScript gate:

```yaml
permissions: {}

jobs:
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/javascript-security-gate.yml@main
    permissions:
      contents: read
    with:
      scan-paths: "src scripts infra"
      lockfile-path: "bun.lock"
```

## Design posture

- Fail only on high-signal issues by default.
- Prefer repo-owned config over hosted dashboards.
- No paid GitHub Advanced Security dependency.
- No SonarCloud LOC usage.
- Keep PokeEdge-specific tuning in examples until proven reusable.

See `docs/pokeedge-backend-pilot.md` for the first integration plan.
