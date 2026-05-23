# Contract Traceability

**Change ID:** addV1Roadmap
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| AC1 | acceptance_criterion | pass | test | Reviewer PASS: root ROADMAP.md exists; read evidence lines 1-109. |
| AC2 | acceptance_criterion | pass | test | ROADMAP.md includes `## V1 goals` lines 27-34 and `## V1 non-goals` lines 36-42. |
| AC3 | acceptance_criterion | pass | test | ROADMAP.md separates `Reusable workflow readiness`, `PokeEdge backend pilot`, `Container deploy gate`, and `Deferred PokeEdge Web follow-up` milestone sections. |
| AC4 | acceptance_criterion | pass | test | ROADMAP.md V1 non-goals include paid GHAS, CodeQL/SARIF upload, SonarCloud/dashboard, and Secret Protection push-blocking replacement exclusions. |
| AC5 | acceptance_criterion | pass | test | ROADMAP.md includes exact CI actionlint Docker command; adv_run_test executed it with exitCode 0. |
| C1 | constraint | respected | static_check | ROADMAP.md states workflow YAML and CI override roadmap prose if they conflict. |
| C2 | constraint | respected | static_check | Reviewer reports git diff from main shows only ROADMAP.md added; no workflow behavior changes. |
| C3 | constraint | respected | static_check | Reviewer assessed roadmap as compact and focused at 109 lines. |
| DONT1 | avoidance | respected | review | ROADMAP.md keeps paid GHAS, SonarCloud, CodeQL/SARIF upload, and dashboards out of V1 non-goals. |
| DONT2 | avoidance | respected | review | ROADMAP.md keeps PokeEdge-specific tuning in examples until backend pilot evidence exists and lists pilot tasks separately. |
| DONT3 | avoidance | respected | review | ROADMAP.md includes only actionlint Docker command for this repo and says deferred web work must preserve existing commands instead of inventing flow. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-1fe9ac0ffe2f | AC1, AC2, AC3, AC4 |  | C1, C2, C3, DONT1, DONT2, DONT3 |  |
| tk-73f8f451b778 |  | AC1, AC2, AC3, AC4, AC5 | C1, C2, C3, DONT1, DONT2, DONT3 |  |
