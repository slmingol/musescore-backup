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
      if (d == "(root)") { printf "| _(root)_ | %d |\n", counts[d] }
      else { url=d; gsub(/ /, "%20", url); printf "| [%s/](%s/) | %d |\n", d, url, counts[d] }
    }
  }
')

recent=$(git log --name-only --format="%ad" --date=format:'%Y-%m-%d %H:%M' -- '*.mscz' | awk '
  /^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$/ { date=$0; next }
  /\.mscz$/ { if (!seen[$0]++) { n++; dates[n]=date; files[n]=$0 } }
  END {
    print "| File | Committed |"
    print "|------|-----------|"
    for (i=1; i<=n && i<=10; i++) {
      path=files[i]; url=path; gsub(/ /, "%20", url)
      split(path, a, "/"); name=a[length(a)]
      printf "| [%s](%s) | %s |\n", name, url, dates[i]
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
  echo "## Recent"
  echo ""
  echo "${recent}"
  echo ""
  echo "## By folder"
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
