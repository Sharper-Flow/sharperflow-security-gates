# PokeEdge Web Pilot

The first implementation was Python-focused for PokeEdge backend. PokeEdge Web
uses a separate JavaScript/TypeScript reusable workflow because the Python gate
is intentionally backend-specific.

## Pilot workflow

Add a non-required workflow in PokeEdge Web:

```yaml
name: Security Gates Pilot

on:
  workflow_dispatch:
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions: {}

jobs:
  web-security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/javascript-security-gate.yml@main
    permissions:
      contents: read
    with:
      scan-paths: "src scripts infra"
      lockfile-path: "bun.lock"
      semgrep-excludes: "src/lib/api/generated .svelte-kit build coverage playwright-report test-results node_modules"
```

## Gates included

- Semgrep JavaScript/TypeScript rules.
- OSV Scanner against `bun.lock`.
- Gitleaks secret scan.
- Trivy filesystem scan for vulnerabilities, secrets, and IaC misconfig.

## Known tradeoffs

- Semgrep CE handles JavaScript/TypeScript source files, but not Svelte single-file components as first-class parsed Svelte templates.
- No CodeQL/GitHub Advanced Security assumption.
- The pilot must not be made required until false positives, suppressions, runtime, and failure modes are documented.

Open questions:

- Frontend deploy image/static artifact scan target.
- Whether dependency-review is available and useful for this repo's GitHub settings.
