# Contract Traceability

**Change ID:** fixCiFailFastTopology
**Contract Version:** 1
**Rigor:** strict
**Reviewed:** 2026-06-17T01:42:17.477Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| DONT1 | avoidance | respected | review | PokeEdge pr-gate.yml diff: only -x added to unit+api lanes (lines 366, 378). Stage-3 sibling jobs (Integration, E2E, Acceptance, Migration Chain, Contract) untouched. No serialization introduced. |
| DONT2 | avoidance | respected | review | PokeEdge-Web pins bumped (926408c→e241c12b). PokeEdge backend pin (cb39edcd # v0.3.2 in pr-gate.yml:256) untouched. Diff verified: only PokeEdge-Web ci.yml + ci-quality.yml changed. |
| DONT3 | avoidance | respected | review | No Advance repo changes. PRs created only for sharperflow-security-gates (#20), PokeEdge-Web (#193), PokeEdge (#498). Advance floating @v0 flagged in discovery but explicitly out of scope (A3). |
| DONT4 | avoidance | respected | review | Only dependency-review.yml concurrency added. pr_agent.yml, pr-size-labeler.yml, auto-merge.yml untouched (already exclude synchronize). No deploy-chain, BuildKit, or Renovate changes. |
| DONT5 | avoidance | respected | review | Both unit lane (pr-gate.yml:366) and api lane (pr-gate.yml:378) have -x flag. Not split into follow-up. Bundled per A5. |
| DONT6 | avoidance | respected | review | examples/pokeedge-web/ci.yml + pokeedge-python/ci.yml: test/build now have needs: [fast-checks, security]. docs/ci-standard.md §2: Fail-fast edges subsection documents direct + fast-gate + anti-pattern. No anti-example preserved. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-92cc4f9df5cd |  |  | DONT6 | Documentation change; verified by review. Respects DONT6 (no anti-example). |
| tk-c2ad8c175422 |  |  | DONT6 | Declarative YAML; verified by actionlint. Respects DONT6. |
| tk-b7f4419a9eac |  |  | DONT4 | Declarative YAML; verified by actionlint + CI evidence. Respects DONT4. |
| tk-123f5d956c34 |  |  | DONT2, DONT3 | Mechanical pin bump; verified by actionlint + CI. Respects DONT2, DONT3. |
| tk-126b6a6664db |  |  | DONT1, DONT5 | Declarative YAML; verified by actionlint + CI evidence. Respects DONT1, DONT5. |
| tk-135ac356a59e |  |  | DONT4 | Declarative YAML; verified by actionlint. Respects DONT4. |
| tk-eb44b5fe3361 |  |  |  | Verification task (actionlint + CI evidence). Not a contract item implementation. Verifies AC3/AC4/AC7 outcomes. |
