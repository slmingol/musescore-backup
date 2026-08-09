#!/usr/bin/env bash
# Manually regenerate and push the README in the musescore-scores repo

set -euo pipefail

GIT_DIR="${GIT_DIR:-/Users/jay}"
BRANCH="${BRANCH:-main}"

cd "$GIT_DIR"

count=$(git ls-files -- '*.mscz' | wc -l | tr -d ' ')
updated=$(date '+%Y-%m-%d %H:%M')
rows=""

while IFS=$'\t' read -r date path; do
  name=$(basename "$path")
  folder=$(dirname "$path")
  [[ "$folder" == "." ]] && folder=""
  url_path="${path// /%20}"

  if [[ -f "$path" ]]; then
    size=$(stat -f %z "$path")
    if   (( size >= 1048576 )); then szfmt="$(( size/1048576 )) MB"
    elif (( size >= 1024 ));    then szfmt="$(( size/1024 )) KB"
    else                             szfmt="${size} B"
    fi
  else
    szfmt="—"
  fi

  if [[ -z "$folder" ]]; then
    rows+="| [${name}](${url_path}) | _(root)_ | ${szfmt} | \`${date}\` |"$'\n'
  else
    url_folder="${folder// /%20}"
    rows+="| [${name}](${url_path}) | [${folder}/](${url_folder}/) | ${szfmt} | \`${date}\` |"$'\n'
  fi
done < <(git log --name-only --format="%ad" --date=format:'%Y-%m-%d %H:%M' -- '*.mscz' | awk '
  /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$/ { date=$0; next }
  /\.mscz$/ { if (!seen[$0]++) print date "\t" $0 }
')

{
  echo "# musescore-scores"
  echo ""
  echo "Auto-backup of MuseScore 4 scores (${count} files). Committed automatically by [musescore-backup](https://github.com/slmingol/musescore-backup) via fswatch + launchd."
  echo ""
  echo "*Last updated: ${updated}*"
  echo ""
  echo "| 🎵 Score | 📁 Folder | 💾 Size | 📅 Committed |"
  echo "|---------|---------|--------|-------------|"
  printf '%s' "$rows"
} > README.md

if [[ -n "$(git status --porcelain README.md)" ]]; then
  git add -- README.md
  git commit -m "readme: ${count} files"
  git push origin "$BRANCH"
  echo "README updated (${count} files)."
else
  echo "README already up to date."
fi
