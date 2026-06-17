# Contract Traceability

**Change ID:** syncPokeedgeWebOpenapiJson
**Contract Version:** 1
**Rigor:** standard
**Reviewed:** 2026-06-17T20:52:21.248Z

## Contract Items

| ID | Kind | Status | Evidence Policy | Evidence |
| --- | --- | --- | --- | --- |
| OOS1 | out_of_scope | respected | not_applicable | Pulled from main (gh api repos/Sharper-Flow/PokeEdge/contents/openapi.json?ref=main), not a specific commit. Backend blob SHA 3183e671 referenced in commit message for traceability per C4. |
| OOS2 | out_of_scope | respected | not_applicable | docs/openapi.json synced via gh api download, not hand-edited. Verified canonical-equal to backend via python3 json.dumps(sort_keys=True, separators=(',',':')) comparison. |
| OOS3 | out_of_scope | respected | not_applicable | Did not touch Advance repo. Did not touch PokeEdge backend's check-api-compat workflow. Change scoped to PokeEdge-Web only. |
| OOS4 | out_of_scope | respected | not_applicable | types.gen.ts and zod.gen.ts regenerated AFTER spec sync (atomic change), not before. Both changes committed in same logical operation. |
| OOS5 | out_of_scope | respected | not_applicable | Did not modify scripts/, openapi-ts.config.ts, or the generate:api npm script. Only ran the existing tool. |

## Task References

| Task | Implements | Verifies | Respects | N/A Reason |
| --- | --- | --- | --- | --- |
| tk-31f4b4052598 |  |  |  | Sync + regen task; mechanical work verified by bun run check. |
| tk-fc0f52c6aafd |  |  |  | Verification task; verified by bun run check + bun run test. |
| tk-28e15d15ec32 |  |  |  | Commit/push task; verified by PR creation. |
