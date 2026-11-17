# Lab 3: Storage with LVM, fstab, and emergency-mode recovery

**Goal:** add a data disk, manage it with LVM, mount it persistently, and recover from a broken `/etc/fstab`.

## 1. Add the disk

VM off → Settings → Storage → SATA controller → Add hard disk → Create → VDI, dynamically allocated, 20 GB (`vm01-data.vdi`).

```bash
lsblk        # new empty disk appears as sdb
```

## 2. Build the LVM stack

Ubuntu Desktop doesn't ship LVM tools (Server does):
```bash
sudo apt install -y lvm2
```

```bash
sudo pvcreate /dev/sdb                      # disk → Physical Volume
sudo vgcreate vg_data /dev/sdb              # PV → Volume Group (pool)
sudo lvcreate -L 10G -n lv_backup vg_data   # pool → 10G Logical Volume
sudo mkfs.ext4 /dev/vg_data/lv_backup       # format
sudo mkdir /backup                          # mount point
sudo blkid /dev/vg_data/lv_backup           # get UUID for fstab
```

```
Disk (sdb) → PV → VG vg_data (20G) → LV lv_backup (10G) → ext4 → /backup
```

Why LVM: resize volumes live, pool multiple disks, take snapshots.

## 3. Persistent mount

**Add a new line** to `/etc/fstab` (never repurpose an existing one):
```
UUID=<lv_backup-uuid>  /backup  ext4  defaults  0  2
```

Validate before rebooting:
```bash
sudo findmnt --verify
sudo systemctl daemon-reload
sudo mount -a
findmnt /backup        # SOURCE must be /dev/mapper/vg_data-lv_backup
ls /backup             # fresh volume shows only lost+found
```

| fstab field | Meaning |
|---|---|
| `UUID=...` | Device to mount |
| `/backup` | Mount point |
| `ext4` | Filesystem |
| `defaults` | Mount options (`nofail` makes non-critical mounts skippable at boot) |
| `0` | dump (legacy, always 0) |
| `2` | fsck order: `1` = root, `2` = others |

## 4. Extend live

```bash
sudo lvextend -r -L +5G /dev/vg_data/lv_backup    # -r resizes the filesystem too
df -h /backup                                     # ~15G
```

## 5. Break fstab and recover

Prep (Ubuntu locks root, and emergency mode needs it):
```bash
sudo passwd root
sudo cp /etc/fstab /etc/fstab.bak
```
Snapshot, change one character of the `/backup` UUID, reboot. Boot waits ~90s for the device, then:

```
You are in emergency mode... Give root password for maintenance
```

Recovery from the emergency shell:
```bash
journalctl -xb | grep -i -E "fail|timed out"
mount -o remount,rw /
blkid /dev/vg_data/lv_backup        # real UUID
nano /etc/fstab                     # fix it
systemctl daemon-reload
mount -a                            # no output = fixed
reboot
```

If root is locked: GRUB → `e` → append `init=/bin/bash` to the `linux` line → `Ctrl+X` → `mount -o remount,rw /` → fix → `exec /sbin/init`.

## Error messages decoded

| Message | Meaning |
|---|---|
| `pvcreate: command not found` | `lvm2` not installed |
| `mount: ext4: mount point does not exist` | fstab fields shifted (missing mount point or missing space), so `ext4` was read as the mount point |
| `ls /backup` shows `bin etc usr...` | Root partition's UUID is mounted at `/backup` |
| `ls /backup` shows nothing (not even `lost+found`) | Nothing mounted; bare directory on the root disk |
| `Unit backup.mount could not be found` | systemd isn't generating a unit from fstab, so the line is missing or invalid |
| `Active block inhibitor` on reboot | A session/process holds a shutdown lock. Check `systemd-inhibit --list`; override with `systemctl reboot -i` |
| "System is booting up" at login | `/run/nologin` blocks non-root users mid-boot/shutdown. Log in as root or reset the VM |

What actually happened during this lab is written up in the [fstab incident report](../incidents/2026-11-fstab-readonly-root.md).
