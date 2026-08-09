#!/usr/bin/env bash
set -euo pipefail
git pull && launchctl unload ~/Library/LaunchAgents/com.user.musescore-backup.plist 2>/dev/null || true && ./install-launchd.sh
