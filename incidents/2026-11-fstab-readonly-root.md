# Incident: Root filesystem stuck read-only after fstab edit

| | |
|---|---|
| **Host** | vm01 (Ubuntu 26.04, VirtualBox) |
| **Period** | 2026-10-09 → 2026-11-16 (intermittent) |
| **Impact** | GNOME desktop crash-looped on boot; snapd and other services failed; `/backup` silently not mounted; snapshot restores did not help |
| **Root cause** | `/etc/fstab` root (`/`) entry was overwritten while adding the `/backup` mount |
| **Status** | Resolved |

## Summary

While adding an LVM volume at `/backup` (Phase 1, Lab 3), the existing root line in `/etc/fstab` was edited into the `/backup` line instead of a new line being appended. The system kept booting, but in progressively worse states: first root was double-mounted at `/backup`; later, once that line was pointed at the correct LV, there was no fstab entry for `/` at all, so root never got remounted read-write and the GUI crash-looped.

## Timeline

| Date | Event |
|---|---|
| Oct 9 | `/backup` added to fstab. Root line repurposed rather than a new line added (not noticed) |
| Oct 13 | Planned "break fstab" exercise didn't trigger emergency mode. GUI crash-looped instead; recovered via TTY with `mount -o remount,rw /` and restoring `fstab.bak` |
| Oct 13 | `grep backup /etc/fstab` empty, `backup.mount` unit missing. `/backup` line re-added; emergency-mode exercise then worked as designed |
| Oct 19 | `ls /backup` showed `bin etc usr var...`: root filesystem mounted at `/backup` |
| Oct 21 | `/backup` line corrected (`mount: ext4: mount point does not exist` fixed by repairing field layout). `findmnt /backup` → `vg_data-lv_backup` ✅ |
| Nov 16 | After patching and reboot, `gdm` crash-loop again. Restoring Snapshot 3 didn't help (it contained the bad fstab) |
| Nov 16 | Diagnosed as missing `/` entry; added, root mounts `rw`, GUI recovers |

## Investigation (Nov 16)

```bash
uname -r                          # 7.0.0-43-generic (new kernel, a red herring)
findmnt -no OPTIONS /             # ro,relatime          ← root read-only
journalctl -b -u gdm              # chmod failed ... Read-only file system (os error 30)
dmesg | grep -i -E "drm|error"    # vmwgfx "unsupported hypervisor" (benign VirtualBox warning)
journalctl -b -u systemd-remount-fs   # Finished, no error
dmesg | grep -i ext4              # EXT4-fs (sda2): mounted ... ro  (no EXT4-fs errors)
```

Reasoning:
- **Not corruption:** no `EXT4-fs error`, no "remounting read-only".
- **Not the kernel or graphics driver:** gdm's error was a write failure, not a display failure.
- The kernel always mounts root `ro` first; `systemd-remount-fs` remounts it `rw` **based on the `/` line in fstab**. It "finished" without error but root stayed `ro` → no `/` line to act on.

## Resolution

```bash
sudo mount -o remount,rw /
sudo nano /etc/fstab
```
Final fstab entries:
```
UUID=<root-sda2-uuid>     /        ext4  defaults  0  1
UUID=<lv_backup-uuid>     /backup  ext4  defaults  0  2
```
```bash
sudo systemctl daemon-reload && sudo mount -a && sudo reboot
findmnt -no OPTIONS /             # rw,relatime ✅
sudo cp /etc/fstab /etc/fstab.bak
```
New VM snapshot taken as the clean baseline.

## Why the symptoms were confusing

| Symptom | Explanation |
|---|---|
| Breaking the "backup" UUID didn't cause emergency mode | That line actually held root's UUID |
| `/backup` listed the whole OS | Root partition mounted a second time |
| Root read-only with no disk errors | No `/` entry for `systemd-remount-fs` |
| Snapshot restore didn't fix it | Snapshot captured the broken fstab |
| `fstab.bak` restores made it worse at times | The backup copy was taken from an already-wrong file |

## Lessons / prevention

1. **Append new fstab lines; never edit an existing one into something else.**
2. **Date-stamped backups** before edits: `sudo cp /etc/fstab /etc/fstab.$(date +%F)`, and only refresh the "known good" copy after a verified reboot.
3. **Validate before reboot:** `sudo findmnt --verify` and `sudo mount -a`.
4. **Diff after edits:** `diff /etc/fstab.bak /etc/fstab`.
5. **Post-boot check:** `findmnt /` and `findmnt /backup`. `ro` on root with no ext4 errors almost always means fstab.
6. **Snapshots are only as good as when they were taken.** Label them with what state they capture.
7. Use `nofail` on non-critical data mounts so a missing disk can't block boot.
