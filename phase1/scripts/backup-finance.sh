#!/bin/bash
# Daily backup of /srv/finance to the LVM-backed /backup volume.
# Keeps 7 days of archives.
set -euo pipefail

DEST=/backup/finance-$(date +%F_%H%M).tar.gz
tar -czf "$DEST" /srv/finance
find /backup -name 'finance-*.tar.gz' -mtime +7 -delete
echo "Backup OK: $DEST"
