#!/bin/bash
# Search tickets by ID, title, description, or content
# Usage: find.sh "query" [-p path]
#
# Examples:
#   find.sh "authentication"
#   find.sh "005"
#   find.sh "mock data" -p ../other

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_tickets_dir

QUERY="$1"

if [ -z "$QUERY" ]; then
    echo "Usage: find.sh \"search query\" [-p path]" >&2
    exit 1
fi

echo "Search: \"$QUERY\""
echo ""
echo "RESULTS:"
echo "================================================================================"

FOUND=0

for dir in $(ls -1 "$TICKETS_DIR" | grep -E '^[0-9]{3}' | sort); do
    TICKET_FILE=$(resolve_ticket_file "$TICKETS_DIR" "$dir")

    if [ ! -f "$TICKET_FILE" ]; then
        continue
    fi

    ID=$(yaml_get "id" "$TICKET_FILE")
    TITLE=$(yaml_get "title" "$TICKET_FILE")
    DESCRIPTION=$(yaml_get "description" "$TICKET_FILE")
    STATUS=$(yaml_get "status" "$TICKET_FILE")

    MATCH_LOCATION=""

    if echo "$ID" | grep -qi "$QUERY"; then
        MATCH_LOCATION="id"
    fi

    if echo "$TITLE" | grep -qi "$QUERY"; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }title"
    fi

    if echo "$DESCRIPTION" | grep -qi "$QUERY"; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }description"
    fi

    CONTENT_MATCH=$(grep -i "$QUERY" "$TICKET_FILE" | grep -v "^id:" | grep -v "^title:" | grep -v "^description:" | head -1)
    if [ -n "$CONTENT_MATCH" ]; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }content"
    fi

    if [ -n "$MATCH_LOCATION" ]; then
        ((FOUND++))
        echo ""
        printf "[%d] %s %s" "$FOUND" "$ID" "$TITLE"
        printf "%*s%s\n" $((60 - ${#ID} - ${#TITLE})) "" "$STATUS"

        if [ ${#DESCRIPTION} -gt 70 ]; then
            DESCRIPTION="${DESCRIPTION:0:67}..."
        fi
        echo "    Description: $DESCRIPTION"
        echo "    Path: $TICKET_FILE"
        echo "    Match: $MATCH_LOCATION"

        if [ -n "$CONTENT_MATCH" ]; then
            echo "    Snippet: ...${CONTENT_MATCH:0:60}..."
        fi
    fi
done

echo ""
echo "================================================================================"

if [ $FOUND -eq 0 ]; then
    echo "No tickets found matching \"$QUERY\""
else
    echo "Found $FOUND ticket(s)"
fi
