# Acceptance

Reviewed at: 2026-06-17T20:52:21.248Z

## Contract Review Matrix

| ID | Kind | Requirement | Status | Evidence |
|---|---|---|---|---|
| OOS1 | out_of_scope | Pinning to a specific backend commit (A2) | respected | Pulled from main (gh api repos/Sharper-Flow/PokeEdge/contents/openapi.json?ref=main), not a specific commit. Backend blob SHA 3183e671 referenced in commit message for traceability per C4. |
| OOS2 | out_of_scope | Hand-editing `docs/openapi.json` | respected | docs/openapi.json synced via gh api download, not hand-edited. Verified canonical-equal to backend via python3 json.dumps(sort_keys=True, separators=(',',':')) comparison. |
| OOS3 | out_of_scope | Other openapi drift in other repos (Advance, PokeEdge backend's own check-api-compat) | respected | Did not touch Advance repo. Did not touch PokeEdge backend's check-api-compat workflow. Change scoped to PokeEdge-Web only. |
| OOS4 | out_of_scope | Regenerating types in advance of the contract sync | respected | types.gen.ts and zod.gen.ts regenerated AFTER spec sync (atomic change), not before. Both changes committed in same logical operation. |
| OOS5 | out_of_scope | Changing the `bun run generate:api` script | respected | Did not modify scripts/, openapi-ts.config.ts, or the generate:api npm script. Only ran the existing tool. |

