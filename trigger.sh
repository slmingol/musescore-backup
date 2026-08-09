#!/usr/bin/env bash
# Manually trigger a full backup cycle: commit all .mscz changes + update README

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_DIR="${GIT_DIR:-/Users/jay}"
BRANCH="${BRANCH:-main}"
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-Library/CloudStorage}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$GIT_DIR"

# Stage all .mscz changes (new, modified, deleted) excluding ignored paths
while IFS= read -r -d '' f; do
  git add -- "$f"
done < <(find . -name "*.mscz" ! -path "*/$EXCLUDE_PATTERN/*" -print0)

git add -u -- '*.mscz'  # stage deletions

if git diff --quiet --cached -- '*.mscz'; then
  log "No .mscz changes to commit."
else
  changed=$(git diff --cached --name-only -- '*.mscz' | xargs -I{} basename {} | tr '\n' ', ' | sed 's/,$//')
  git commit -m "update: $changed"
  git push origin "$BRANCH"
  log "Pushed: $changed"
fi

# Regenerate README
"$SCRIPT_DIR/refresh-readme.sh"
