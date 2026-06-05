#!/usr/bin/env bash
#
# Apply the Sharperflow org branch-protection ruleset (protection-as-code).
#
# Idempotent: looks up an existing org ruleset by name and updates it (PUT),
# otherwise creates it (POST). Use --dry-run to preview without mutating.
#
# Auth: requires a token with `admin:org` (org-admin classic PAT) or a GitHub
# App with org `Administration: write`. The Actions GITHUB_TOKEN is NOT
# sufficient. Authenticate gh first (`gh auth login`) or export GH_TOKEN.
#
# Reading existing rulesets (GET /orgs/{org}/rulesets) also requires admin:org;
# under --dry-run without that scope the lookup is skipped and a create is shown.

set -euo pipefail

ORG="Sharper-Flow"
RULESET_FILE="rulesets/sharperflow-app-protection.json"
DRY_RUN=false

usage() {
	cat <<'EOF'
Apply the Sharperflow org branch-protection ruleset.

Usage: scripts/apply-ruleset.sh [options]

Options:
  --org <name>     GitHub org (default: Sharper-Flow)
  --file <path>    Ruleset JSON (default: rulesets/sharperflow-app-protection.json)
  --dry-run        Show the create/update that would happen; mutate nothing
  -h, --help       Show this help

Auth: token with `admin:org` (org-admin PAT) or a GitHub App with org
`Administration: write`. GITHUB_TOKEN from Actions is NOT sufficient.
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
	--org)
		ORG="$2"
		shift 2
		;;
	--file)
		RULESET_FILE="$2"
		shift 2
		;;
	--dry-run)
		DRY_RUN=true
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "error: unknown argument '$1'" >&2
		usage
		exit 2
		;;
	esac
done

if ! command -v gh >/dev/null 2>&1; then
	echo "error: gh CLI not found on PATH" >&2
	exit 2
fi
if [ ! -f "$RULESET_FILE" ]; then
	echo "error: ruleset file '$RULESET_FILE' not found" >&2
	exit 2
fi

NAME="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$RULESET_FILE")"
echo "Org:     $ORG"
echo "Ruleset: $NAME"
echo "File:    $RULESET_FILE"

# Idempotency: find an existing ruleset id by name.
EXISTING_ID="$(gh api "orgs/${ORG}/rulesets" --jq ".[] | select(.name == \"${NAME}\") | .id" 2>/dev/null || true)"

if [ -n "$EXISTING_ID" ]; then
	echo "Existing ruleset id=${EXISTING_ID} -> update (PUT)"
	METHOD="PUT"
	ENDPOINT="orgs/${ORG}/rulesets/${EXISTING_ID}"
else
	echo "No existing ruleset named '${NAME}' -> create (POST)"
	METHOD="POST"
	ENDPOINT="orgs/${ORG}/rulesets"
fi

if [ "$DRY_RUN" = true ]; then
	echo "[dry-run] would ${METHOD} ${ENDPOINT} with payload:"
	cat "$RULESET_FILE"
	exit 0
fi

gh api -X "$METHOD" "$ENDPOINT" --input "$RULESET_FILE" >/dev/null
echo "Applied ruleset '${NAME}' to org '${ORG}'."
