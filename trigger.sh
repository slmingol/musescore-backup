#!/usr/bin/env bash
# Manually trigger a full backup cycle: commit all .mscz changes + update README

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCORES_DIRS="${SCORES_DIRS:-$HOME/Documents/MuseScore4/Scores|$HOME/Desktop|$HOME/Downloads|$HOME/Desktop/FE:PIT EXERCISES|$HOME/Library/Application Support/MuseScore*}"
GIT_DIR="${GIT_DIR:-/Users/jay}"
BRANCH="${BRANCH:-main}"
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-Library/CloudStorage}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

cd "$GIT_DIR"

# Expand SCORES_DIRS (| separated, glob aware) into search paths
IFS='|' read -ra _raw_dirs <<< "$SCORES_DIRS"
search_dirs=()
for _raw in "${_raw_dirs[@]}"; do
  _raw="${_raw/#\~/$HOME}"
  while IFS= read -r _d; do
    [[ -d "$_d" ]] && search_dirs+=("$_d")
  done < <(compgen -G "$_raw" 2>/dev/null || echo "$_raw")
done
log "Searching: ${search_dirs[*]}"

# Stage all .mscz files: depth-1 scan of GIT_DIR + recursive scan of SCORES_DIRS
while IFS= read -r -d '' f; do
  git add -- "$f"
done < <(
  find "$GIT_DIR" -maxdepth 1 -name "*.mscz" ! -path "*/$EXCLUDE_PATTERN/*" -print0
  find "${search_dirs[@]}" -name "*.mscz" ! -path "*/$EXCLUDE_PATTERN/*" -print0
)

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
