#!/usr/bin/env bash
# One-time setup: install deps, init git repo, create GitHub repo

set -euo pipefail

GIT_DIR="${GIT_DIR:-/Users/jay}"
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-Library/CloudStorage}"
REPO_NAME="${REPO_NAME:-musescore-scores}"
BRANCH="${BRANCH:-main}"

if [[ ! -d "$GIT_DIR" ]]; then
  echo "Git dir not found: $GIT_DIR"
  echo "Set GIT_DIR env var and retry."
  exit 1
fi

# Install fswatch if missing
if ! command -v fswatch &>/dev/null; then
  echo "Installing fswatch..."
  brew install fswatch
fi

# Install gh if missing (needed to create GitHub repo)
if ! command -v gh &>/dev/null; then
  echo "Installing gh CLI..."
  brew install gh
fi

# Verify gh auth
if ! gh auth status &>/dev/null; then
  echo "Not logged in to GitHub CLI. Run: gh auth login"
  exit 1
fi

cd "$GIT_DIR"

# Init git if not already
if [[ ! -d .git ]]; then
  git init -b "$BRANCH"
  echo "Initialized git in $GIT_DIR"
fi

# Add .gitignore for non-score files
if [[ ! -f .gitignore ]]; then
  cat > .gitignore <<'EOF'
.DS_Store
*.tmp
*.lock
EOF
fi

# Initial commit of existing .mscz files if no commits yet
if ! git rev-parse HEAD &>/dev/null 2>&1; then
  while IFS= read -r -d '' f; do
    git add -- "$f"
  done < <(find . -name "*.mscz" ! -path "*/$EXCLUDE_PATTERN/*" -print0)
  git commit -m "Initial commit: existing scores" || echo "No .mscz files found, skipping initial commit."
fi

# Create GitHub repo and push if no remote
if ! git remote get-url origin &>/dev/null; then
  gh repo create "$REPO_NAME" --private --source=. --remote=origin --push
  echo "Created GitHub repo: $REPO_NAME"
else
  git push -u origin "$BRANCH"
fi

echo ""
echo "Setup complete."
echo "Git dir:     $GIT_DIR"
echo "GitHub repo: $(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo $REPO_NAME)"
echo ""
echo "Next: install the background watcher with:"
echo "  ./install-launchd.sh"
