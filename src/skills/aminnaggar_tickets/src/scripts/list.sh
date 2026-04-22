#!/bin/bash
# List all tickets with status
# Usage: list.sh [filter] [-p path]
#
# Filters: draft, todo, current, done, open (not done), closed (done)
#
# Examples:
#   list.sh              # List all tickets
#   list.sh open         # List draft + todo + current
#   list.sh done         # List only done tickets
#   list.sh -p ../other  # List tickets in another directory

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_tickets_dir

STATUS_FILTER="$1"

# Counters
DRAFT_COUNT=0
TODO_COUNT=0
CURRENT_COUNT=0
DONE_COUNT=0

# Output header
printf "%-6s %-50s %-10s %s\n" "ID" "TITLE" "STATUS" "CREATED"
printf "%s\n" "================================================================================"

for dir in $(ls -1 "$TICKETS_DIR" | grep -E '^[0-9]{3}' | sort); do
    TICKET_FILE=$(resolve_ticket_file "$TICKETS_DIR" "$dir")

    if [ ! -f "$TICKET_FILE" ]; then
        continue
    fi

    ID=$(yaml_get "id" "$TICKET_FILE")
    TITLE=$(yaml_get "title" "$TICKET_FILE")
    STATUS=$(yaml_get "status" "$TICKET_FILE")
    CREATED=$(yaml_get "created" "$TICKET_FILE")
    GH_ISSUE=$(yaml_get "gh_issue" "$TICKET_FILE")

    case "$STATUS" in
        draft) ((DRAFT_COUNT++)) ;;
        todo) ((TODO_COUNT++)) ;;
        current) ((CURRENT_COUNT++)) ;;
        done) ((DONE_COUNT++)) ;;
    esac

    if [ -n "$STATUS_FILTER" ]; then
        case "$STATUS_FILTER" in
            open)    [ "$STATUS" = "done" ] && continue ;;
            closed)  [ "$STATUS" != "done" ] && continue ;;
            *)       [ "$STATUS" != "$STATUS_FILTER" ] && continue ;;
        esac
    fi

    if [[ "$ID" =~ ^[0-9]+[a-z]$ ]]; then
        DISPLAY_ID="  $ID"
    else
        DISPLAY_ID="$ID"
    fi

    if [ ${#TITLE} -gt 48 ]; then
        TITLE="${TITLE:0:45}..."
    fi

    printf "%-6s %-50s %-10s %s\n" "$DISPLAY_ID" "$TITLE" "$STATUS" "$CREATED"
    if [ -n "$GH_ISSUE" ]; then
        echo "       Path: $TICKET_FILE   (GH #$GH_ISSUE)"
    else
        echo "       Path: $TICKET_FILE"
    fi
done

printf "%s\n" "================================================================================"
TOTAL=$((DRAFT_COUNT + TODO_COUNT + CURRENT_COUNT + DONE_COUNT))
printf "Summary: %d draft | %d todo | %d current | %d done | %d total\n" "$DRAFT_COUNT" "$TODO_COUNT" "$CURRENT_COUNT" "$DONE_COUNT" "$TOTAL"
