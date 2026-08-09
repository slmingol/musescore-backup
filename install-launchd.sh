#!/usr/bin/env bash
# Install launchd agent so watch.sh runs automatically on login

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCH_SCRIPT="$SCRIPT_DIR/watch.sh"
SCORES_DIR="${SCORES_DIR:-/Users/jay}"
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:-Library/CloudStorage}"
LABEL="com.user.musescore-backup"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOG_DIR="$HOME/Library/Logs"

chmod +x "$WATCH_SCRIPT"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>

  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${WATCH_SCRIPT}</string>
  </array>

  <key>EnvironmentVariables</key>
  <dict>
    <key>SCORES_DIR</key>
    <string>${SCORES_DIR}</string>
    <key>EXCLUDE_PATTERN</key>
    <string>${EXCLUDE_PATTERN}</string>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    <key>HOME</key>
    <string>${HOME}</string>
  </dict>

  <key>RunAtLoad</key>
  <true/>

  <key>KeepAlive</key>
  <true/>

  <key>StandardOutPath</key>
  <string>${LOG_DIR}/musescore-backup.log</string>

  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/musescore-backup-error.log</string>
</dict>
</plist>
EOF

# Unload if already loaded (ignore error if not)
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "Launchd agent installed and started."
echo "Plist: $PLIST"
echo "Logs:  $LOG_DIR/musescore-backup.log"
echo "       $LOG_DIR/musescore-backup-error.log"
echo ""
echo "To stop:    launchctl unload $PLIST"
echo "To restart: launchctl unload $PLIST && launchctl load $PLIST"
echo "To check:   launchctl list | grep musescore"
