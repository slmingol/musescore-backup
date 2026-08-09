#!/usr/bin/env bash
# Watch MuseScore scores dirs and commit+push any .mscz changes to GitHub

set -euo pipefail

SCORES_DIRS="${SCORES_DIRS:-$HOME/Documents/MuseScore4/Scores $HOME/Desktop $HOME/Downloads}"
GIT_DIR="${GIT_DIR:-/Users/jay}"
BRANCH="${BRANCH:-main}"
DEBOUNCE="${DEBOUNCE:-5}"  # seconds to wait after last change before committing
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-Library/CloudStorage}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

if [[ ! -d "$GIT_DIR/.git" ]]; then
  log "ERROR: $GIT_DIR is not a git repo. Run setup.sh first."
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

update_readme() {
  local dir="$1"
  cd "$dir"

  local count updated rows
  count=$(git ls-files -- '*.mscz' | wc -l | tr -d ' ')
  updated=$(date '+%Y-%m-%d %H:%M')
  rows=""

  while IFS=$'\t' read -r date path; do
    local name folder url_path url_folder size szfmt
    name=$(basename "$path")
    folder=$(dirname "$path")
    [[ "$folder" == "." ]] && folder=""
    url_path="${path// /%20}"

    if [[ -z "$folder" ]]; then
      rows+="| [${name}](${url_path}) | _(root)_ | \`${date}\` |"$'\n'
    else
      url_folder="${folder// /%20}"
      rows+="| [${name}](${url_path}) | [${folder}/](${url_folder}/) | \`${date}\` |"$'\n'
    fi
  done < <({ git ls-files -- '*.mscz' | grep '/' | sort; git ls-files -- '*.mscz' | grep -v '/' | sort; } | while IFS= read -r f; do
    date=$(git log -1 --format="%ad" --date=format:'%Y-%m-%d %H:%M' -- "$f")
    printf '%s\t%s\n' "$date" "$f"
  done)

  {
    echo "# musescore-scores"
    echo ""
    echo "Auto-backup of MuseScore 4 scores (${count} files). Committed automatically by [musescore-backup](https://github.com/slmingol/musescore-backup) via fswatch + launchd."
    echo ""
    echo "*Last updated: ${updated}*"
    echo ""
    echo "| 🎵 Score | 📁 Folder | 📅 Committed |"
    echo "|---------|---------|-------------|"
    printf '%s' "$rows"
  } > README.md

  if [[ -n "$(git status --porcelain README.md)" ]]; then
    git add -- README.md
    git commit -m "readme: ${count} files"
    git push origin "$BRANCH"
    log "Updated README (${count} files)"
  fi
}

read -ra watch_dirs <<< "$SCORES_DIRS"

log "Watching: ${watch_dirs[*]} (branch: $BRANCH, excluding: $EXCLUDE_PATTERN)..."

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
  "${watch_dirs[@]}" | while IFS= read -r changed_path; do
    log "Change detected: $(basename "$changed_path")"
    commit_changes "$GIT_DIR" || log "ERROR: commit/push failed"
    update_readme "$GIT_DIR" || log "ERROR: readme update failed"
  done
