# PokeEdge Web Follow-up

The first implementation is Python-focused for PokeEdge backend. PokeEdge Web
should get a separate reusable workflow after the backend pilot stabilizes.

Candidate gates:

- Semgrep JavaScript/TypeScript + React rules.
- OSV or npm audit equivalent for package lockfiles.
- Trivy filesystem scan for IaC/secrets.
- Gitleaks secret scan.
- Optional dependency-review if GitHub settings support it.

Open questions:

- Package manager and lockfile source of truth.
- Frontend deploy image/static artifact scan target.
- Existing lint/type/test commands to preserve.
