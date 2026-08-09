#!/usr/bin/env bash
# Watch MuseScore scores dirs and commit+push any .mscz changes to GitHub

set -euo pipefail

SCORES_DIRS="${SCORES_DIRS:-$HOME/Documents/MuseScore4/Scores|$HOME/Desktop|$HOME/Downloads|$HOME/Desktop/FE:PIT EXERCISES|$HOME/Library/Application Support/MuseScore*}"
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

_sorted_mscz() {
  # Folder files: sort by (top-level dir, full dirname, basename) then root files
  { git ls-files -- '*.mscz' | grep '/' | while IFS= read -r f; do
      printf '%s\t%s\t%s\t%s\n' \
        "$(printf '%s' "$f" | cut -d/ -f1)" "$(dirname "$f")" "$(basename "$f")" "$f"
    done | sort -t$'\t' -k1,1 -k2,2 -k3,3 | awk -F'\t' '{print $NF}'
    git ls-files -- '*.mscz' | grep -v '/' | sort
  }
}

update_readme() {
  local dir="$1"
  cd "$dir"

  local count updated tmpdata row_h header_h width height
  count=$(git ls-files -- '*.mscz' | wc -l | tr -d ' ')
  updated=$(date '+%Y-%m-%d %H:%M')
  tmpdata=$(mktemp)
  row_h=26; header_h=40; width=700

  _sorted_mscz | while IFS= read -r f; do
    local d n fld
    d=$(git log -1 --format="%ad" --date=format:'%Y-%m-%d %H:%M' -- "$f")
    n=$(basename "$f"); fld=$(dirname "$f"); [[ "$fld" == "." ]] && fld=""
    printf '%s\t%s\t%s\n' "$n" "$fld" "$d"
  done > "$tmpdata"

  height=$(( header_h + count * row_h + 16 ))

  {
    printf '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">\n' "$width" "$height" "$width" "$height"
    printf '<rect width="%d" height="%d" fill="#0D1117"/>\n' "$width" "$height"
    printf '<rect width="%d" height="%d" fill="#161B22"/>\n' "$width" "$header_h"
    printf '<rect y="32" width="%d" height="8" fill="#161B22"/>\n' "$width"
    printf '<text x="16" y="25" font-family="SF Mono,Consolas,monospace" font-size="11" font-weight="700" fill="#4A9EFF" letter-spacing="0.8">SCORE</text>\n'
    printf '<text x="300" y="25" font-family="SF Mono,Consolas,monospace" font-size="11" font-weight="700" fill="#3FB950" letter-spacing="0.8">FOLDER</text>\n'
    printf '<text x="524" y="25" font-family="SF Mono,Consolas,monospace" font-size="11" font-weight="700" fill="#8B949E" letter-spacing="0.8">COMMITTED</text>\n'
    printf '<line x1="0" y1="%d" x2="%d" y2="%d" stroke="#2A3A52" stroke-width="1"/>\n' "$header_h" "$width" "$header_h"
    printf '<line x1="292" y1="0" x2="292" y2="%d" stroke="#1E2A3D" stroke-width="1"/>\n' "$height"
    printf '<line x1="520" y1="0" x2="520" y2="%d" stroke="#1E2A3D" stroke-width="1"/>\n' "$height"

    local i=0
    while IFS=$'\t' read -r name folder date; do
      local ry ty sn sf
      ry=$(( header_h + i * row_h )); ty=$(( ry + 17 ))
      (( i % 2 == 1 )) && printf '<rect x="0" y="%d" width="%d" height="%d" fill="#0F1923"/>\n' "$ry" "$width" "$row_h"
      sn="${name//&/&amp;}"; sn="${sn//</&lt;}"; sn="${sn//>/&gt;}"
      sf="${folder//&/&amp;}"; sf="${sf//</&lt;}"; sf="${sf//>/&gt;}"
      [[ ${#sn} -gt 38 ]] && sn="${sn:0:35}..."
      [[ -z "$sf" ]] && sf="--" || { [[ ${#sf} -gt 28 ]] && sf="${sf:0:25}..."; }
      printf '<text x="16" y="%d" font-family="SF Mono,Consolas,monospace" font-size="11" fill="#58A6FF">%s</text>\n' "$ty" "$sn"
      printf '<text x="300" y="%d" font-family="SF Mono,Consolas,monospace" font-size="11" fill="#3FB950">%s</text>\n' "$ty" "$sf"
      printf '<text x="524" y="%d" font-family="SF Mono,Consolas,monospace" font-size="11" fill="#6E7681">%s</text>\n' "$ty" "$date"
      i=$((i+1))
    done < "$tmpdata"

    local fy=$(( height - 4 ))
    printf '<line x1="0" y1="%d" x2="%d" y2="%d" stroke="#1E2A3D" stroke-width="1"/>\n' "$((height-16))" "$width" "$((height-16))"
    printf '<text x="%d" y="%d" font-family="SF Mono,Consolas,monospace" font-size="10" fill="#484F58" text-anchor="end">%d files · updated %s</text>\n' "$((width-12))" "$fy" "$count" "$updated"
    printf '</svg>\n'
  } > inventory.svg

  # Build clickable links for <details> section
  local links=""
  links+="| Score | Folder | Committed |"$'\n'
  links+="|-------|--------|-----------|"$'\n'
  while IFS=$'\t' read -r name folder date; do
    local url_path url_folder
    url_path="${folder:+${folder}/}${name}"; url_path="${url_path// /%20}"
    if [[ -z "$folder" ]]; then
      links+="| [${name}](${url_path}) | -- | \`${date}\` |"$'\n'
    else
      url_folder="${folder// /%20}"
      links+="| [${name}](${url_path}) | [${folder}/](${url_folder}/) | \`${date}\` |"$'\n'
    fi
  done < "$tmpdata"

  rm -f "$tmpdata"

  # Build watched locations table
  local loc_table=""
  loc_table+="| Path | Depth |"$'\n'
  loc_table+="|------|-------|"$'\n'
  loc_table+="| \`${GIT_DIR}/\` | top-level only |"$'\n'
  for _wd in "${watch_dirs[@]}"; do
    loc_table+="| \`${_wd}\` | recursive |"$'\n'
  done

  {
    echo "# musescore-scores"
    echo ""
    echo "Private backup of MuseScore 4 scores, auto-committed by [musescore-backup](https://github.com/slmingol/musescore-backup) via fswatch + launchd. Each \`.mscz\` save triggers a commit within 5 seconds."
    echo ""
    echo "## Watched Locations"
    echo ""
    echo "Files are committed automatically when saved in any of these locations."
    echo "Moving a file outside these paths will appear as a deletion."
    echo ""
    printf '%s' "$loc_table"
    echo ""
    echo "## Inventory"
    echo ""
    echo "![inventory](inventory.svg)"
    echo ""
    echo "<details>"
    echo "<summary>Browse all files</summary>"
    echo ""
    printf '%s' "$links"
    echo ""
    echo "</details>"
  } > README.md

  if [[ -n "$(git status --porcelain README.md inventory.svg)" ]]; then
    git add -- README.md inventory.svg
    git commit -m "readme: ${count} files"
    git push origin "$BRANCH"
    log "Updated README (${count} files)"
  fi
}

# Split on | and expand globs (handles spaces in paths, MuseScore* etc.)
IFS='|' read -ra _raw_dirs <<< "$SCORES_DIRS"
watch_dirs=()
for _raw in "${_raw_dirs[@]}"; do
  _raw="${_raw/#\~/$HOME}"
  while IFS= read -r _d; do
    [[ -d "$_d" ]] && watch_dirs+=("$_d")
  done < <(compgen -G "$_raw" 2>/dev/null || echo "$_raw")
done

log "Watching: ${watch_dirs[*]} (branch: $BRANCH, excluding: $EXCLUDE_PATTERN)..."

fswatch \
  --recursive \
  --extended \
  --event=Updated \
  --event=Created \
  --event=Removed \
  --event=Renamed \
  --latency="$DEBOUNCE" \
  "${watch_dirs[@]}" | grep -E '\.mscz$' | grep -v "$EXCLUDE_PATTERN" | while IFS= read -r changed_path; do
    log "Change detected: $(basename "$changed_path")"
    commit_changes "$GIT_DIR" || log "ERROR: commit/push failed"
    update_readme "$GIT_DIR" || log "ERROR: readme update failed"
  done
