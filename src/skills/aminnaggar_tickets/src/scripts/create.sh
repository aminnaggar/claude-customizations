#!/bin/bash
# Create a new ticket
# Usage: create.sh "<title>" [-p path] [-s parent_id]
#
# Creates the ticket directory and outputs the template content.
# The caller (agent) writes the ticket file using the Write tool.
#
# Examples:
#   create.sh "Fix auth token refresh"
#   create.sh "Add retry logic" -p ../other
#   create.sh "Subtask for outcomes" -s 005

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
ensure_tickets_dir

TITLE="$1"

if [ -z "$TITLE" ]; then
    echo "Usage: create.sh \"<title>\" [-p path] [-s parent_id]" >&2
    echo "" >&2
    echo "Creates a new ticket with auto-generated number and slug." >&2
    echo "Use -s <parent_id> to create a sub-ticket." >&2
    exit 1
fi

# Generate ID
if [ -n "$PARENT_ID" ]; then
    TICKET_ID=$(next_ticket_id "$PARENT_ID")
else
    TICKET_ID=$(next_ticket_id)
fi

if [ $? -ne 0 ]; then
    exit 1
fi

SLUG=$(generate_slug "$TITLE")
TICKET_DIR_NAME="${TICKET_ID}_${SLUG}"
TICKET_DIR_PATH="$TICKETS_DIR/$TICKET_DIR_NAME"
FNAME=$(ticket_filename "$TICKET_ID")
TICKET_FILE="$TICKET_DIR_PATH/$FNAME"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$TICKET_DIR_PATH"

# Build parent line for template
PARENT_LINE=""
if [ -n "$PARENT_ID" ]; then
    PARENT_DIR=$(ls -1 "$TICKETS_DIR" | grep -E "^${PARENT_ID}_" | head -1)
    if [ -n "$PARENT_DIR" ]; then
        PARENT_FNAME=$(ticket_filename "$PARENT_ID")
        PARENT_LINE="parent: '../${PARENT_DIR}/${PARENT_FNAME}'"
    fi
fi

# Print existing tickets
echo "Existing tickets:"
for dir in $(ls -1 "$TICKETS_DIR" | grep -E '^[0-9]{3}' | sort); do
    [ "$dir" = "$TICKET_DIR_NAME" ] && continue
    local_file=$(resolve_ticket_file "$TICKETS_DIR" "$dir")
    [ ! -f "$local_file" ] && continue
    id=$(yaml_get "id" "$local_file")
    title=$(yaml_get "title" "$local_file")
    status=$(yaml_get "status" "$local_file")
    echo "  $id - $title [$status]"
done

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "Created directory: ${TICKET_DIR_NAME}/"
echo "To undo: ${SCRIPTS_DIR}/safe-delete.sh ${TICKET_ID}"
echo ""
echo "Use the Write tool to create the file at: $TICKET_FILE"
echo "The file does not exist yet — do NOT use Edit or Read, use Write directly."
echo ""
echo "--- TEMPLATE ---"
echo "---"
echo "id: \"$TICKET_ID\""
echo "title: \"$TITLE\""
echo "description: "
echo "status: draft"
echo "created: $TODAY"
[ -n "$PARENT_LINE" ] && echo "$PARENT_LINE"
echo "---"
echo ""
echo "# $TITLE"
echo ""
echo "## Objective"
echo ""
echo ""
echo ""
echo "## Acceptance Criteria"
echo ""
echo "- [ ] "
echo ""
echo "## Notes"
echo ""
