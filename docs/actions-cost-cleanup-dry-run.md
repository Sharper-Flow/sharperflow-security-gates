# Actions Cost Cleanup Dry Run

Read-only cache/artifact cleanup evidence for `reduceActionsCost`.

No deletion was performed. Destructive cleanup still requires explicit approval
against a bounded candidate set.

## PokeEdge cache inventory

Source: `gh api repos/Sharper-Flow/PokeEdge/actions/caches?per_page=100&page=N`

Snapshot taken during execution:

| Cache class | Count | Size | Refs | Oldest last access | Newest last access |
|---|---:|---:|---:|---|---|
| Trivy (`cache-trivy-*`, `trivy-binary-*`) | 132 | 8,816.9 MB | 122 | 2026-06-05T00:11:38Z | 2026-06-12T04:09:29Z |
| setup-uv | 52 | 51.2 MB | 24 | 2026-06-04T21:10:12Z | 2026-06-12T05:06:21Z |

### PokeEdge deletion candidate rule

Safe proposal, pending explicit approval:

- Delete `cache-trivy-*` entries older than 7 days by `last_accessed_at`.
- Keep current-day and recent-week entries.
- Do not delete `setup-uv` caches unless a separate dependency-cache cleanup is approved.

Example candidates observed:

| ID | Key | Ref | Size bytes | Last accessed |
|---:|---|---|---:|---|
| 4777239892 | `cache-trivy-2026-06-04` | `refs/heads/main` | 69,722,042 | 2026-06-05T00:11:38Z |
| 4831736763 | `cache-trivy-2026-06-06` | `refs/pull/271/merge` | 70,144,281 | 2026-06-06T17:51:20Z |
| 4832204081 | `cache-trivy-2026-06-06` | `refs/pull/273/merge` | 70,144,735 | 2026-06-06T18:12:19Z |

## PokeEdge-Web cache inventory

Source: `gh api repos/Sharper-Flow/PokeEdge-Web/actions/caches?per_page=100&page=N`

Snapshot taken during execution:

| Cache class | Count | Size | Refs | Oldest last access | Newest last access |
|---|---:|---:|---:|---|---|
| BuildKit (`buildkit-*`, `index-buildkit*`) | 526 | 9,596.3 MB | 2 | 2026-06-09T02:47:47Z | 2026-06-12T05:07:55Z |
| Trivy (`cache-trivy-*`, `trivy-binary-*`) | 12 | 779.7 MB | 8 | 2026-06-10T03:38:38Z | 2026-06-12T04:53:31Z |
| Bun | 1 | 34.5 MB | 1 | 2026-06-12T05:00:51Z | 2026-06-12T05:00:51Z |

### PokeEdge-Web deletion candidate rule

Safe proposal, pending explicit approval:

- Prefer forward fix first: BuildKit cache mode changed from `max` to `min` in app workflow edits.
- Delete BuildKit entries older than 7 days only after the forward fix lands.
- Delete old `cache-trivy-*` entries older than 7 days by `last_accessed_at`.
- Keep current Bun dependency cache.

Example BuildKit candidates observed:

| ID | Key prefix | Ref | Size bytes | Last accessed |
|---:|---|---|---:|---|
| 4921265924 | `buildkit-blob-1-sha256:000fef...` | `refs/heads/main` | 17,242,981 | 2026-06-10T16:34:55Z |
| 4958436506 | `buildkit-blob-1-sha256:003933...` | `refs/heads/staging` | 121,421,177 | 2026-06-11T22:48:52Z |
| 4892102593 | `buildkit-blob-1-sha256:005e10...` | `refs/heads/main` | 85,586,801 | 2026-06-09T18:20:01Z |

## Mutation boundary

No `DELETE /repos/{owner}/{repo}/actions/caches/{cache_id}` or artifact-delete API
call was made during this task. If cleanup is approved later, use an explicit
candidate list generated from the current API response immediately before
deletion.
