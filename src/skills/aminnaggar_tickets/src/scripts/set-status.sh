#!/bin/bash
# Set ticket status with proper field management
# Usage: set-status.sh <id> <status> [-p path]
#
# Examples:
#   set-status.sh 007 done       # Mark ticket 007 as done
#   set-status.sh 005a current   # Mark sub-ticket 005a as current
#   set-status.sh 003 todo       # Reopen ticket 003

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_tickets_dir

TICKET_ID="$1"
NEW_STATUS="$2"

if [ -z "$TICKET_ID" ] || [ -z "$NEW_STATUS" ]; then
    echo "Usage: set-status.sh <id> <status> [-p path]" >&2
    echo "" >&2
    echo "Valid statuses: draft, todo, current, done" >&2
    exit 1
fi

if [[ ! "$NEW_STATUS" =~ ^(draft|todo|current|done)$ ]]; then
    echo "Error: Invalid status '$NEW_STATUS'" >&2
    echo "Valid statuses: draft, todo, current, done" >&2
    exit 1
fi

TICKET_DIR=$(ls -1 "$TICKETS_DIR" | grep -E "^${TICKET_ID}_" | head -1)

if [ -z "$TICKET_DIR" ]; then
    echo "Error: Ticket not found: $TICKET_ID" >&2
    echo "" >&2
    echo "Run list.sh to see available tickets." >&2
    exit 1
fi

TICKET_FILE=$(resolve_ticket_file "$TICKETS_DIR" "$TICKET_DIR")

if [ ! -f "$TICKET_FILE" ]; then
    echo "Error: Ticket file not found in $TICKET_DIR" >&2
    exit 1
fi

OLD_STATUS=$(yaml_get "status" "$TICKET_FILE")

if [ "$OLD_STATUS" = "$NEW_STATUS" ]; then
    echo "Ticket $TICKET_ID is already '$NEW_STATUS'"
    exit 0
fi

TODAY=$(date +%Y-%m-%d)

yaml_set "status" "$NEW_STATUS" "$TICKET_FILE"

if [ "$NEW_STATUS" = "done" ]; then
    yaml_set "completed" "$TODAY" "$TICKET_FILE"
else
    yaml_remove "completed" "$TICKET_FILE"
fi

TITLE=$(yaml_get "title" "$TICKET_FILE")
echo "Updated: $TICKET_ID - $TITLE"
echo "Path:    $TICKET_FILE"
echo "Status:  $OLD_STATUS → $NEW_STATUS"
if [ "$NEW_STATUS" = "done" ]; then
    echo "Completed: $TODAY"
fi
