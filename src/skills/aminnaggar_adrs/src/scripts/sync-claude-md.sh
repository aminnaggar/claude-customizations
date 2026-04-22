#!/bin/bash
# Output CLAUDE.md ADRs section content
# Usage: sync-claude-md.sh [-p path]
#
# This outputs the formatted section content. The agent handles editing CLAUDE.md.

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

# Output section header
echo "## ADRs"
echo ""

FOUND_ANY=false
MISSING_SUMMARY=()

# Process each ADR file
for file in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
    [ ! -f "$file" ] && continue
    [[ "$file" == *"template"* ]] && continue

    CRITICAL=$(yaml_get_bool "context-critical" "$file")

    if [ "$CRITICAL" != "true" ]; then
        continue
    fi

    ID=$(yaml_get "id" "$file")
    STATUS=$(yaml_get "status" "$file")
    SUMMARY=$(yaml_get "summary" "$file")

    [ -z "$ID" ] && continue

    # Only include active ADRs
    if [ "$STATUS" != "proposed" ] && [ "$STATUS" != "accepted" ]; then
        continue
    fi

    if [ -z "$SUMMARY" ]; then
        MISSING_SUMMARY+=("$ID")
        continue
    fi

    echo "- $SUMMARY - $ID"
    FOUND_ANY=true
done

if [ "$FOUND_ANY" = false ]; then
    echo "_No context-critical ADRs. Run \`/adr new\` to create one._"
fi

# Warn about missing summaries
if [ ${#MISSING_SUMMARY[@]} -gt 0 ]; then
    echo "" >&2
    echo "Warning: context-critical ADRs missing summary field:" >&2
    for id in "${MISSING_SUMMARY[@]}"; do
        echo "  $id" >&2
    done
fi
