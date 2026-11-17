# Lab 4: Scheduled backups

**Goal:** back up `/srv/finance` daily to `/backup`, keep 7 days, and prove restores work.

## Script

[`scripts/backup-finance.sh`](scripts/backup-finance.sh) → `/usr/local/bin/backup-finance.sh`

```bash
sudo chmod +x /usr/local/bin/backup-finance.sh
sudo /usr/local/bin/backup-finance.sh
ls -lh /backup
```

`tar: Removing leading '/' from member names` is expected: tar stores relative paths so a restore can't overwrite live files by accident.

## Schedule with cron

```bash
sudo crontab -e
```
```
0 2 * * * /usr/local/bin/backup-finance.sh >> /var/log/backup-finance.log 2>&1
```
```
min hour day month weekday
 0   2    *    *     *        → 02:00 daily
```
Test with `*/2 * * * *` (every 2 minutes), check `/backup` and the log, then revert to `0 2 * * *`.

## Restore test

```bash
sudo touch /srv/finance/report.txt
sudo /usr/local/bin/backup-finance.sh
sudo rm /srv/finance/report.txt

sudo tar -tzf /backup/finance-<latest>.tar.gz                               # list contents
sudo tar -xzf /backup/finance-<latest>.tar.gz -C / srv/finance/report.txt  # restore one file
ls -l /srv/finance
```

## Bugs hit

| Symptom | Cause | Fix |
|---|---|---|
| Archives named `finance=...` | Typo `=` instead of `-` in `DEST`; retention `find` would never match them | Edit the script |
| `sudo: cannot execute ... Permission denied` | Script missing execute bit; cron would also fail silently | `chmod +x` |
| No log file | Cron hadn't fired yet | Run manually to test |

## Next: systemd timer (TODO)

Replace cron with `backup-finance.service` (`Type=oneshot`) + `backup-finance.timer` (`OnCalendar=*-*-* 02:00:00`, `Persistent=true`), verify with `systemctl list-timers`.
