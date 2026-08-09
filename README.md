<p align="center">
  <img src="logo.svg" alt="musescore-backup" width="540">
</p>

Auto-commits `.mscz` changes to a private GitHub repo via fswatch + launchd. Watches multiple directories, debounces 5s, then `git commit && git push`. Starts on login — no terminal required.

## Setup

```bash
./setup.sh            # install deps, init git repo, create GitHub repo
./install-launchd.sh  # install persistent watcher (auto-starts on login)
./install-autoupdate.sh  # optional: daily 3am pull + restart
```

Requires `gh auth login` first.

## Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | One-time setup |
| `watch.sh` | Watcher daemon |
| `install-launchd.sh` | Install watcher as launchd agent |
| `install-autoupdate.sh` | Install daily auto-updater (3am) |
| `update.sh` | Pull latest + reload watcher |
| `trigger.sh` | Manual full backup cycle |
| `refresh-readme.sh` | Regenerate scores repo README |

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `SCORES_DIRS` | `~/Documents/MuseScore4/Scores ~/Desktop ~/Downloads` | Space-separated dirs to watch |
| `GIT_DIR` | `/Users/jay` | Git repo root |
| `EXCLUDE_PATTERN` | `Library/CloudStorage` | Paths to ignore (regex) |
| `REPO_NAME` | `musescore-scores` | GitHub repo name (setup only) |
| `BRANCH` | `main` | Git branch |
| `DEBOUNCE` | `5` | Seconds after last change before commit |

## Logs

```
~/Library/Logs/musescore-backup.log
~/Library/Logs/musescore-backup-error.log
~/Library/Logs/musescore-backup-update.log
```

## Launchd

```bash
launchctl list | grep musescore                                    # status
launchctl unload ~/Library/LaunchAgents/com.user.musescore-backup.plist   # stop
launchctl load  ~/Library/LaunchAgents/com.user.musescore-backup.plist    # start
```
