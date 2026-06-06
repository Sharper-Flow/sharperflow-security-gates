#!/usr/bin/env bash
#
# Apply the Sharperflow org branch-protection ruleset (protection-as-code).
#
# Idempotent: looks up an existing org ruleset by name and updates it (PUT),
# otherwise creates it (POST). Use --dry-run to preview without mutating.
#
# Release bypass: the Sharperflow default is TAG-ONLY releases — semantic-release
# pushes only a tag (not a commit to the default branch), so NO bypass is needed
# and --no-release-bypass is the normal path. The --bypass-* flags are an escape
# hatch ONLY for repos whose release must push commits to the default branch.
# See docs/ci-standard.md "Release automation".
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
BYPASS_APP_ID="${RELEASE_BYPASS_APP_ID:-}"
BYPASS_TEAM_ID=""
BYPASS_USER_ID=""
NO_RELEASE_BYPASS=false

usage() {
	cat <<'EOF'
Apply the Sharperflow org branch-protection ruleset.

Usage: scripts/apply-ruleset.sh [options]

Options:
  --org <name>           GitHub org (default: Sharper-Flow)
  --file <path>          Ruleset JSON (default: rulesets/sharperflow-app-protection.json)
  --bypass-app-id <id>   Release GitHub App ID -> Integration bypass (ESCAPE HATCH).
                         Use the App ID (gh api /app), NOT the installation or client id.
                         Also settable via env RELEASE_BYPASS_APP_ID.
  --bypass-team-id <id>  Release Team ID -> Team bypass (escape hatch; cloud-only).
  --bypass-user-id <id>  Release User ID -> User bypass (escape hatch; cloud-only).
  --no-release-bypass    Apply with no bypass (NORMAL path for tag-only releases).
  --dry-run              Show the create/update + composed payload; mutate nothing.
  -h, --help             Show this help

Release bypass: tag-only releases (the Sharperflow default) need NO bypass — use
--no-release-bypass. Only repos whose release pushes commits to the default branch
need a bypass actor; for those, prefer --bypass-app-id (a dedicated GitHub App).

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
	--bypass-app-id)
		BYPASS_APP_ID="$2"
		shift 2
		;;
	--bypass-team-id)
		BYPASS_TEAM_ID="$2"
		shift 2
		;;
	--bypass-user-id)
		BYPASS_USER_ID="$2"
		shift 2
		;;
	--no-release-bypass)
		NO_RELEASE_BYPASS=true
		shift
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

# Release guard: require an explicit release-mode choice so the operator is aware
# of how releases interact with the ruleset. Tag-only (the default) needs no
# bypass — pass --no-release-bypass. A bypass actor is only for repos that push
# release commits to the default branch.
if [ -z "${BYPASS_APP_ID}${BYPASS_TEAM_ID}${BYPASS_USER_ID}" ] && [ "$NO_RELEASE_BYPASS" != true ]; then
	echo "error: release mode not specified." >&2
	echo "  Tag-only releases (the Sharperflow default) need no bypass:" >&2
	echo "    pass --no-release-bypass (normal path)." >&2
	echo "  Only if this repo's release pushes commits to the default branch:" >&2
	echo "    pass --bypass-app-id <App ID> (escape hatch)." >&2
	exit 2
fi

# Compose the payload: inject bypass_actors when any bypass id is supplied,
# otherwise use the committed file as-is (bypass_actors: []).
PAYLOAD_FILE="$RULESET_FILE"
if [ -n "${BYPASS_APP_ID}${BYPASS_TEAM_ID}${BYPASS_USER_ID}" ]; then
	TMP_PAYLOAD="$(mktemp)"
	# shellcheck disable=SC2064 # expand TMP_PAYLOAD now for cleanup
	trap "rm -f '${TMP_PAYLOAD}'" EXIT
	python3 - "$RULESET_FILE" "$BYPASS_APP_ID" "$BYPASS_TEAM_ID" "$BYPASS_USER_ID" >"$TMP_PAYLOAD" <<'PY'
import json, sys

path, app_id, team_id, user_id = sys.argv[1:5]
data = json.load(open(path))

actors = []
def add(actor_type, raw):
    if raw:
        actors.append({
            "actor_id": int(raw),
            "actor_type": actor_type,
            "bypass_mode": "always",
        })

add("Integration", app_id)
add("Team", team_id)
add("User", user_id)

if actors:
    data["bypass_actors"] = actors

json.dump(data, sys.stdout, indent=2)
sys.stdout.write("\n")
PY
	PAYLOAD_FILE="$TMP_PAYLOAD"
fi

NAME="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$PAYLOAD_FILE")"
echo "Org:     $ORG"
echo "Ruleset: $NAME"
echo "File:    $RULESET_FILE"
if [ "$PAYLOAD_FILE" != "$RULESET_FILE" ]; then
	echo "Bypass:  injected $(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1])).get("bypass_actors", [])))' "$PAYLOAD_FILE") release actor(s)"
fi

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
	cat "$PAYLOAD_FILE"
	exit 0
fi

gh api -X "$METHOD" "$ENDPOINT" --input "$PAYLOAD_FILE" >/dev/null
echo "Applied ruleset '${NAME}' to org '${ORG}'."
