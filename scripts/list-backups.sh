#!/bin/bash
# List all available backups.
# Usage: list-backups.sh

source "$(dirname "$0")/_common.sh"

if [ ! -d "$BACKUPS_DIR" ] || [ -z "$(ls -A "$BACKUPS_DIR" 2>/dev/null)" ]; then
    echo "No backups found."
    exit 0
fi

echo "Available backups:"
echo ""
for backup in "$BACKUPS_DIR"/*/; do
    [ -d "$backup" ] || continue
    name=$(basename "$backup")
    if [ -f "$backup/manifest.json" ]; then
        operation=$(jq -r '.operation' "$backup/manifest.json")
        target=$(jq -r '.target' "$backup/manifest.json")
        timestamp=$(jq -r '.timestamp' "$backup/manifest.json")
        count=$(jq '.backed_up | length' "$backup/manifest.json")
        echo "  $name"
        echo "    Operation: $operation | Target: $target | Files: $count"
        echo "    Restore:   just restore $name"
        echo ""
    else
        echo "  $name (no manifest)"
        echo ""
    fi
done
