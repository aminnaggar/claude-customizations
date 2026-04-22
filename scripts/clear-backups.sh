#!/bin/bash
# Delete all backups.
# Usage: clear-backups.sh

source "$(dirname "$0")/_common.sh"

if [ ! -d "$BACKUPS_DIR" ] || [ -z "$(ls -A "$BACKUPS_DIR" 2>/dev/null)" ]; then
    echo "No backups to clear."
    exit 0
fi

count=$(find "$BACKUPS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
rm -rf "${BACKUPS_DIR:?}/"*
echo "Cleared $count backup(s)."
