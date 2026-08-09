#!/usr/bin/env bash
# One-time setup: install deps, init git repo in scores dir, create GitHub repo

set -euo pipefail

SCORES_DIR="${SCORES_DIR:-/Users/jay}"
REPO_NAME="${REPO_NAME:-musescore-scores}"
BRANCH="${BRANCH:-main}"

if [[ ! -d "$SCORES_DIR" ]]; then
  echo "Scores dir not found: $SCORES_DIR"
  echo "Set SCORES_DIR env var and retry."
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

cd "$SCORES_DIR"

# Init git if not already
if [[ ! -d .git ]]; then
  git init -b "$BRANCH"
  echo "Initialized git in $SCORES_DIR"
fi

# Add .gitignore for non-score files
if [[ ! -f .gitignore ]]; then
  cat > .gitignore <<'EOF'
.DS_Store
*.tmp
*.lock
EOF
fi

# Initial commit if no commits yet
if ! git rev-parse HEAD &>/dev/null 2>&1; then
  git add -A
  git commit -m "Initial commit: existing scores"
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
echo "Scores dir: $SCORES_DIR"
echo "GitHub repo: $(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo $REPO_NAME)"
echo ""
echo "Next: install the background watcher with:"
echo "  ./install-launchd.sh"
