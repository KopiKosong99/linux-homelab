# Lab 1: Users, groups, permissions, ACLs

**Scenario:** a `finance` team needs a shared folder only they can write to; an auditor gets read-only access.

## Setup

```bash
sudo groupadd finance
sudo useradd -m -s /bin/bash -G finance alice
sudo useradd -m -s /bin/bash -G finance bob
sudo useradd -m -s /bin/bash carol          # auditor
sudo passwd alice                           # repeat for bob, carol

sudo mkdir -p /srv/finance
sudo chown root:finance /srv/finance
sudo chmod 2770 /srv/finance                # setgid: new files inherit the finance group
sudo setfacl -m u:carol:rx /srv/finance     # auditor: read + traverse
sudo setfacl -d -m u:carol:rx /srv/finance  # default ACL so new files are readable too
```

## Tasks

| Task | Command |
|---|---|
| Limited sudo for alice (restart services only) | `sudo visudo -f /etc/sudoers.d/alice` → `alice ALL=(root) /usr/bin/systemctl restart *` |
| Force password change at next login | `sudo chage -d 0 bob` |
| Lock / unlock an account | `sudo usermod -L carol` / `sudo usermod -U carol` |
| Remove user from group | `sudo gpasswd -d bob finance` |

## Verify

- `su - alice` → can create files in `/srv/finance`
- `su - carol` → can read, cannot write
- `bob` removed from `finance` → `Permission denied`
- `getfacl /srv/finance` shows the ACL entries

## Notes

- `chmod 2770`: the leading `2` is setgid on a directory, so team files stay group-owned by `finance`.
- `passwd` warns "BAD PASSWORD: shorter than 8 characters" but root can still set it. A "passwords do not match" error is a retype mismatch (input is hidden). `Ctrl+C` cancels without changing anything.
