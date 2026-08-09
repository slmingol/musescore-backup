# MuseScore GitHub Backup

Auto-commits `.mscz` changes to a private GitHub repo using `fswatch` + launchd.

## What it does

- Watches `~/Documents/MuseScore4/Scores` for `.mscz` file changes in real time
- Debounces 5s after last change (waits for MuseScore to finish writing)
- Commits with message like `update: MySong.mscz` and pushes to GitHub
- Runs persistently via launchd, auto-starts on login

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | One-time setup: installs deps, inits git, creates GitHub repo |
| `watch.sh` | The watcher daemon |
| `install-launchd.sh` | Installs watcher as a launchd agent |

## First-time setup

```bash
# 1. Run setup (installs fswatch + gh if missing, creates GitHub repo)
./setup.sh

# 2. Install persistent background daemon
./install-launchd.sh
```

Requires `gh auth login` if not already authenticated with GitHub CLI.

## Custom scores path

```bash
SCORES_DIR=/path/to/scores ./setup.sh
SCORES_DIR=/path/to/scores ./install-launchd.sh
```

## Logs

```
~/Library/Logs/musescore-backup.log
~/Library/Logs/musescore-backup-error.log
```

## launchd management

```bash
# Stop
launchctl unload ~/Library/LaunchAgents/com.user.musescore-backup.plist

# Restart
launchctl unload ~/Library/LaunchAgents/com.user.musescore-backup.plist
launchctl load ~/Library/LaunchAgents/com.user.musescore-backup.plist

# Check status
launchctl list | grep musescore
```

## Defaults

| Setting | Default | Override |
|---------|---------|----------|
| Scores dir | `~/Documents/MuseScore4/Scores` | `SCORES_DIR=...` |
| GitHub repo name | `musescore-scores` | `REPO_NAME=...` |
| Branch | `main` | `BRANCH=...` |
| Debounce | `5` seconds | `DEBOUNCE=...` |
