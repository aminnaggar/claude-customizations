#!/bin/bash
# Safely delete a draft ticket
# Usage: safe-delete.sh <id> [-p path]
#
# Only tickets with status "draft" can be deleted.
#
# Examples:
#   safe-delete.sh 003
#   safe-delete.sh 005a -p ../other

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_tickets_dir

TICKET_ID="$1"

if [ -z "$TICKET_ID" ]; then
    echo "Usage: safe-delete.sh <id> [-p path]" >&2
    echo "" >&2
    echo "Only draft tickets can be deleted." >&2
    exit 1
fi

TICKET_DIR=$(ls -1 "$TICKETS_DIR" | grep -E "^${TICKET_ID}_" | head -1)

if [ -z "$TICKET_DIR" ]; then
    echo "Error: Ticket not found: $TICKET_ID" >&2
    echo "" >&2
    echo "Available tickets:" >&2
    for dir in $(ls -1 "$TICKETS_DIR" | grep -E '^[0-9]{3}' | sort); do
        local_file=$(resolve_ticket_file "$TICKETS_DIR" "$dir")
        [ ! -f "$local_file" ] && continue
        id=$(yaml_get "id" "$local_file")
        echo "  $id" >&2
    done
    exit 1
fi

TICKET_FILE=$(resolve_ticket_file "$TICKETS_DIR" "$TICKET_DIR")

# If no ticket file exists, this is an empty directory (create ran but file was never written)
if [ ! -f "$TICKET_FILE" ]; then
    rm -rf "$TICKETS_DIR/$TICKET_DIR"
    echo "Deleted empty ticket directory: $TICKET_DIR/"
    exit 0
fi

STATUS=$(yaml_get "status" "$TICKET_FILE")
TITLE=$(yaml_get "title" "$TICKET_FILE")

if [ "$STATUS" != "draft" ]; then
    SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
    echo "Error: Cannot delete ticket $TICKET_ID - status is '$STATUS', not 'draft'" >&2
    echo "" >&2
    echo "Only draft tickets can be deleted. To delete this ticket:" >&2
    echo "  1. ${SCRIPTS_DIR}/set-status.sh $TICKET_ID draft" >&2
    echo "  2. ${SCRIPTS_DIR}/safe-delete.sh $TICKET_ID" >&2
    exit 1
fi

rm -rf "$TICKETS_DIR/$TICKET_DIR"

echo "Deleted: $TICKET_ID - $TITLE"
echo "  Removed: $TICKET_DIR/"
