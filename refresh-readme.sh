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
  echo "README updated (${count} files)."
else
  echo "README already up to date."
fi
