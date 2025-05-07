#!/bin/bash
set -euo pipefail

BACKUP_DIR="/bitnami/backups"
TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
BACKUP_FILE="$BACKUP_DIR/backup-${TIMESTAMP}.mbstream"

mkdir -v /tmp/backuptmp && cd /tmp/backuptmp
# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Run xtrabackup stream and log to stderr
echo "[$(date)] Starting xtrabackup stream..." >&2
mariadb-backup --backup --stream=mbstream --user="$MARIADB_BACKUP_USER" --password="$MARIADB_BACKUP_PASSWORD" 2>&1 > "$BACKUP_FILE"
echo "[$(date)] Backup completed: $BACKUP_FILE" >&2

rm -rfv /tmp/backuptmp
