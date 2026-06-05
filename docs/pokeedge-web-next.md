# PokeEdge Web Conformance

> History: PokeEdge Web started with a non-required JS/TS security *pilot*. Under
> the [Sharperflow CI Standard](ci-standard.md) the security gate is now
> **permanent and required**, and the web app conforms via Change C. PokeEdge Web
> uses the JavaScript/TypeScript reusable gate because the Python gate is
> backend-specific.

## Conformance: fold the security gate into CI

Add the gate as a `security` job inside the web CI workflow and require only the
`Sharperflow CI Gate` summary. Pin by SHA + version comment.

```yaml
jobs:
  security:
    uses: Sharper-Flow/sharperflow-security-gates/.github/workflows/javascript-security-gate.yml@e21e07a7faa2396662875fac9679f08b6b4efc9d  # v0.3.1
    permissions:
      contents: read
    with:
      scan-paths: "src scripts infra"
      lockfile-path: "bun.lock"
      semgrep-excludes: "src/lib/api/generated .svelte-kit build coverage playwright-report test-results node_modules"

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

Use the shared `setup-bun-node` composite for setup. Apply the org ruleset and
require **only** `Sharperflow CI Gate` (today web requires only `Build` — the real
fast-checks/test jobs are not required; conformance fixes that by gating on the
summary).

## Gates included

- Semgrep JavaScript/TypeScript rules.
- OSV Scanner against `bun.lock`.
- Gitleaks secret scan.
- Trivy filesystem scan for vulnerabilities, secrets, and IaC misconfig.

## Known tradeoffs

- Semgrep CE handles JS/TS source files, but not Svelte single-file components as
  first-class parsed Svelte templates.
- No CodeQL/GitHub Advanced Security assumption.

Open questions:

- Frontend deploy image/static artifact scan target.
- Whether `dependency-review` is useful given this repo's GitHub settings.
