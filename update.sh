#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST="$HOME/Library/LaunchAgents/com.user.musescore-backup.plist"

cd "$SCRIPT_DIR"
git pull
launchctl unload "$PLIST" 2>/dev/null || true
./install-launchd.sh
