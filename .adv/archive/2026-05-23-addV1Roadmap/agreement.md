# Agreement: Add v1 roadmap

## Objectives
- Add a root `ROADMAP.md` that is the planning entrypoint for V1 readiness.
- Sequence work across reusable workflow validation, PokeEdge backend pilot, reusable hardening, container gate readiness, and PokeEdge Web follow-up.
- Keep the roadmap grounded in current repo behavior and docs, not speculative security-program features.

## Acceptance criteria
- `ROADMAP.md` exists at the repository root.
- It identifies V1 goals and non-goals.
- It separates reusable V1 work from PokeEdge backend pilot tasks and deferred frontend follow-up.
- It preserves the high-signal default posture: no paid GHAS/CodeQL/SARIF upload/SonarCloud/dashboard assumptions.
- It includes verification guidance that matches CI: `docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7`.

## Constraints
- Treat workflow YAML and CI as executable source of truth when prose conflicts.
- Do not change workflow behavior as part of this roadmap-only change.
- Keep the document compact; no exhaustive project plan or tutorial.

## Avoidances
- Do not introduce required paid services or hosted security dashboards.
- Do not promote PokeEdge-specific settings into reusable defaults before pilot evidence.
- Do not invent package-manager commands; this repo has no app/package manifest.
