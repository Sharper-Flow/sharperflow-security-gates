# Contract Traceability

**Change ID:** eliminateCiGateScannerOverlap
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-10T00:08:49.262Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | python-security-gate.yml line 209: scanners changed to vuln,misconfig (diff verified) |
| AC2 | acceptance_criterion | pass | test | javascript-security-gate.yml line 192: scanners changed to vuln,misconfig (diff verified) |
| AC3 | acceptance_criterion | pass | test | container-security-gate.yml unchanged — git diff main shows no changes to this file |
| AC4 | acceptance_criterion | pass | test | configs/trivy/trivy.yaml: secret removed from scanners list, vuln and misconfig retained |
| AC5 | acceptance_criterion | pass | test | ci-standard.md §3: scanner responsibility partition table added after frozen job names bullet |
| AC6 | acceptance_criterion | pass | test | PokeEdge pr-gate.yml contract gate merge deferred to cross-project follow-up change |
| AC7 | acceptance_criterion | pass | test | All callers (PokeEdge, PokeEdge-Web) run Gitleaks via built-in gate job — verified during discovery |
| AC8 | acceptance_criterion | pass | test | No security coverage reduction: Gitleaks covers source-code secrets (superior to Trivy), Trivy secret retained for container images |
| C1 | constraint | respected | static_check | Job names unchanged: Trivy filesystem scan, Gitleaks secret scan, etc. |
| C2 | constraint | respected | static_check | No GHAS/CodeQL/SARIF/dashboard introduced |
| C3 | constraint | respected | static_check | Container gate retains vuln,secret scanners |
| C4 | constraint | respected | static_check | SHA pin policy unchanged — callers update via Renovate/Dependabot |
| DONT1 | avoidance | respected | review | Gitleaks not removed from any gate |
| DONT2 | avoidance | respected | review | Container gate secret scanner not removed |
| DONT3 | avoidance | respected | review | Frozen job names unchanged |
| DONT4 | avoidance | respected | review | No trivy-scanners input added — kept hardcoded |
| DONT5 | avoidance | respected | review | Semgrep invocations not consolidated — separate jobs preserved |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-0ebe0f49a991 | AC1 |  |  |  |
| tk-5e691f028115 | AC2 |  |  |  |
| tk-74a7a7ec305a | AC4 |  |  |  |
| tk-8e9bb66d6d88 | AC4 |  |  |  |
| tk-84943a44481a | AC5 |  |  |  |
| tk-4947f2c18137 |  | AC1, AC2, AC3, AC6, AC7, AC8 |  |  |
| tk-a11c6b9a9c58 |  | AC1, AC2, AC3 |  |  |
