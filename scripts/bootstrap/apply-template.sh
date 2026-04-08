#!/usr/bin/env bash
# apply-template.sh
# Usage: ./apply-template.sh 'org/repo' 'CLAUDE-dotnet.md' '<gh_token>'
#
# Clones the target repo, copies workflow files and templates, commits, and pushes.
# - Always overwrites all 4 productivity/security workflow files
# - Always copies enterprise workflow templates (CI, dependency-review, stale, release-drafter)
# - Only copies CLAUDE.md if not already present (allows teams to customise it)
# - Only copies .claudeignore if not already present
# - Only copies PR template if not already present
# - Commits with: chore: provision enterprise workflows [<label>]
# - Applies branch protection, repo rules, and enforces settings after push

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

# Core productivity + security workflows (always overwrite)
for WF in pr-summary.yml claude-review.yml security-scan.yml release-notes.yml; do
  SRC="$ROOT/workflows/productivity/$WF"
  # Fallback: legacy flat location
  [ -f "$SRC" ] || SRC="$ROOT/workflow-templates/$WF"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$TARGET_DIR/.github/workflows/$WF"
    echo "    Copied workflow: $WF"
  else
    echo "    WARNING: $SRC not found — skipping"
  fi
done

# Enterprise CI/quality workflow templates (always overwrite)
for WF in ci-build-test.yml ci-lint.yml dependency-review.yml \
           code-coverage.yml stale-issues.yml release-drafter.yml; do
  # Try dev/ then quality/ then business/ subdirectory
  SRC=""
  for DIR in dev quality business; do
    CANDIDATE="$ROOT/workflow-templates/$DIR/$WF"
    if [ -f "$CANDIDATE" ]; then
      SRC="$CANDIDATE"
      break
    fi
  done
  if [ -f "$SRC" ]; then
    cp "$SRC" "$TARGET_DIR/.github/workflows/$WF"
    echo "    Copied enterprise workflow: $WF"
  else
    echo "    WARNING: enterprise workflow $WF not found — skipping"
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

# ── PR template (only if missing) ────────────────────────────────────────────
PR_TEMPLATE_SRC="$ROOT/PULL_REQUEST_TEMPLATE/pull_request_template.md"
PR_TEMPLATE_DEST="$TARGET_DIR/.github/PULL_REQUEST_TEMPLATE/pull_request_template.md"
if [ ! -f "$PR_TEMPLATE_DEST" ]; then
  mkdir -p "$(dirname "$PR_TEMPLATE_DEST")"
  cp "$PR_TEMPLATE_SRC" "$PR_TEMPLATE_DEST"
  echo "    Copied PR template"
else
  echo "    PR template already exists — skipping"
fi

# ── Commit and push ──────────────────────────────────────────────────────────
cd "$TARGET_DIR"
git config user.email "github-actions[bot]@users.noreply.github.com"
git config user.name "github-actions[bot]"
git add -A

if git diff --cached --quiet; then
  echo "    No changes to commit for $REPO — already up to date"
else
  git commit -m "chore: provision enterprise workflows [$LABEL]"
  git push
  echo "    Pushed changes to $REPO"

  # Allow GitHub to register the new commits before applying rules
  sleep 5

  # Apply branch protection rules
  if [ -f "$ROOT/scripts/governance/apply-branch-rules.sh" ]; then
    bash "$ROOT/scripts/governance/apply-branch-rules.sh" "$REPO" "$GH_TOKEN" \
      || echo "    WARNING: Branch rules setup failed — will retry on next run"
  fi

  # Enforce repository settings (merge strategy, security features, etc.)
  if [ -f "$ROOT/scripts/governance/enforce-settings.sh" ]; then
    bash "$ROOT/scripts/governance/enforce-settings.sh" "$REPO" "$GH_TOKEN" \
      || echo "    WARNING: Settings enforcement failed — will retry on next run"
  fi
fi

# ── Cleanup ──────────────────────────────────────────────────────────────────
rm -rf "$TMP_DIR"
echo "==> Done: $REPO"
