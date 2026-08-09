<p align="center">
  <img src="logo.svg" alt="musescore-backup" width="540">
</p>

Auto-commits `.mscz` changes to a private GitHub repo. Watches your MuseScore scores directory, debounces 5 seconds after the last write, then `git commit && git push`. Runs as a launchd agent — starts automatically on login, no terminal required.

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
| `watch.sh` | Watcher daemon (fswatch → debounce → git commit + push) |
| `install-launchd.sh` | Registers `watch.sh` as a launchd agent |

## Configuration

All settings are environment variables with sensible defaults.

| Variable | Default | Description |
|----------|---------|-------------|
| `SCORES_DIR` | `~/Documents/MuseScore4/Scores` | Scores directory to watch |
| `REPO_NAME` | `musescore-scores` | GitHub repo name to create |
| `BRANCH` | `main` | Git branch |
| `DEBOUNCE` | `5` | Seconds to wait after last file change |

Override at runtime:

```bash
SCORES_DIR=/path/to/scores ./setup.sh
SCORES_DIR=/path/to/scores ./install-launchd.sh
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
