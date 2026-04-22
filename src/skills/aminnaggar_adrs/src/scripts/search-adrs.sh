#!/bin/bash
# Search ADRs by content, tags, title, or ID
# Usage: search-adrs.sh "query" [-p path]
#
# Examples:
#   search-adrs.sh "authentication"
#   search-adrs.sh "grpc"
#   search-adrs.sh "ADR-003"

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
require_adr_dir

QUERY="$1"

if [ -z "$QUERY" ]; then
    echo "Usage: search-adrs.sh \"query\" [-p path]" >&2
    exit 1
fi

echo "Search: \"$QUERY\""
echo ""
echo "RESULTS:"
echo "================================================================================"

FOUND=0

for file in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
    [ ! -f "$file" ] && continue
    [[ "$file" == *"template"* ]] && continue

    ID=$(yaml_get "id" "$file")
    TITLE=$(yaml_get "title" "$file")
    STATUS=$(yaml_get "status" "$file")
    SUMMARY=$(yaml_get "summary" "$file")

    [ -z "$ID" ] && continue

    MATCH_LOCATION=""

    if echo "$ID" | grep -qi "$QUERY"; then
        MATCH_LOCATION="id"
    fi

    if echo "$TITLE" | grep -qi "$QUERY"; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }title"
    fi

    if echo "$SUMMARY" | grep -qi "$QUERY"; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }summary"
    fi

    # Check tags
    TAGS_MATCH=$(grep -A 20 "^tags:" "$file" | grep -i "  - .*$QUERY" | head -1)
    if [ -n "$TAGS_MATCH" ]; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }tags"
    fi

    # Check body content (below frontmatter)
    CONTENT_MATCH=$(awk '/^---$/{n++; if(n==2) p=1; next} p{print}' "$file" | grep -i "$QUERY" | head -1)
    if [ -n "$CONTENT_MATCH" ]; then
        MATCH_LOCATION="${MATCH_LOCATION:+$MATCH_LOCATION, }content"
    fi

    if [ -n "$MATCH_LOCATION" ]; then
        ((FOUND++))
        echo ""
        printf "[%d] %s %s" "$FOUND" "$ID" "$TITLE"
        printf "%*s%s\n" $((60 - ${#ID} - ${#TITLE})) "" "$STATUS"

        if [ -n "$SUMMARY" ]; then
            echo "    Summary: $SUMMARY"
        fi
        echo "    Path: $file"
        echo "    Match: $MATCH_LOCATION"

        if [ -n "$CONTENT_MATCH" ]; then
            CONTENT_MATCH=$(echo "$CONTENT_MATCH" | sed 's/^[[:space:]]*//')
            echo "    Snippet: ...${CONTENT_MATCH:0:70}..."
        fi
    fi
done

echo ""
echo "================================================================================"

if [ $FOUND -eq 0 ]; then
    echo "No ADRs found matching \"$QUERY\""
else
    echo "Found $FOUND ADR(s)"
fi
