# Design: Add v1 roadmap

## Artifact
Create root `ROADMAP.md` as the V1 planning entrypoint. It is documentation only; no workflow YAML or config behavior changes.

## Structure
- Title and source-of-truth note: workflow YAML/CI override prose if they conflict.
- Current state: summarize existing reusable gates and self-test coverage.
- V1 goals: what must be true before the package is treated as a reusable Sharper Flow standard.
- V1 non-goals: paid GHAS, CodeQL/SARIF upload, SonarCloud, hosted dashboards, and GitHub Secret Protection push-blocking replacement.
- Milestone checklist split into buckets:
  - reusable workflow V1 readiness,
  - PokeEdge backend pilot,
  - container image deploy gate,
  - V1 hardening candidates that require separate changes,
  - deferred PokeEdge Web follow-up.
- Verification: actionlint Docker command and required-file checks from `self-test.yml`; no package-manager commands.

## Grounding rules
- Python filesystem Trivy must be described as `vuln,secret,misconfig` with HIGH/CRITICAL and ignore-unfixed, matching `.github/workflows/python-security-gate.yml`.
- Container Trivy must be described as `vuln,secret` only, matching `.github/workflows/container-security-gate.yml`.
- OSV behavior must mention skip-with-warning when the lockfile is absent.
- Gitleaks behavior must mention the direct pinned container invocation and not imply `configs/gitleaks/gitleaks.toml` is wired into the workflow.
- `configs/trivy/trivy.yaml` remains local-experiment config, not workflow input.
- Caller-side PokeEdge paths such as `configs/security/bandit.yaml` are caller repo paths and should not be corrected in this repo.

## Validator result
Independent validator verdict: PASS. Required adjustments incorporated: preserve fs/image Trivy scanner asymmetry, keep behavior-changing hardening items separate, avoid invented test runners, and add a workflow-source-of-truth note.
