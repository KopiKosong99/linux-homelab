# Lab 2: systemd service and logs

**Goal:** run a custom script as a managed, self-healing service.

## Script

`/usr/local/bin/heartbeat.sh`:
```bash
#!/bin/bash
while true; do echo "heartbeat $(date)"; sleep 30; done
```
```bash
sudo chmod +x /usr/local/bin/heartbeat.sh
```

## Unit file

[`systemd/heartbeat.service`](systemd/heartbeat.service) → `/etc/systemd/system/heartbeat.service`

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now heartbeat
```

## Tasks

| Task | Command |
|---|---|
| Follow logs live | `journalctl -u heartbeat -f` |
| Kill it, confirm auto-restart | `sudo pkill -f heartbeat.sh` then `systemctl status heartbeat` |
| List failed units | `systemctl --failed` |
| Errors from current boot | `journalctl -b -p err` |

## Verify

- Survives a reboot (`enable`)
- Restarts after being killed (`Restart=on-failure`)
- Runs as an unprivileged user (`User=nobody`)
