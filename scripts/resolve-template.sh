#!/usr/bin/env bash
# resolve-template.sh
# Usage: ./resolve-template.sh '<language>' '<description>'
# Outputs the correct CLAUDE template filename.
# Description keyword matching takes priority over language.
#
# Examples:
#   ./resolve-template.sh 'C#' 'client portal dotnet react'  → CLAUDE-dotnet.md
#   ./resolve-template.sh '' 'flutter mobile app'            → CLAUDE-flutter.md
#   ./resolve-template.sh 'Python' ''                        → CLAUDE-python.md

set -euo pipefail

LANG="${1:-}"
DESC="${2:-}"

# Combine description + language; description is listed first so it takes priority
# in left-to-right matching (all patterns are checked in order regardless)
INPUT=$(echo "$DESC $LANG" | tr '[:upper:]' '[:lower:]')

if echo "$INPUT" | grep -qiE 'dotnet|\.net|csharp|c#'; then
  echo "CLAUDE-dotnet.md"
elif echo "$INPUT" | grep -qiE 'python|django|fastapi|flask|sqlalchemy|celery'; then
  echo "CLAUDE-python.md"
elif echo "$INPUT" | grep -qiE 'flutter|dart|riverpod|bloc|getx'; then
  echo "CLAUDE-flutter.md"
elif echo "$INPUT" | grep -qiE '\bjava\b|kotlin|spring|quarkus|gradle|maven'; then
  echo "CLAUDE-java.md"
elif echo "$INPUT" | grep -qiE '\bgo\b|golang|\bgin\b|\becho\b|\bfiber\b|gorm'; then
  echo "CLAUDE-go.md"
elif echo "$INPUT" | grep -qiE 'node|nodejs|typescript|express|nestjs|prisma'; then
  echo "CLAUDE-node.md"
else
  echo "CLAUDE-default.md"
fi
