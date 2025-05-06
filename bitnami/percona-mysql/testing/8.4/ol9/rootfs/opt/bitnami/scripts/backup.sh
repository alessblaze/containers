#!/bin/bash
set -euo pipefail

BACKUP_DIR="/bitnami/backups"
TIMESTAMP=$(date +'%Y%m%d-%H%M%S')
BACKUP_FILE="$BACKUP_DIR/backup-${TIMESTAMP}.xbstream"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Run xtrabackup stream and log to stderr
echo "[$(date)] Starting xtrabackup stream..." >&2
xtrabackup --backup --stream=xbstream --user="$MYSQL_BACKUP_USER" --password="$MYSQL_BACKUP_PASSWORD" 2>&1 > "$BACKUP_FILE"
echo "[$(date)] Backup completed: $BACKUP_FILE" >&2
