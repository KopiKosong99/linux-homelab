# Phase 1: Core Linux Administration

| Lab | Topic | Notes |
|---|---|---|
| 0 | [Access: SSH from Windows over host-only network](00-access.md) | |
| 1 | [Users, groups, permissions, ACLs](01-users-acl.md) | |
| 2 | [systemd service and journald](02-systemd-service.md) | [`heartbeat.service`](systemd/heartbeat.service) |
| 3 | [Storage: LVM, fstab, emergency-mode recovery](03-lvm-storage.md) | Led to an [incident](../incidents/2026-11-fstab-readonly-root.md) |
| 4 | [Scheduled backups: script, cron, restore](04-backups.md) | [`backup-finance.sh`](scripts/backup-finance.sh) |
| 5 | [Patching and CVE checks](05-patching.md) | |

## Key takeaways

- `/etc/fstab` mistakes can take a system down in non-obvious ways. Always validate with `findmnt --verify` and `mount -a` before rebooting.
- Ubuntu locks root by default; emergency mode needs a root password (or a GRUB `init=/bin/bash` workaround).
- Cron is silent. Redirect output to a log, or you'll never see failures (e.g. a script missing `+x`).
- A backup isn't real until a restore has been tested.
