#!/bin/bash
# Install a skill or hook (auto-detected).
# Usage: install.sh <name> [target]
#   target: claude, gemini, both, or prompt (default: prompt) — only used for skills

source "$(dirname "$0")/_common.sh"

NAME="$1"
TARGET_ARG="${2:-prompt}"
TYPE=$(detect_type "$NAME")
MANIFEST=$(get_manifest "$TYPE" "$NAME")
check_deps "$MANIFEST"
if [ "$TYPE" = "skill" ]; then
    check_requires "$MANIFEST"
fi

if [ "$TYPE" = "skill" ]; then
    TARGET=$(prompt_target "$TARGET_ARG")
    SKILL_SRC_DIR="$SKILLS_SRC/$NAME/src"

    while IFS= read -r SKILLS_HOME; do
        if [ ! -d "$SKILLS_HOME" ]; then
            echo "Note: $SKILLS_HOME does not exist yet — creating it (first-time install)"
            mkdir -p "$SKILLS_HOME"
        fi
        SKILL_DIR="$SKILLS_HOME/$NAME"
        BACKUP_DIR=$(create_backup "install" "$NAME" "$SKILL_DIR")

        OLD_VERSION=""
        if [ -f "$SKILL_DIR/SKILL.md" ]; then
            OLD_VERSION=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$SKILL_DIR/SKILL.md" | yq -r '.version // ""')
        fi
        NEW_VERSION=$(awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$SKILL_SRC_DIR/SKILL.md" | yq -r '.version // ""')

        echo "Installing $NAME to $SKILLS_HOME..."
        rm -rf "$SKILL_DIR/scripts"
        mkdir -p "$SKILL_DIR/scripts"
        cp -r "$SKILL_SRC_DIR/"* "$SKILL_DIR/"

        if [ -n "$OLD_VERSION" ] && [ "$OLD_VERSION" != "$NEW_VERSION" ]; then
            echo "  Updated from $OLD_VERSION to $NEW_VERSION"
        elif [ -n "$OLD_VERSION" ]; then
            echo "  Reinstalled $NEW_VERSION"
        else
            echo "  Installed $NEW_VERSION"
        fi

        print_backup_info "$BACKUP_DIR"
    done < <(resolve_skill_targets "$TARGET")

elif [ "$TYPE" = "hook" ]; then
    HOOK_SRC_DIR="$HOOKS_SRC/$NAME"
    SETTINGS="$CLAUDE_HOME/.claude/settings.json"
    HOOK_DIR="$CLAUDE_HOME/.claude/hooks/$NAME"

    if [ ! -f "$HOOK_SRC_DIR/settings.json" ]; then
        echo "Error: No settings.json found in src/hooks/$NAME/"
        exit 1
    fi
    if [ ! -f "$SETTINGS" ]; then
        echo "Error: $SETTINGS not found"
        echo "  Claude Code may not be set up yet. Run 'claude' first to initialize."
        exit 1
    fi

    # Validate settings.json has the expected hooks structure
    if ! jq -e '.hooks.PreToolUse | type == "array"' "$SETTINGS" &>/dev/null; then
        echo "Error: $SETTINGS is missing a valid .hooks.PreToolUse array"
        echo "  Expected structure: {\"hooks\": {\"PreToolUse\": [...]}}"
        echo "  Please fix settings.json before installing hooks."
        exit 1
    fi

    BACKUP_DIR=$(create_backup "install" "$NAME" "$SETTINGS" "$HOOK_DIR")

    mkdir -p "$HOOK_DIR"
    cp "$HOOK_SRC_DIR"/*.sh "$HOOK_DIR/"
    chmod +x "$HOOK_DIR"/*.sh
    echo "Deployed scripts to $HOOK_DIR/"

    NEW_HOOKS=$(jq '.hooks.PreToolUse' "$HOOK_SRC_DIR/settings.json")
    HOOK_PATH="~/.claude/hooks/$NAME/"

    UPDATED=$(jq --arg hook_path "$HOOK_PATH" --argjson new_hooks "$NEW_HOOKS" '
      .hooks.PreToolUse = [
        .hooks.PreToolUse[] |
        select(
          (.hooks | all(.command | tostring | startswith($hook_path))) | not
        )
      ]
      | .hooks.PreToolUse += $new_hooks
    ' "$SETTINGS")

    echo "$UPDATED" | jq '.' > "$SETTINGS"
    echo "Merged hook config into settings.json"
    echo "Installed $NAME hook."
    print_backup_info "$BACKUP_DIR"
fi
