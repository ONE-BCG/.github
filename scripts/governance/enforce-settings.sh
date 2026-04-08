#!/usr/bin/env bash
# enforce-settings.sh
# Usage: ./enforce-settings.sh 'org/repo' '<gh_token>'
#
# Idempotent — safe to re-run. Enforces repository settings from
# policies/repo-rules.json (repo_settings block) via the GitHub REST API:
#   - Merge strategy (squash only)
#   - Delete branch on merge
#   - Disable wiki / projects
#   - Enable vulnerability alerts, secret scanning, push protection, Dependabot
#   - Set default branch to main

set -euo pipefail

REPO="$1"
GH_TOKEN="$2"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_RULES="$ROOT/policies/repo-rules.json"

API="https://api.github.com"
AUTH_HEADER="Authorization: Bearer $GH_TOKEN"
ACCEPT_HEADER="Accept: application/vnd.github+json"
API_VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"

echo "==> Enforcing repo settings for $REPO"

# ── Extract settings from policy file ────────────────────────────────────────
SETTINGS=$(python3 -c "import json; d=json.load(open('$REPO_RULES')); print(json.dumps(d['repo_settings']))")

DELETE_ON_MERGE=$(echo "$SETTINGS"   | python3 -c "import json,sys; print(str(json.load(sys.stdin)['delete_branch_on_merge']).lower())")
ALLOW_MERGE=$(echo "$SETTINGS"       | python3 -c "import json,sys; print(str(json.load(sys.stdin)['allow_merge_commit']).lower())")
ALLOW_SQUASH=$(echo "$SETTINGS"      | python3 -c "import json,sys; print(str(json.load(sys.stdin)['allow_squash_merge']).lower())")
ALLOW_REBASE=$(echo "$SETTINGS"      | python3 -c "import json,sys; print(str(json.load(sys.stdin)['allow_rebase_merge']).lower())")
HAS_WIKI=$(echo "$SETTINGS"          | python3 -c "import json,sys; print(str(json.load(sys.stdin)['has_wiki']).lower())")
HAS_PROJECTS=$(echo "$SETTINGS"      | python3 -c "import json,sys; print(str(json.load(sys.stdin)['has_projects']).lower())")
SQUASH_TITLE=$(echo "$SETTINGS"      | python3 -c "import json,sys; print(json.load(sys.stdin)['squash_merge_commit_title'])")
SQUASH_MSG=$(echo "$SETTINGS"        | python3 -c "import json,sys; print(json.load(sys.stdin)['squash_merge_commit_message'])")

# ── Patch repo settings ───────────────────────────────────────────────────────
echo "    Patching core repository settings"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PATCH "$API/repos/$REPO" \
  -H "$AUTH_HEADER" \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION_HEADER" \
  -H "Content-Type: application/json" \
  -d "{
    \"default_branch\": \"main\",
    \"delete_branch_on_merge\": $DELETE_ON_MERGE,
    \"allow_merge_commit\": $ALLOW_MERGE,
    \"allow_squash_merge\": $ALLOW_SQUASH,
    \"allow_rebase_merge\": $ALLOW_REBASE,
    \"squash_merge_commit_title\": \"$SQUASH_TITLE\",
    \"squash_merge_commit_message\": \"$SQUASH_MSG\",
    \"has_wiki\": $HAS_WIKI,
    \"has_projects\": $HAS_PROJECTS
  }")

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "    OK ($HTTP_CODE): core settings applied"
else
  echo "    ERROR ($HTTP_CODE): failed to patch repo settings"
  exit 1
fi

# ── Enable vulnerability alerts ───────────────────────────────────────────────
echo "    Enabling vulnerability alerts"
curl -s -o /dev/null \
  -X PUT "$API/repos/$REPO/vulnerability-alerts" \
  -H "$AUTH_HEADER" \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION_HEADER"

# ── Enable secret scanning ────────────────────────────────────────────────────
echo "    Enabling secret scanning + push protection"
curl -s -o /dev/null \
  -X PATCH "$API/repos/$REPO" \
  -H "$AUTH_HEADER" \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION_HEADER" \
  -H "Content-Type: application/json" \
  -d '{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}'

# ── Enable Dependabot security updates ───────────────────────────────────────
echo "    Enabling Dependabot security updates"
curl -s -o /dev/null \
  -X PUT "$API/repos/$REPO/automated-security-fixes" \
  -H "$AUTH_HEADER" \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION_HEADER"

echo "==> Settings enforced: $REPO"
