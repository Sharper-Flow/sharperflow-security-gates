# Executive Summary: Optimize CI Test Actions

## Problem
PokeEdge pr-gate burned 28,500 minutes ($148 net) in 8 days of June 2026 — a 3.5× spike vs prior months. Root causes: single binary path-scope triggering all expensive jobs on every PR, no draft PR optimization, and PokeEdge-Web lacking dependency caching and running fast-checks sequentially.

## What Changed
Three PRs targeting the org CI pipeline:
1. **sharperflow-security-gates#16**: Added Bun dependency caching (`actions/cache@v5.0.5`) to the shared `setup-bun-node` composite action, caching `~/.bun/install/cache` keyed on `bun.lock` hash. Saves ~20s per call × 6 calls/run in PokeEdge-Web.
2. **PokeEdge#356**: Added granular path-scope outputs (`tests`, `migrations`, `openapi`) to the `changes` job; gated integration/E2E/acceptance/contract-live on specific outputs; added draft PR skip for the 4 most expensive jobs.
3. **PokeEdge-Web#134**: Split sequential `fast-checks` into parallel `lint` + `typecheck` jobs; gated integration E2E on `src/`+`tests/` path changes.

## Measured Impact
- PokeEdge PR #356: **11 of 17 jobs skipped** on a workflow-only change (was: all 17 run). Path-scope working as designed.
- PokeEdge-Web PR #134: **Lint (63s) and Typecheck (51s) ran in parallel** instead of sequential 99s. Integration E2E correctly skipped.
- Expected savings: 550-1000 min/month ($3-6/month net).

## Verified
- All 3 PRs pass actionlint
- All required status checks report terminal results (no stuck gates)
- No merge-queue or ruleset behavior changes
- Backward-compatible composite action change
