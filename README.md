<p align="center">
  <img src="logo.svg" alt="musescore-backup" width="540">
</p>

Auto-commits `.mscz` changes to a private GitHub repo. Watches one or more directories for `.mscz` file changes, debounces 5 seconds after the last write, then `git commit && git push`. Runs as a launchd agent — starts automatically on login, no terminal required.

## Requirements

- macOS
- [Homebrew](https://brew.sh)
- GitHub CLI — `brew install gh && gh auth login`

## Setup

```bash
# 1. Install deps, init git repo in scores dir, create private GitHub repo
./setup.sh

# 2. Install as a persistent launchd agent (auto-starts on login)
./install-launchd.sh
```

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | One-time setup: deps, git init, GitHub repo creation |
| `watch.sh` | Watcher daemon (fswatch → debounce → git commit + push + readme update) |
| `install-launchd.sh` | Registers `watch.sh` as a persistent launchd agent |
| `install-autoupdate.sh` | Registers a daily 3am launchd timer to pull updates and restart the watcher |
| `update.sh` | Pull latest, reload watcher — run manually or via autoupdate timer |

## Configuration

All settings are environment variables with sensible defaults.

| Variable | Default | Description |
|----------|---------|-------------|
| `SCORES_DIRS` | `~/Documents/MuseScore4/Scores ~/Desktop ~/Downloads` | Space-separated list of dirs to watch |
| `GIT_DIR` | `/Users/jay` | Root dir where the git repo lives (must contain all watched dirs) |
| `EXCLUDE_PATTERN` | `Library/CloudStorage` | Regex pattern — matching paths are ignored by fswatch |
| `REPO_NAME` | `musescore-scores` | GitHub repo name to create (setup.sh only) |
| `BRANCH` | `main` | Git branch |
| `DEBOUNCE` | `5` | Seconds to wait after last file change |

Override at runtime:

```bash
SCORES_DIRS="~/Music/Scores ~/Desktop" GIT_DIR=/Users/jay ./setup.sh
SCORES_DIRS="~/Music/Scores ~/Desktop" GIT_DIR=/Users/jay ./install-launchd.sh
```

## Logs

```
~/Library/Logs/musescore-backup.log
~/Library/Logs/musescore-backup-error.log
```

## Launchd management

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.user.musescore-backup.plist

# Restart
launchctl unload ~/Library/LaunchAgents/com.user.musescore-backup.plist
launchctl load ~/Library/LaunchAgents/com.user.musescore-backup.plist

# Status
launchctl list | grep musescore
```
