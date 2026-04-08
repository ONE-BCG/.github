#!/usr/bin/env bash
# apply-template.sh
# Usage: ./apply-template.sh 'org/repo' 'CLAUDE-dotnet.md' '<gh_token>'
#
# Clones the target repo, copies workflow files and templates, commits, and pushes.
# - Always overwrites all 4 workflow files (pr-summary, claude-review, security-scan, release-notes)
# - Only copies CLAUDE.md if not already present (allows teams to customise it)
# - Only copies .claudeignore if not already present
# - Commits with: chore: add Claude Code workflows [<label>]
# - Applies branch protection after push

set -euo pipefail

REPO="$1"
TEMPLATE_FILE="$2"
GH_TOKEN="$3"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Derive a short label from the template filename (e.g. CLAUDE-dotnet.md → dotnet)
LABEL="${TEMPLATE_FILE%.md}"
LABEL="${LABEL#CLAUDE-}"

TMP_DIR=$(mktemp -d)
TARGET_DIR="$TMP_DIR/target_repo"

echo "==> Provisioning $REPO"
echo "    Template : $TEMPLATE_FILE (label: $LABEL)"

# Clone with token auth
git clone "https://x-access-token:${GH_TOKEN}@github.com/${REPO}.git" "$TARGET_DIR"

# ── Workflow files (always overwrite) ────────────────────────────────────────
mkdir -p "$TARGET_DIR/.github/workflows"
for WF in pr-summary.yml claude-review.yml security-scan.yml release-notes.yml; do
  SRC="$ROOT/workflow-templates/$WF"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$TARGET_DIR/.github/workflows/$WF"
    echo "    Copied workflow: $WF"
  else
    echo "    WARNING: $SRC not found — skipping"
  fi
done

# ── CLAUDE.md (only if not already customised) ───────────────────────────────
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
  cp "$ROOT/repo-templates/$TEMPLATE_FILE" "$TARGET_DIR/CLAUDE.md"
  echo "    Copied CLAUDE.md from $TEMPLATE_FILE"
else
  echo "    CLAUDE.md already exists — skipping (team may have customised it)"
fi

# ── .claudeignore (only if missing) ─────────────────────────────────────────
if [ ! -f "$TARGET_DIR/.claudeignore" ]; then
  cp "$ROOT/repo-templates/.claudeignore" "$TARGET_DIR/.claudeignore"
  echo "    Copied .claudeignore"
else
  echo "    .claudeignore already exists — skipping"
fi

# ── Commit and push ──────────────────────────────────────────────────────────
cd "$TARGET_DIR"
git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"
git add -A

if git diff --cached --quiet; then
  echo "    No changes to commit for $REPO — already up to date"
else
  git commit -m "chore: add Claude Code workflows [$LABEL]"
  git push
  echo "    Pushed changes to $REPO"

  # Apply branch protection (sleep to allow GitHub to register the new commits)
  sleep 5
  if [ -f "$ROOT/scripts/setup-branch-protection.sh" ]; then
    bash "$ROOT/scripts/setup-branch-protection.sh" "$REPO" "$GH_TOKEN" \
      || echo "    WARNING: Branch protection setup failed — will retry on next provisioner run"
  fi
fi

# ── Cleanup ──────────────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"
echo "==> Done: $REPO"
