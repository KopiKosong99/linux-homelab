# Lab 5: Patching and CVE checks

**Goal:** keep the system patched, and know how to answer "is CVE-X fixed on this box?"

## Windows → Ubuntu mapping

| Windows | Ubuntu |
|---|---|
| KB update | USN (Ubuntu Security Notice), e.g. `USN-xxxx-1` |
| CVE ID | Same CVE IDs |
| MSRC Security Update Guide | ubuntu.com/security/cves and /notices |
| WSUS / Windows Update | apt + unattended-upgrades (Landscape at scale) |
| Defender Vulnerability Mgmt | OpenSCAP + OVAL, Greenbone/OpenVAS, Wazuh |

## Automatic security updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
cat /etc/apt/apt.conf.d/50unattended-upgrades    # security origin only, no auto-reboot
```

## Checking what's pending

```bash
sudo apt update
apt list --upgradable                                     # everything
apt list --upgradable 2>/dev/null | grep -c security      # security count
apt list --upgradable 2>/dev/null | grep linux-           # kernel updates
pro security-status                                       # summary
pro fix CVE-YYYY-NNNNN                                    # affected / fixed / needs update
```

Reading an `apt list --upgradable` line:
```
bind9-host/resolute-updates,resolute-security 1:9.20.24-1ubuntu0.5 amd64 [upgradable from: 1:9.20.24-1ubuntu0.1]
package    repos (-security = CVE fix)        new version          arch   installed version
```

`apt changelog <pkg>` lists every CVE ever fixed in the package, **not** what's pending. Compare `apt-cache policy <pkg>`: if Installed = Candidate, it's fully patched.

## Full CVE report (OpenSCAP + Canonical OVAL)

```bash
sudo apt install -y openscap-scanner bzip2
. /etc/os-release
wget https://security-metadata.canonical.com/oval/com.ubuntu.${VERSION_CODENAME}.usn.oval.xml.bz2
bunzip2 com.ubuntu.${VERSION_CODENAME}.usn.oval.xml.bz2
oscap oval eval --report report.html com.ubuntu.${VERSION_CODENAME}.usn.oval.xml
```

## Applying updates

```bash
# snapshot first
sudo unattended-upgrade -v               # security only (--dry-run to preview)
sudo apt upgrade -y                      # everything
cat /var/run/reboot-required.pkgs 2>/dev/null || echo "No reboot needed"
```

Other useful bits:
- `sudo apt-mark hold <pkg>`: pin a package
- `uname -r`: running kernel; new kernels install alongside old ones (fallback via GRUB → Advanced options)
- `sudo apt autoremove --purge`: clean old kernels

## Observation

Most pending updates on this VM were desktop packages (GNOME, GTK, Bluetooth, GStreamer). Ubuntu Server would carry none of them: a smaller attack surface and fewer patches, which is why servers run headless.
