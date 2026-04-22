#!/bin/bash
# Shared utilities for ADR scripts
# Source this file; do not execute directly.

# --- ADR directory resolution ---
# Priority: -p flag > ADR_PATH env var > $PWD/adrs/

# Parse -p and -s flags from script arguments.
# Sets ADR_DIR, SUPERSEDES_LIST, SHIFT_COUNT.
parse_flags() {
    SHIFT_COUNT=0
    SUPERSEDES_LIST=""
    OPTIND=1
    while getopts "p:s:" opt "$@"; do
        case $opt in
            p) ADR_DIR="$OPTARG" ;;
            s) SUPERSEDES_LIST="$OPTARG" ;;
            \?) echo "Unknown option: -$OPTARG" >&2; exit 1 ;;
        esac
    done
    SHIFT_COUNT=$((OPTIND - 1))
    ADR_DIR="${ADR_DIR:-${ADR_PATH:-$PWD/adrs}}"
}

# Exit with error if ADR directory does not exist.
require_adr_dir() {
    if [ ! -d "$ADR_DIR" ]; then
        echo "Error: ADR directory not found: $ADR_DIR" >&2
        echo "" >&2
        echo "Either:" >&2
        echo "  - Run from a directory containing an adrs/ folder" >&2
        echo "  - Set ADR_PATH environment variable" >&2
        echo "  - Use -p <path> flag" >&2
        exit 1
    fi
}

# Create ADR directory if it does not exist.
ensure_adr_dir() {
    if [ ! -d "$ADR_DIR" ]; then
        mkdir -p "$ADR_DIR"
    fi
}

# --- YAML frontmatter helpers ---
# No yq dependency -- uses grep/sed only.

# Read a field value from YAML frontmatter.
# Usage: yaml_get "field" "file"
yaml_get() {
    local field="$1" file="$2"
    grep -m1 "^${field}:" "$file" 2>/dev/null | sed "s/^${field}:[[:space:]]*//" | tr -d '"'"'"
}

# Read a boolean field (returns "true" or "false").
# Usage: yaml_get_bool "field" "file"
yaml_get_bool() {
    local val
    val=$(yaml_get "$1" "$2")
    if [ "$val" = "true" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Read a YAML array field as newline-separated values.
# Usage: yaml_get_array "field" "file"
yaml_get_array() {
    local field="$1" file="$2"
    awk -v f="$field" '
        /^---$/ { n++; if(n==2) exit; next }
        n==1 && $0 ~ "^"f":" { capture=1; next }
        n==1 && capture && /^  - / { gsub(/^  - /, ""); gsub(/["'"'"']/, ""); print; next }
        n==1 && capture { exit }
    ' "$file"
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

# Set a YAML array field.
# Usage: yaml_set_array "field" "val1,val2" "file"
yaml_set_array() {
    local field="$1" values="$2" file="$3"

    # Remove existing field and its array items
    awk -v f="$field" '
        /^---$/ { n++; if(n==2) { skip=0 } }
        n==1 && $0 ~ "^"f":" { skip=1; next }
        n==1 && skip && /^  - / { next }
        n==1 && skip { skip=0 }
        { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

    # Build the new array block
    local block="${field}:"
    if [ -z "$values" ]; then
        block="${field}: []"
    else
        IFS=',' read -ra items <<< "$values"
        for item in "${items[@]}"; do
            item=$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            block="${block}"$'\n'"  - ${item}"
        done
    fi

    # Insert before closing ---
    awk -v b="$block" '
        /^---$/ { count++ }
        count == 2 && /^---$/ { print b }
        { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
}

# --- ADR file resolution ---

# Find ADR file by numeric ID (handles ADR-XXX or plain number).
# Usage: resolve_adr_file "003" or resolve_adr_file "ADR-003"
resolve_adr_file() {
    local id="$1"
    local id_num id_padded

    # Strip ADR- prefix if present
    id_num=$(echo "$id" | sed 's/^ADR-//')
    # Strip leading zeros for arithmetic, then re-pad
    id_padded=$(printf "%03d" "$((10#$id_num))")

    local file
    file=$(ls -1 "$ADR_DIR"/${id_padded}-*.md 2>/dev/null | head -1)
    echo "$file"
}

# --- ADR numbering ---

# Get next ADR number.
# Usage: next_adr_id
next_adr_id() {
    local highest
    highest=$(ls -1 "$ADR_DIR" 2>/dev/null | \
        grep -E '^[0-9]{3}-' | \
        sed 's/^\([0-9]\{3\}\).*/\1/' | \
        sort -n | \
        tail -1)

    if [ -z "$highest" ]; then
        printf "%03d" 1
    else
        printf "%03d" $((10#$highest + 1))
    fi
}

# --- Slug generation ---

# Generate a kebab-case slug from a title string.
generate_slug() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | sed 's/--*/-/g; s/^-//; s/-$//'
}
