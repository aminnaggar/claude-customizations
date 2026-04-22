#!/bin/bash
# Create a new ADR
# Usage: create.sh "<title>" [-p path] [-s ADR-001,ADR-003]
#
# Creates the ADR file path and outputs the template content.
# The caller (agent) writes the ADR file using the Write tool.
#
# Examples:
#   create.sh "Use Drizzle ORM"
#   create.sh "Custom JWT auth" -p ../other
#   create.sh "Switch to gRPC" -s ADR-001,ADR-003

source "$(dirname "$0")/_common.sh"
parse_flags "$@"
shift $SHIFT_COUNT
ensure_adr_dir

TITLE="$1"

if [ -z "$TITLE" ]; then
    echo "Usage: create.sh \"<title>\" [-p path] [-s ADR-001,ADR-003]" >&2
    echo "" >&2
    echo "Creates a new ADR with auto-generated number and slug." >&2
    echo "Use -s to supersede existing ADRs (comma-separated IDs)." >&2
    exit 1
fi

# Generate ID and filename
ADR_NUM=$(next_adr_id)
ADR_ID="ADR-${ADR_NUM}"
SLUG=$(generate_slug "$TITLE")
FILENAME="${ADR_NUM}-${SLUG}.md"
ADR_FILE="$ADR_DIR/$FILENAME"
TODAY=$(date +%Y-%m-%d)
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Process supersession: update old ADRs immediately
SUPERSEDES_ARRAY="[]"
SUPERSEDED_FILES=()
if [ -n "$SUPERSEDES_LIST" ]; then
    # Build supersedes array and update old ADRs
    SUPERSEDES_ITEMS=()
    IFS=',' read -ra IDS <<< "$SUPERSEDES_LIST"
    for old_id in "${IDS[@]}"; do
        old_id=$(echo "$old_id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        old_file=$(resolve_adr_file "$old_id")
        if [ -z "$old_file" ] || [ ! -f "$old_file" ]; then
            echo "Error: ADR not found: $old_id" >&2
            echo "" >&2
            echo "Available ADRs:" >&2
            for f in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
                [ ! -f "$f" ] && continue
                [[ "$f" == *"template"* ]] && continue
                local_id=$(yaml_get "id" "$f")
                local_title=$(yaml_get "title" "$f")
                echo "  $local_id - $local_title" >&2
            done
            exit 1
        fi
        SUPERSEDES_ITEMS+=("$old_id")
        SUPERSEDED_FILES+=("$old_file")

        # Update old ADR
        yaml_set "status" "superseded" "$old_file"
        yaml_set "superseded_by" "$ADR_ID" "$old_file"
    done

    # Build YAML array string
    SUPERSEDES_ARRAY=""
    for item in "${SUPERSEDES_ITEMS[@]}"; do
        SUPERSEDES_ARRAY="${SUPERSEDES_ARRAY}\n  - ${item}"
    done
    SUPERSEDES_ARRAY="supersedes:${SUPERSEDES_ARRAY}"
fi

# Print existing ADRs (decision context)
echo "Existing ADRs:"
for file in $(ls -1 "$ADR_DIR"/*.md 2>/dev/null | grep -E '/[0-9]{3}-' | sort); do
    [ ! -f "$file" ] && continue
    [[ "$file" == *"template"* ]] && continue
    id=$(yaml_get "id" "$file")
    title=$(yaml_get "title" "$file")
    status=$(yaml_get "status" "$file")
    summary=$(yaml_get "summary" "$file")
    display="${summary:-$title}"
    echo "  $id - $display [$status]"
done

# Show supersession changes if any
if [ ${#SUPERSEDED_FILES[@]} -gt 0 ]; then
    echo ""
    echo "Supersession changes applied:"
    for old_file in "${SUPERSEDED_FILES[@]}"; do
        old_id=$(yaml_get "id" "$old_file")
        old_title=$(yaml_get "title" "$old_file")
        echo "  $old_id ($old_title) → superseded by $ADR_ID"
    done
fi

echo ""
echo "Created: $ADR_ID"
echo "To undo: ${SCRIPTS_DIR}/safe-delete.sh ${ADR_NUM}"
echo ""
echo "Use the Write tool to create the file at: $ADR_FILE"
echo "The file does not exist yet — do NOT use Edit or Read, use Write directly."
echo ""
echo "--- TEMPLATE ---"
echo "---"
echo "id: $ADR_ID"
echo "title: \"$TITLE\""
echo "date: $TODAY"
echo "status: proposed"
echo ""
if [ "$SUPERSEDES_ARRAY" = "[]" ]; then
    echo "supersedes: []"
else
    echo -e "$SUPERSEDES_ARRAY"
fi
echo "superseded_by: null"
echo ""
echo "tags:"
echo "  - "
echo "deciders:"
echo "  - "
echo ""
echo "context-critical: false"
echo "summary: \"\""
echo "---"
echo ""
echo "# $TITLE"
echo ""
echo "## Context"
echo ""
echo ""
echo ""
echo "## Decision"
echo ""
echo "We will "
echo ""
echo "## Rationale"
echo ""
echo "- "
echo ""
echo "## Consequences"
echo ""
echo "### Positive"
echo "- "
echo ""
echo "### Negative"
echo "- "
echo ""
echo "### Neutral"
echo "- "

# Sync reminder
echo ""
echo "---"
echo "NOTE: If you set context-critical: true, run sync afterward:"
echo "  ${SCRIPTS_DIR}/sync-claude-md.sh"
