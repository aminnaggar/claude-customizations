#!/bin/bash
# Shared utilities for all deployment scripts.
# Source this file; do not execute directly.

set -euo pipefail

# --- Bootstrap: verify framework-level dependencies ---
# These are required by the scripts themselves, not by individual skills/hooks.
for _dep in jq yq; do
    if ! command -v "$_dep" &>/dev/null; then
        echo "Error: '$_dep' is required but not installed." >&2
        echo "  Install with: brew install $_dep" >&2
        exit 1
    fi
done
unset _dep

# Project root is one level up from this script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configurable home directory for testability (defaults to $HOME)
CLAUDE_HOME="${CLAUDE_HOME:-$HOME}"

BACKUPS_DIR="$PROJECT_ROOT/backups"
SKILLS_SRC="$PROJECT_ROOT/src/skills"
HOOKS_SRC="$PROJECT_ROOT/src/hooks"

# Detect whether a name is a skill or hook.
# Usage: detect_type <name>
# Returns "skill" or "hook" on stdout; exits 1 if not found.
detect_type() {
    local name="$1"
    if [ -d "$SKILLS_SRC/$name" ]; then
        echo "skill"
    elif [ -d "$HOOKS_SRC/$name" ]; then
        echo "hook"
    else
        echo "Error: '$name' not found in src/skills/ or src/hooks/" >&2
        exit 1
    fi
}

# Get the manifest file path for a skill or hook.
# Usage: get_manifest <type> <name>
# Returns the path on stdout; exits 1 if not found.
get_manifest() {
    local type="$1"
    local name="$2"
    local manifest
    if [ "$type" = "skill" ]; then
        manifest="$SKILLS_SRC/$name/src/SKILL.md"
    else
        manifest="$HOOKS_SRC/$name/HOOK.md"
    fi
    if [ ! -f "$manifest" ]; then
        echo "Error: Manifest not found at $manifest" >&2
        exit 1
    fi
    echo "$manifest"
}

# Check that all declared dependencies are available on PATH.
# Usage: check_deps <manifest_path>
# Exits 1 with guidance if any are missing.
check_deps() {
    local manifest="$1"
    # Extract deps array from YAML frontmatter
    local deps
    deps=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$manifest" \
        | yq -r '.deps // [] | .[]' 2>/dev/null)

    if [ -z "$deps" ]; then
        return 0
    fi

    local missing=()
    while IFS= read -r dep; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done <<< "$deps"

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing dependencies:" >&2
        for dep in "${missing[@]}"; do
            echo "  - $dep (install with: brew install $dep)" >&2
        done
        exit 1
    fi
}

# Check that all required sibling skills are installed.
# Usage: check_requires <manifest_path>
# Exits 1 with guidance if any are missing from $CLAUDE_HOME/.claude/skills/.
check_requires() {
    local manifest="$1"
    local requires
    requires=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$manifest" \
        | yq -r '.requires // [] | .[]' 2>/dev/null)

    if [ -z "$requires" ]; then
        return 0
    fi

    local missing=()
    while IFS= read -r required; do
        # A required skill is considered installed if its directory exists in
        # $CLAUDE_HOME/.claude/skills/. We don't yet check the gemini side —
        # add a parallel check there if/when sibling-skill deps land for gemini.
        if [ ! -d "$CLAUDE_HOME/.claude/skills/$required" ]; then
            missing+=("$required")
        fi
    done <<< "$requires"

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Error: Missing required skills:" >&2
        for required in "${missing[@]}"; do
            echo "  - $required (install with: just install $required)" >&2
        done
        exit 1
    fi
}

# Prompt user to select a target CLI (claude, gemini, or both)
# Usage: prompt_target [default_target]
#   If default_target is "prompt" or empty, shows interactive menu.
#   Otherwise uses the value directly.
prompt_target() {
    local target="${1:-prompt}"
    if [ "$target" = "prompt" ]; then
        echo "Which CLI do you want to target?" >&2
        echo "1) Claude Code (~/.claude/skills)" >&2
        echo "2) Gemini CLI (~/.gemini/skills)" >&2
        echo "3) Both" >&2
        read -p "Select an option [1-3] (default: 3): " opt >&2
        case ${opt:-3} in
            1) target="claude" ;;
            2) target="gemini" ;;
            3) target="both" ;;
            *) echo "Invalid option" >&2; exit 1 ;;
        esac
    fi
    echo "$target"
}

# Resolve target CLI directories based on target selection
# Usage: resolve_skill_targets <target>
# Returns newline-separated list of skill home directories
resolve_skill_targets() {
    local target="$1"
    if [ "$target" = "claude" ] || [ "$target" = "both" ]; then
        echo "$CLAUDE_HOME/.claude/skills"
    fi
    if [ "$target" = "gemini" ] || [ "$target" = "both" ]; then
        echo "$CLAUDE_HOME/.gemini/skills"
    fi
}

# Create a timestamped backup of given paths.
# Usage: create_backup <operation> <target> <path1> [path2 ...]
# Returns the backup directory path on stdout.
create_backup() {
    local operation="$1"
    local target="$2"
    shift 2

    local timestamp
    timestamp=$(date +%Y-%m-%d_%H%M%S)
    local backup_name="${timestamp}_${operation}_${target}"
    local backup_dir="$BACKUPS_DIR/$backup_name"
    mkdir -p "$backup_dir"

    local manifest_entries=()
    for path in "$@"; do
        local bname
        bname=$(basename "$path")
        if [ -e "$path" ]; then
            if [ -d "$path" ]; then
                cp -r "$path" "$backup_dir/$bname"
            else
                cp "$path" "$backup_dir/$bname"
            fi
            manifest_entries+=("{\"source\": \"$path\", \"local\": \"$bname\", \"existed\": true}")
        else
            manifest_entries+=("{\"source\": \"$path\", \"local\": \"$bname\", \"existed\": false}")
        fi
    done

    # Build manifest
    local entries
    if [ ${#manifest_entries[@]} -eq 0 ]; then
        entries="[]"
    else
        entries=$(printf '%s\n' "${manifest_entries[@]}" | jq -s '.')
    fi
    jq -n \
        --arg op "$operation" \
        --arg tgt "$target" \
        --arg ts "$timestamp" \
        --argjson backed_up "$entries" \
        '{operation: $op, target: $tgt, timestamp: $ts, backed_up: $backed_up}' \
        > "$backup_dir/manifest.json"

    echo "$backup_dir"
}

# Print backup summary after an operation
print_backup_info() {
    local backup_dir="$1"
    local backup_name
    backup_name=$(basename "$backup_dir")
    echo ""
    echo "Backup saved to $backup_dir/"
    echo "To restore:  just restore $backup_name"
}
