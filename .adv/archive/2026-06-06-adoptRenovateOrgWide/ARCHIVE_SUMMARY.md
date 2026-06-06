# Archive: Adopt Renovate org wide

**Change ID:** adoptRenovateOrgWide
**Archived:** 2026-06-06T23:46:51.137Z
**Created:** 2026-06-06T22:17:38.201Z

## Tasks Completed

- ✅ Add shared Renovate preset + security-gates renovate.json (native)
  > Task checkpoint completed
- ✅ Renovate App install + allow_auto_merge + onboarding (privileged; handoff where no scope)
  > Task checkpoint completed
- ✅ Document the Renovate dependency-update policy in ci-standard.md
  > Task checkpoint completed
- ✅ Per-repo renovate.json (pokeedge, web, advance) — cross-project PRs
  > Task checkpoint completed
- ✅ Remove pokeedge dependabot.yml after Renovate onboarding (PR)
  > Task checkpoint completed
- ✅ Verify Renovate adoption
  > Task checkpoint completed

## Specs Modified


## Wisdom Accumulated

- **[convention]** Automerge policy amended mid-execution (user decision, supersedes AC1/DONT2 "never automerge major/prod"). New policy: preset sets top-level automerge:true → ALL update types (incl. majors + production deps) auto-merge once the repo's required check is green. Justification: pokeedge+web require Sharperflow CI Gate = a real functional suite (unit+integration(pgvector)+e2e(playwright)+contract), and Renovate only merges GREEN — a breaking update fails the suite, the PR stays open red, and never merges. The human review being removed was low-value (user would never perform it). 7-day cooldown (minimumReleaseAge) retained; security fixes exempted via vulnerabilityAlerts.minimumReleaseAge "0 days". advance is the exception: no Sharperflow CI Gate yet (deferred until conformAdvanceCi) → its renovate.json sets automerge:false + repo allow_auto_merge stays off (double guard). An LLM merge-reviewer was considered and deferred to a separate change: the test suite is the load-bearing gate; an agent adds only marginal changelog/deprecation signal, not safety.
