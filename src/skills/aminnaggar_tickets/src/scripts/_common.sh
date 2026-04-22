#!/bin/bash
# Shared utilities for ticket scripts
# Source this file; do not execute directly.

# --- Ticket file resolution ---
# Supports TICKET_FILENAME env var for Obsidian-friendly filenames.
#   unset / "default" → ticket.md
#   "id_prefix"       → {id}_ticket.md
resolve_ticket_file() {
    local tickets_dir="$1"
    local dir_name="$2"

    case "${TICKET_FILENAME:-default}" in
        default)
            echo "$tickets_dir/$dir_name/ticket.md"
            ;;
        id_prefix)
            local id="${dir_name%%_*}"
            echo "$tickets_dir/$dir_name/${id}_ticket.md"
            ;;
        *)
            echo "Error: Unknown TICKET_FILENAME mode: $TICKET_FILENAME" >&2
            return 1
            ;;
    esac
}

# Get just the filename portion (e.g. "ticket.md" or "007_ticket.md")
ticket_filename() {
    local id="$1"
    case "${TICKET_FILENAME:-default}" in
        default)    echo "ticket.md" ;;
        id_prefix)  echo "${id}_ticket.md" ;;
    esac
}

# --- Tickets directory resolution ---
# Priority: -p flag > TICKETS_PATH env var > $PWD/tickets/

# Parse -p and -s flags from script arguments.
# Sets TICKETS_DIR, PARENT_ID, SHIFT_COUNT.
parse_flags() {
    SHIFT_COUNT=0
    PARENT_ID=""
    OPTIND=1
    while getopts "p:s:" opt "$@"; do
        case $opt in
            p) TICKETS_DIR="$OPTARG" ;;
            s) PARENT_ID="$OPTARG" ;;
            \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
        esac
    done
    SHIFT_COUNT=$((OPTIND - 1))
    TICKETS_DIR="${TICKETS_DIR:-${TICKETS_PATH:-$PWD/tickets}}"
}

# Exit with error if tickets directory does not exist.
require_tickets_dir() {
    if [ ! -d "$TICKETS_DIR" ]; then
        echo "Error: Tickets directory not found: $TICKETS_DIR" >&2
        echo "" >&2
        echo "Either:" >&2
        echo "  - Run from a directory containing a tickets/ folder" >&2
        echo "  - Set TICKETS_PATH environment variable" >&2
        echo "  - Use -p <path> flag" >&2
        exit 1
    fi
}

# Create tickets directory if it does not exist.
ensure_tickets_dir() {
    if [ ! -d "$TICKETS_DIR" ]; then
        mkdir -p "$TICKETS_DIR"
    fi
}

# --- YAML frontmatter helpers ---

# Read a field value from YAML frontmatter.
# Usage: yaml_get "field" "file"
yaml_get() {
    local field="$1" file="$2"
    grep -m1 "^${field}:" "$file" | sed "s/^${field}:[[:space:]]*//" | tr -d '"'"'"
}

# Set a field value in YAML frontmatter.
# Updates existing field or appends before closing ---.
# Usage: yaml_set "field" "value" "file"
yaml_set() {
    local field="$1" value="$2" file="$3"
    if grep -q "^${field}:" "$file"; then
        sed -i '' "s|^${field}:.*|${field}: ${value}|" "$file"
    else
        awk -v f="$field" -v v="$value" '
            /^---$/ { count++ }
            count == 2 && /^---$/ { print f ": " v }
            { print }
        ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
}

# Remove a field from YAML frontmatter.
# Usage: yaml_remove "field" "file"
yaml_remove() {
    local field="$1" file="$2"
    sed -i '' "/^${field}:/d" "$file"
}

# --- Ticket numbering ---

# Get next main ticket number or sub-ticket ID.
# Requires TICKETS_DIR to be set.
# Usage: next_ticket_id           -> "007"
#        next_ticket_id "005"     -> "005c"
next_ticket_id() {
    local parent="$1"

    if [ -z "$parent" ]; then
        local highest
        highest=$(ls -1 "$TICKETS_DIR" 2>/dev/null | \
            grep -E '^[0-9]{3}_' | \
            grep -vE '^[0-9]{3}[a-z]_' | \
            sed 's/_.*//' | \
            sort -n | \
            tail -1)

        if [ -z "$highest" ]; then
            printf "%03d" 1
        else
            printf "%03d" $((10#$highest + 1))
        fi
    else
        local highest_letter
        highest_letter=$(ls -1 "$TICKETS_DIR" 2>/dev/null | \
            grep -E "^${parent}[a-z]_" | \
            sed "s/^${parent}//" | \
            sed 's/_.*//' | \
            sort | \
            tail -1)

        if [ -z "$highest_letter" ]; then
            echo "${parent}a"
        else
            local next_letter
            next_letter=$(echo "$highest_letter" | tr 'a-y' 'b-z')
            if [ "$next_letter" = "$highest_letter" ]; then
                echo "Error: Exceeded maximum sub-tickets (z)" >&2
                return 1
            fi
            echo "${parent}${next_letter}"
        fi
    fi
}

# --- Slug generation ---

# Generate a slug from a title string.
# Lowercase, underscores, no special chars.
generate_slug() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-z0-9_' | sed 's/__*/_/g; s/^_//; s/_$//'
}
