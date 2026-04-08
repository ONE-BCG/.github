#!/usr/bin/env bash
# apply-branch-rules.sh
# Usage: ./apply-branch-rules.sh 'org/repo' '<gh_token>'
#
# Idempotent — safe to re-run. Applies branch protection rules from
# policies/branch-protection.json and the org ruleset from policies/repo-rules.json
# to the target repository via the GitHub REST API.

set -euo pipefail

REPO="$1"
GH_TOKEN="$2"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BRANCH_POLICY="$ROOT/policies/branch-protection.json"
REPO_RULES="$ROOT/policies/repo-rules.json"

API="https://api.github.com"
AUTH_HEADER="Authorization: Bearer $GH_TOKEN"
ACCEPT_HEADER="Accept: application/vnd.github+json"
API_VERSION_HEADER="X-GitHub-Api-Version: 2022-11-28"

echo "==> Applying branch rules to $REPO"

# ── Apply branch protection for each branch ──────────────────────────────────
branch_count=$(python3 -c "import json; d=json.load(open('$BRANCH_POLICY')); print(len(d['branches']))")

for i in $(seq 0 $((branch_count - 1))); do
  BRANCH=$(python3 -c "import json; d=json.load(open('$BRANCH_POLICY')); print(d['branches'][$i]['name'])")
  PROTECTION=$(python3 -c "import json; d=json.load(open('$BRANCH_POLICY')); print(json.dumps(d['branches'][$i]['protection']))")

  echo "    Setting branch protection: $BRANCH"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$API/repos/$REPO/branches/$BRANCH/protection" \
    -H "$AUTH_HEADER" \
    -H "$ACCEPT_HEADER" \
    -H "$API_VERSION_HEADER" \
    -H "Content-Type: application/json" \
    -d "$PROTECTION")

  if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo "    OK ($HTTP_CODE): branch protection set for $BRANCH"
  elif [ "$HTTP_CODE" -eq 404 ]; then
    echo "    SKIP ($HTTP_CODE): branch '$BRANCH' does not exist yet in $REPO — will apply on next run"
  else
    echo "    ERROR ($HTTP_CODE): failed to set branch protection for $BRANCH"
    exit 1
  fi
done

# ── Apply org-level repository ruleset ───────────────────────────────────────
ORG=$(echo "$REPO" | cut -d'/' -f1)
RULESET_NAME=$(python3 -c "import json; d=json.load(open('$REPO_RULES')); print(d['ruleset']['name'])")
RULESET_PAYLOAD=$(python3 -c "import json; d=json.load(open('$REPO_RULES')); print(json.dumps(d['ruleset']))")

echo "    Upserting org ruleset: $RULESET_NAME"

# Check if ruleset already exists
EXISTING_ID=$(curl -s \
  "$API/orgs/$ORG/rulesets" \
  -H "$AUTH_HEADER" \
  -H "$ACCEPT_HEADER" \
  -H "$API_VERSION_HEADER" \
  | python3 -c "import json,sys; rs=json.load(sys.stdin); ids=[r['id'] for r in rs if r['name']=='$RULESET_NAME']; print(ids[0] if ids else '')" 2>/dev/null || echo "")

if [ -n "$EXISTING_ID" ]; then
  # Update existing ruleset
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "$API/orgs/$ORG/rulesets/$EXISTING_ID" \
    -H "$AUTH_HEADER" \
    -H "$ACCEPT_HEADER" \
    -H "$API_VERSION_HEADER" \
    -H "Content-Type: application/json" \
    -d "$RULESET_PAYLOAD")
  echo "    Ruleset updated (id=$EXISTING_ID, HTTP $HTTP_CODE)"
else
  # Create new ruleset
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$API/orgs/$ORG/rulesets" \
    -H "$AUTH_HEADER" \
    -H "$ACCEPT_HEADER" \
    -H "$API_VERSION_HEADER" \
    -H "Content-Type: application/json" \
    -d "$RULESET_PAYLOAD")
  echo "    Ruleset created (HTTP $HTTP_CODE)"
fi

echo "==> Branch rules applied: $REPO"
