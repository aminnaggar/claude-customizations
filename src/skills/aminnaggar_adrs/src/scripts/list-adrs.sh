#!/bin/bash
# List ADRs with optional status filter
# Usage: list-adrs.sh [filter] [-p path]
#
# Filters:
#   active     - proposed + accepted (default)
#   all        - all statuses
#   proposed   - only proposed
#   accepted   - only accepted
#   deprecated - only deprecated
#   superseded - only superseded

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

FILTER="${1:-active}"

# Counters
PROPOSED_COUNT=0
ACCEPTED_COUNT=0
DEPRECATED_COUNT=0
SUPERSEDED_COUNT=0

# Output header
printf "%-10s %-50s %-12s %s\n" "ID" "TITLE" "STATUS" "DATE"
printf "%s\n" "================================================================================"

# Process each ADR file
for file in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
    [ ! -f "$file" ] && continue
    [[ "$file" == *"template"* ]] && continue

    ID=$(yaml_get "id" "$file")
    TITLE=$(yaml_get "title" "$file")
    STATUS=$(yaml_get "status" "$file")
    DATE=$(yaml_get "date" "$file")

    [ -z "$ID" ] && continue

    # Update counters
    case "$STATUS" in
        proposed) ((PROPOSED_COUNT++)) ;;
        accepted) ((ACCEPTED_COUNT++)) ;;
        deprecated) ((DEPRECATED_COUNT++)) ;;
        superseded) ((SUPERSEDED_COUNT++)) ;;
    esac

    # Apply filter
    case "$FILTER" in
        active)
            if [ "$STATUS" != "proposed" ] && [ "$STATUS" != "accepted" ]; then
                continue
            fi
            ;;
        all) ;;
        proposed|accepted|deprecated|superseded)
            if [ "$STATUS" != "$FILTER" ]; then
                continue
            fi
            ;;
        *)
            echo "Error: Unknown filter '$FILTER'. Use: active, all, proposed, accepted, deprecated, superseded" >&2
            exit 1
            ;;
    esac

    # Truncate title if too long
    if [ ${#TITLE} -gt 48 ]; then
        TITLE="${TITLE:0:45}..."
    fi

    printf "%-10s %-50s %-12s %s\n" "$ID" "$TITLE" "$STATUS" "$DATE"
    echo "           Path: $file"
done

# Summary
printf "%s\n" "================================================================================"
TOTAL=$((PROPOSED_COUNT + ACCEPTED_COUNT + DEPRECATED_COUNT + SUPERSEDED_COUNT))
printf "Summary: %d proposed | %d accepted | %d deprecated | %d superseded | %d total\n" \
    "$PROPOSED_COUNT" "$ACCEPTED_COUNT" "$DEPRECATED_COUNT" "$SUPERSEDED_COUNT" "$TOTAL"
