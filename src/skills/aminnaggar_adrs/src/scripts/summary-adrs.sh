#!/bin/bash
# Show id + summary for all active ADRs (for conflict detection)
# Usage: summary-adrs.sh [-p path]

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

# Output header
printf "%-10s %-12s %s\n" "ID" "STATUS" "SUMMARY"
printf "%s\n" "================================================================================"

# Process each ADR file - only active (proposed + accepted)
for file in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
    [ ! -f "$file" ] && continue
    [[ "$file" == *"template"* ]] && continue

    ID=$(yaml_get "id" "$file")
    STATUS=$(yaml_get "status" "$file")
    SUMMARY=$(yaml_get "summary" "$file")
    TITLE=$(yaml_get "title" "$file")

    [ -z "$ID" ] && continue

    # Only show active ADRs
    if [ "$STATUS" != "proposed" ] && [ "$STATUS" != "accepted" ]; then
        continue
    fi

    # Use title if no summary
    DISPLAY="${SUMMARY:-$TITLE}"

    printf "%-10s %-12s %s\n" "$ID" "$STATUS" "$DISPLAY"
done
