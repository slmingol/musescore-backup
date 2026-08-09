#!/usr/bin/env bash
# Watch MuseScore scores dir and commit+push any .mscz changes to GitHub

set -euo pipefail

SCORES_DIR="${SCORES_DIR:-/Users/jay}"
BRANCH="${BRANCH:-main}"
DEBOUNCE="${DEBOUNCE:-5}"  # seconds to wait after last change before committing
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-Library/CloudStorage}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if [[ ! -d "$SCORES_DIR/.git" ]]; then
  log "ERROR: $SCORES_DIR is not a git repo. Run setup.sh first."
  exit 1
fi

if ! command -v fswatch &>/dev/null; then
  log "ERROR: fswatch not found. Run setup.sh first."
  exit 1
fi

commit_changes() {
  local dir="$1"
  cd "$dir"

  # Only act if there are .mscz changes
  if git diff --quiet -- '*.mscz' && git diff --cached --quiet -- '*.mscz' && [[ -z "$(git ls-files --others --exclude-standard -- '*.mscz')" ]]; then
    return
  fi

  # Get changed .mscz file names for commit message
  local changed
  changed=$(git status --porcelain -- '*.mscz' | awk '{print $2}' | xargs -I{} basename {} | tr '\n' ', ' | sed 's/,$//')

  # Stage only .mscz files (handles spaces in filenames)
  while IFS= read -r f; do
    [[ -n "$f" ]] && git add -- "$f"
  done < <(git status --porcelain -- '*.mscz' | awk '{print $2}')

  local msg="update: $changed"
  if [[ ${#msg} -gt 72 ]]; then
    msg="update: $(echo "$changed" | cut -c1-50)..."
  fi

  git commit -m "$msg"
  git push origin "$BRANCH"
  log "Pushed: $msg"
}

log "Watching $SCORES_DIR for changes (branch: $BRANCH)..."

# fswatch emits one line per changed file; we debounce with a timer
fswatch \
  --recursive \
  --include='\.mscz$' \
  --exclude="$EXCLUDE_PATTERN" \
  --extended \
  --event=Updated \
  --event=Created \
  --event=Removed \
  --event=Renamed \
  --latency="$DEBOUNCE" \
  "$SCORES_DIR" | while IFS= read -r changed_path; do
    log "Change detected: $(basename "$changed_path")"
    commit_changes "$SCORES_DIR" || log "ERROR: commit/push failed"
  done
