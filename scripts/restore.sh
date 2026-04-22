#!/bin/bash
# Restore from a named backup.
# Usage: restore.sh <backup_name>

source "$(dirname "$0")/_common.sh"

BACKUP_NAME="$1"
BACKUP_DIR="$BACKUPS_DIR/$BACKUP_NAME"

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Backup not found at $BACKUP_DIR"
    exit 1
fi
if [ ! -f "$BACKUP_DIR/manifest.json" ]; then
    echo "Error: No manifest.json found in backup"
    exit 1
fi

OPERATION=$(jq -r '.operation' "$BACKUP_DIR/manifest.json")
TARGET=$(jq -r '.target' "$BACKUP_DIR/manifest.json")
echo "Restoring backup: $BACKUP_NAME"
echo "  Operation: $OPERATION"
echo "  Target: $TARGET"

# Restore each backed-up item
jq -c '.backed_up[]' "$BACKUP_DIR/manifest.json" | while IFS= read -r entry; do
    SOURCE=$(echo "$entry" | jq -r '.source')
    LOCAL=$(echo "$entry" | jq -r '.local')
    EXISTED=$(echo "$entry" | jq -r '.existed')
    BACKUP_PATH="$BACKUP_DIR/$LOCAL"

    if [ "$EXISTED" = "false" ]; then
        # It didn't exist before the operation — remove what was installed
        if [ -e "$SOURCE" ]; then
            rm -rf "$SOURCE"
            echo "  Removed $SOURCE (did not exist before this operation)"
        fi
        continue
    fi

    echo "  Restoring $SOURCE"
    if [ -d "$BACKUP_PATH" ]; then
        rm -rf "$SOURCE"
        cp -r "$BACKUP_PATH" "$SOURCE"
    else
        mkdir -p "$(dirname "$SOURCE")"
        cp "$BACKUP_PATH" "$SOURCE"
    fi
done

echo "Restore complete."
