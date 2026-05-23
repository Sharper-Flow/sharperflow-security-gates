# Proposal: Add v1 roadmap

## Problem
This repository has reusable security gate workflows and pilot notes, but no compact V1 roadmap that sequences what should be stabilized before treating the package as a reusable Sharper Flow standard.

## Proposed direction
Add a root `ROADMAP.md` focused on V1 readiness for the reusable security gates. The roadmap should be concise and repo-specific, using the existing README, workflow defaults, self-test workflow, examples, and pilot docs as sources of truth.

## Scope
- Create or update root `ROADMAP.md`.
- Document V1 goals and non-goals.
- Sequence milestones for workflow validation, PokeEdge backend pilot, reusable hardening, container gate readiness, and later frontend follow-up.
- Preserve the high-signal/no-paid-dashboard design posture already documented.

## Success criteria
- `ROADMAP.md` exists at repo root and is compact enough to be used as a planning entrypoint.
- Roadmap items are derived from current repo sources: README, workflows, docs, examples, and configs.
- The roadmap distinguishes reusable V1 work from PokeEdge pilot-only work and deferred frontend follow-up.
- Existing CI workflow lint still passes.

## Error handling / rollback
If the roadmap contradicts executable workflow behavior, update it to match the workflow source of truth. If verification fails, do not claim completion until fixed or explicitly blocked.

## Out of scope
- Implementing new workflow behavior in this change.
- Making PokeEdge-specific wiring reusable before the backend pilot proves it.
- Adding paid GitHub Advanced Security, CodeQL/SARIF upload, SonarCloud, or hosted dashboard assumptions.
