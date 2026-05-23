# Acceptance

Reviewed at: 

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| AC1 | acceptance_criterion | `ROADMAP.md` exists at the repository root. | pass | Reviewer PASS: root ROADMAP.md exists; read evidence lines 1-109. |
| AC2 | acceptance_criterion | It identifies V1 goals and non-goals. | pass | ROADMAP.md includes `## V1 goals` lines 27-34 and `## V1 non-goals` lines 36-42. |
| AC3 | acceptance_criterion | It separates reusable V1 work from PokeEdge backend pilot tasks and deferred frontend follow-up. | pass | ROADMAP.md separates `Reusable workflow readiness`, `PokeEdge backend pilot`, `Container deploy gate`, and `Deferred PokeEdge Web follow-up` milestone sections. |
| AC4 | acceptance_criterion | It preserves the high-signal default posture: no paid GHAS/CodeQL/SARIF upload/SonarCloud/dashboard assumptions. | pass | ROADMAP.md V1 non-goals include paid GHAS, CodeQL/SARIF upload, SonarCloud/dashboard, and Secret Protection push-blocking replacement exclusions. |
| AC5 | acceptance_criterion | It includes verification guidance that matches CI: `docker run --rm -v "$PWD:/repo" --workdir /repo rhysd/actionlint:1.7.7`. | pass | ROADMAP.md includes exact CI actionlint Docker command; adv_run_test executed it with exitCode 0. |
| C1 | constraint | Treat workflow YAML and CI as executable source of truth when prose conflicts. | respected | ROADMAP.md states workflow YAML and CI override roadmap prose if they conflict. |
| C2 | constraint | Do not change workflow behavior as part of this roadmap-only change. | respected | Reviewer reports git diff from main shows only ROADMAP.md added; no workflow behavior changes. |
| C3 | constraint | Keep the document compact; no exhaustive project plan or tutorial. | respected | Reviewer assessed roadmap as compact and focused at 109 lines. |
| DONT1 | avoidance | Do not introduce required paid services or hosted security dashboards. | respected | ROADMAP.md keeps paid GHAS, SonarCloud, CodeQL/SARIF upload, and dashboards out of V1 non-goals. |
| DONT2 | avoidance | Do not promote PokeEdge-specific settings into reusable defaults before pilot evidence. | respected | ROADMAP.md keeps PokeEdge-specific tuning in examples until backend pilot evidence exists and lists pilot tasks separately. |
| DONT3 | avoidance | Do not invent package-manager commands; this repo has no app/package manifest. | respected | ROADMAP.md includes only actionlint Docker command for this repo and says deferred web work must preserve existing commands instead of inventing flow. |

