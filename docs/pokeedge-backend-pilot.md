# PokeEdge Backend Conformance

> History: this began as the backend security-gate *pilot*. The pilot proved the
> reusable package; the gate is now **permanent and required** under the
> [Sharperflow CI Standard](ci-standard.md). This doc now describes how the
> backend conforms to that standard (Change B), not a trial.

Goal: bring PokeEdge backend CI into conformance with the org CI standard using a
no-GHAS/no-Sonar security package.

## Package validation (done)

- Reusable workflow syntax validated with `actionlint`.
- Defaults stay high-signal:
  - Bandit: high severity + high confidence only.
  - Trivy: HIGH/CRITICAL only, ignore unfixed.
  - Semgrep: Python + FastAPI rules.
- No SARIF upload assumptions (private-repo GitHub code scanning is not enabled).

## Conformance: fold the security gate into CI

Per the standard, the security gate is a **job inside the app CI workflow** (not a
standalone `security-gates-pilot.yml`), and only the `Sharperflow CI Gate` summary
is required. Pin by SHA + version comment.

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
      bandit-config: "configs/security/bandit.yaml"

  ci-gate:
    name: Sharperflow CI Gate
    if: ${{ !cancelled() }}
    needs: [fast-checks, test, build, security]
    runs-on: ubuntu-latest
    steps:
      - name: Verify required jobs
        env:
          RESULTS: ${{ join(needs.*.result, ',') }}
        run: |
          IFS=','
          for r in $RESULTS; do
            case "$r" in success|skipped) ;; *) echo "::error::job result=$r"; exit 1 ;; esac
          done
```

Then apply the org ruleset and **remove the stale classic required-status-check
contexts** (e.g. the ghost `Run Constitution §7.4 Quality Chain`) so the ruleset's
`Sharperflow CI Gate` is the single source. Drop the inline OSV + generic Semgrep
duplicated by the reusable gate; keep repo-custom `.semgrep/*` rules and the IaC
`:latest` guardrail as a thin local job.

## Production deploy gate

After the PokeEdge deploy workflow builds an image, call the container gate:

```yaml
jobs:
  image-security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/container-security-gate.yml@5afaf289aafeebc18466ca19621ad4d7e9289139  # v0.3.2
    with:
      image-ref: "ghcr.io/Sharper-Flow/pokeedge-api:${{ github.sha }}"
```

## Known tradeoffs

- No CodeQL taint/dataflow equivalent without GitHub Code Security.
- No hosted security dashboard by default.
- Gitleaks is CLI-based; GitHub Secret Protection push blocking is not replaced.
- Semgrep CE is mostly intra-file/intra-function compared with paid engines.
