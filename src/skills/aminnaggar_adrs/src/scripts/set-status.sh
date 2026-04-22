#!/bin/bash
# Set ADR status with proper field management
# Usage: set-status.sh <id> <status> [-p path]
#
# For standalone lifecycle transitions (not supersession -- use create.sh -s for that).
#
# Examples:
#   set-status.sh 003 accepted       # Accept a proposed ADR
#   set-status.sh ADR-003 deprecated  # Deprecate an accepted ADR
#   set-status.sh 003 proposed        # Reopen an ADR

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

RAW_ID="$1"
NEW_STATUS="$2"

if [ -z "$RAW_ID" ] || [ -z "$NEW_STATUS" ]; then
    echo "Usage: set-status.sh <id> <status> [-p path]" >&2
    echo "" >&2
    echo "Valid statuses: proposed, accepted, deprecated" >&2
    echo "For supersession, use: create.sh -s <ids> \"<title>\"" >&2
    exit 1
fi

if [[ ! "$NEW_STATUS" =~ ^(proposed|accepted|deprecated)$ ]]; then
    echo "Error: Invalid status '$NEW_STATUS'" >&2
    echo "Valid statuses: proposed, accepted, deprecated" >&2
    echo "" >&2
    echo "To supersede an ADR, create a new one with: create.sh -s $RAW_ID \"<title>\"" >&2
    exit 1
fi

ADR_FILE=$(resolve_adr_file "$RAW_ID")

if [ -z "$ADR_FILE" ] || [ ! -f "$ADR_FILE" ]; then
    echo "Error: ADR not found: $RAW_ID" >&2
    echo "" >&2
    echo "Run list-adrs.sh to see available ADRs." >&2
    exit 1
fi

OLD_STATUS=$(yaml_get "status" "$ADR_FILE")

if [ "$OLD_STATUS" = "$NEW_STATUS" ]; then
    ADR_ID=$(yaml_get "id" "$ADR_FILE")
    echo "$ADR_ID is already '$NEW_STATUS'"
    exit 0
fi

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

yaml_set "status" "$NEW_STATUS" "$ADR_FILE"

ADR_ID=$(yaml_get "id" "$ADR_FILE")
TITLE=$(yaml_get "title" "$ADR_FILE")
CONTEXT_CRITICAL=$(yaml_get_bool "context-critical" "$ADR_FILE")

echo "Updated: $ADR_ID - $TITLE"
echo "Path:    $ADR_FILE"
echo "Status:  $OLD_STATUS → $NEW_STATUS"

if [ "$CONTEXT_CRITICAL" = "true" ]; then
    echo ""
    echo "This ADR is context-critical. Run sync to update CLAUDE.md:"
    echo "  ${SCRIPTS_DIR}/sync-claude-md.sh"
fi
