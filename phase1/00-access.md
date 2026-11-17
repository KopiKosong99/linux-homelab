# Lab 0: SSH access from Windows

**Goal:** manage the VM over SSH from the Windows host instead of the VirtualBox console.

## Steps

1. VM powered off → Settings → Network:
   - Adapter 1: **NAT** (unchanged, keeps internet)
   - Adapter 2: **Enable** → **Host-only Adapter** → VirtualBox Host-Only Ethernet Adapter
2. In the VM:
   ```bash
   sudo apt update && sudo apt install -y openssh-server
   ip -br a        # enp0s3 = NAT (xxx.xxx.xxx.xxx = VM NAT IP), enp0s8 = host-only (xxx.xxx.xxx.xxx = VM host-only IP)
   ```
3. From Windows PowerShell:
   ```powershell
   ssh vboxuser@xxx.xxx.xxx.xxx    # VM host-only IP (from `ip -br a`, enp0s8)
   ```

Optional `~/.ssh/config` on Windows:
```
Host vm01
    # HostName = VM host-only IP
    HostName xxx.xxx.xxx.xxx
    User vboxuser
```

## Gotchas hit

| Problem | Cause | Fix |
|---|---|---|
| Only `enp0s3` / `xxx.xxx.xxx.xxx` (VM NAT IP) visible | NAT only; Windows can't reach NAT guests | Add the host-only adapter (Adapter 2) |
| `Permission denied` on password | No username given, so SSH used the Windows domain login (`DOMAIN\user`) | Specify the Linux user: `ssh vboxuser@...` |

## Network modes compared

| Mode | VM → Internet | Host → VM | VM ↔ VM |
|---|---|---|---|
| NAT | ✅ | ❌ (port-forward only) | ❌ |
| Host-only | ❌ | ✅ | ✅ |
| Bridged | ✅ | ✅ | ✅ (but exposed to LAN, IP changes per network) |

The VM host-only IP comes from VirtualBox DHCP and can change; a static IP via netplan is planned for Phase 2.
