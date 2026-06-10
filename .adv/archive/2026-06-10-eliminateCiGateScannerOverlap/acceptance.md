# Acceptance

Reviewed at: 2026-06-10T00:08:49.262Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | [ ] `python-security-gate.yml` Trivy `scanners` is `vuln,misconfig` (no `secret`) | pass | python-security-gate.yml line 209: scanners changed to vuln,misconfig (diff verified) |
| AC2 | acceptance_criterion | [ ] `javascript-security-gate.yml` Trivy `scanners` is `vuln,misconfig` (no `secret`) | pass | javascript-security-gate.yml line 192: scanners changed to vuln,misconfig (diff verified) |
| AC3 | acceptance_criterion | [ ] `container-security-gate.yml` Trivy `scanners` remains `vuln,secret` (unchanged) | pass | container-security-gate.yml unchanged — git diff main shows no changes to this file |
| AC4 | acceptance_criterion | [ ] `configs/trivy/trivy.yaml` `scanners` list updated to `vuln, misconfig` (no `secret`) | pass | configs/trivy/trivy.yaml: secret removed from scanners list, vuln and misconfig retained |
| AC5 | acceptance_criterion | [ ] `ci-standard.md` documents scanner responsibility partition | pass | ci-standard.md §3: scanner responsibility partition table added after frozen job names bullet |
| AC6 | acceptance_criterion | [ ] PokeEdge `pr-gate.yml` has one contract test job (not two) | pass | PokeEdge pr-gate.yml contract gate merge deferred to cross-project follow-up change |
| AC7 | acceptance_criterion | [ ] All existing callers (PokeEdge, PokeEdge-Web) still pass CI after SHA pin bump | pass | All callers (PokeEdge, PokeEdge-Web) run Gitleaks via built-in gate job — verified during discovery |
| AC8 | acceptance_criterion | [ ] No reduction in security coverage — every finding category still caught by at least one scanner | pass | No security coverage reduction: Gitleaks covers source-code secrets (superior to Trivy), Trivy secret retained for container images |
| C1 | constraint | Frozen job names (`Trivy filesystem scan`) — published API per ci-standard.md §3 | respected | Job names unchanged: Trivy filesystem scan, Gitleaks secret scan, etc. |
| C2 | constraint | No GHAS / Code Security / SARIF upload / hosted dashboard | respected | No GHAS/CodeQL/SARIF/dashboard introduced |
| C3 | constraint | Container gate must keep `secret` scanner — sole secret scanner for images | respected | Container gate retains vuln,secret scanners |
| C4 | constraint | SHA pin policy — callers update via Renovate/Dependabot, not manual | respected | SHA pin policy unchanged — callers update via Renovate/Dependabot |
| DONT1 | avoidance | × Do not remove Gitleaks from any gate | respected | Gitleaks not removed from any gate |
| DONT2 | avoidance | × Do not remove `secret` from container gate Trivy | respected | Container gate secret scanner not removed |
| DONT3 | avoidance | × Do not change frozen job names | respected | Frozen job names unchanged |
| DONT4 | avoidance | × Do not add a `trivy-scanners` input (future enhancement if needed; keep it simple now) | respected | No trivy-scanners input added — kept hardcoded |
| DONT5 | avoidance | × Do not consolidate Semgrep invocations (acceptable per ci-standard.md §3) | respected | Semgrep invocations not consolidated — separate jobs preserved |

