#!/bin/bash
# Safely delete a proposed ADR
# Usage: safe-delete.sh <id> [-p path]
#
# Only ADRs with status "proposed" can be deleted.
# If the ADR superseded others, those changes are reversed.
#
# Examples:
#   safe-delete.sh 003
#   safe-delete.sh ADR-003
#   safe-delete.sh 003 -p ../other

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

RAW_ID="$1"

if [ -z "$RAW_ID" ]; then
    echo "Usage: safe-delete.sh <id> [-p path]" >&2
    echo "" >&2
    echo "Only proposed ADRs can be deleted." >&2
    exit 1
fi

ADR_FILE=$(resolve_adr_file "$RAW_ID")

if [ -z "$ADR_FILE" ] || [ ! -f "$ADR_FILE" ]; then
    echo "Error: ADR not found: $RAW_ID" >&2
    echo "" >&2
    echo "Available ADRs:" >&2
    for f in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
        [ ! -f "$f" ] && continue
        [[ "$f" == *"template"* ]] && continue
        id=$(yaml_get "id" "$f")
        echo "  $id" >&2
    done
    exit 1
fi

STATUS=$(yaml_get "status" "$ADR_FILE")
TITLE=$(yaml_get "title" "$ADR_FILE")
ADR_ID=$(yaml_get "id" "$ADR_FILE")

if [ "$STATUS" != "proposed" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "Error: Cannot delete $ADR_ID - status is '$STATUS', not 'proposed'" >&2
    echo "" >&2
    echo "Only proposed ADRs can be deleted. To delete this ADR:" >&2
    echo "  1. ${SCRIPTS_DIR}/set-status.sh $RAW_ID proposed" >&2
    echo "  2. ${SCRIPTS_DIR}/safe-delete.sh $RAW_ID" >&2
    exit 1
fi

# Reverse supersession changes if this ADR superseded others
SUPERSEDED_IDS=$(yaml_get_array "supersedes" "$ADR_FILE")
if [ -n "$SUPERSEDED_IDS" ]; then
    echo "Reversing supersession changes:"
    while IFS= read -r old_id; do
        [ -z "$old_id" ] && continue
        old_file=$(resolve_adr_file "$old_id")
        if [ -n "$old_file" ] && [ -f "$old_file" ]; then
            yaml_set "status" "accepted" "$old_file"
            yaml_remove "superseded_by" "$old_file"
            old_title=$(yaml_get "title" "$old_file")
            echo "  $old_id ($old_title) → restored to accepted"
        fi
    done <<< "$SUPERSEDED_IDS"
    echo ""
fi

rm -f "$ADR_FILE"

echo "Deleted: $ADR_ID - $TITLE"
echo "  Removed: $(basename "$ADR_FILE")"
