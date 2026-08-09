#!/usr/bin/env bash
# Manually regenerate and push the README in the musescore-scores repo

set -euo pipefail

GIT_DIR="${GIT_DIR:-/Users/jay}"
BRANCH="${BRANCH:-main}"

cd "$GIT_DIR"

count=$(git ls-files -- '*.mscz' | wc -l | tr -d ' ')
updated=$(date '+%Y-%m-%d %H:%M')
listing=$(git ls-files -- '*.mscz' | sort | awk -F/ '
  {
    dir = (NF == 1) ? "(root)" : $1
    counts[dir]++
    if (!(dir in seen)) { seen[dir]=1; order[++n]=dir }
  }
  END {
    print "| Folder | Files |"
    print "|--------|------:|"
    for (i=1; i<=n; i++) {
      d = order[i]
      label = (d == "(root)") ? "_(root)_" : d "/"
      printf "| %s | %d |\n", label, counts[d]
    }
  }
')

{
  echo "# musescore-scores"
  echo ""
  echo "Auto-backup of MuseScore 4 scores (${count} files). Committed automatically by [musescore-backup](https://github.com/slmingol/musescore-backup) via fswatch + launchd."
  echo ""
  echo "*Last updated: ${updated}*"
  echo ""
  echo "## Scores"
  echo ""
  echo "${listing}"
} > README.md

if [[ -n "$(git status --porcelain README.md)" ]]; then
  git add -- README.md
  git commit -m "readme: ${count} files"
  git push origin "$BRANCH"
  echo "README updated (${count} files)."
else
  echo "README already up to date."
fi
