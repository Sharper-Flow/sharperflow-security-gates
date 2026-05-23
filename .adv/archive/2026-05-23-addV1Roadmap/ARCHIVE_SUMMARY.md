# Archive: Add v1 roadmap

**Change ID:** addV1Roadmap
**Archived:** 2026-05-23T00:44:33.487Z
**Created:** 2026-05-23T00:23:50.093Z

## Tasks Completed

- ✅ Create root ROADMAP.md from approved design
  > Added compact root ROADMAP.md with source-of-truth note, current state, V1 goals/non-goals, milestone buckets, hardening candidates, deferred PokeEdge Web follow-up, and CI verification guidance. Preserved workflow behavior details and avoided workflow/config changes.
- ✅ Verify ROADMAP.md against contract and CI lint
  > Reviewed ROADMAP.md against the approved contract and design guardrails. Confirmed V1 goals/non-goals, reusable/pilot/container/hardening/deferred buckets, no behavior changes, no invented package-manager commands, and exact CI actionlint command. Ran actionlint successfully.

## Specs Modified


## Wisdom Accumulated

- **[gotcha]** In this repo, Trivy scanner scope differs by workflow: Python filesystem gate scans `vuln,secret,misconfig`, while container image gate scans `vuln,secret` only. Roadmap/docs should preserve that asymmetry instead of summarizing both as the same scan.
