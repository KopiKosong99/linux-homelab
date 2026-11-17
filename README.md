# Linux Homelab

A hands-on Linux system administration lab, built and broken on purpose to practise real sysadmin work: users and permissions, services, storage, backups, patching, and troubleshooting.

## Lab environment

| Item | Value |
|---|---|
| Hypervisor | Oracle VirtualBox (Windows host) |
| Guest OS | Ubuntu 26.04 LTS Desktop ("resolute") |
| VM | `vm01`: 4 vCPU, 10 GB RAM, 25 GB OS disk + 20 GB data disk |
| Adapter 1 | NAT: outbound internet (apt, updates) |
| Adapter 2 | Host-only (`192.168.56.0/24`): SSH from Windows, future VM-to-VM traffic |

Why NAT + Host-only: NAT gives the VM internet without exposing it; host-only gives a stable private lab network reachable from the host. It's the local equivalent of a cloud VNet with a private subnet and outbound NAT.

## Roadmap

| Phase | Focus | Status |
|---|---|---|
| [1](phase1/) | Core admin: users/ACLs, systemd, LVM storage, backups, patching | ✅ Done |
| 2 | Networking & security: SSH hardening, firewall, static IP, fail2ban | ⏳ Next |
| 3 | Services: nginx, DNS (BIND), Samba/NFS, database backup/restore | |
| 4 | Multi-VM: Ubuntu Server + Rocky Linux, Ansible, central logging, monitoring, AD/LDAP join | |
| 5 | Modern stack: Docker/compose, restic backups | |

Cert target: RHCSA (EX200).

## Incidents

Real outages hit during the lab, written up as postmortems:

- [2026-11: Root filesystem stuck read-only after fstab edit](incidents/2026-11-fstab-readonly-root.md)

## Conventions

- Snapshot the VM before every lab and before patching.
- Back up config files before editing: `sudo cp /etc/fstab /etc/fstab.$(date +%F)`
- No real passwords, keys, or work data in this repo.
