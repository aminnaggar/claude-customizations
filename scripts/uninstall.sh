#!/bin/bash
# Uninstall a skill or hook (auto-detected).
# Usage: uninstall.sh <name> [target]
#   target: claude, gemini, both, or prompt (default: prompt) — only used for skills

source "$(dirname "$0")/_common.sh"

NAME="$1"
TARGET_ARG="${2:-prompt}"
TYPE=$(detect_type "$NAME")

if [ "$TYPE" = "skill" ]; then
    TARGET=$(prompt_target "$TARGET_ARG")

    while IFS= read -r SKILLS_HOME; do
        SKILL_DIR="$SKILLS_HOME/$NAME"
        if [ -d "$SKILL_DIR" ]; then
            BACKUP_DIR=$(create_backup "uninstall" "$NAME" "$SKILL_DIR")
            rm -rf "$SKILL_DIR"
            echo "Uninstalled $NAME from $SKILLS_HOME"
            print_backup_info "$BACKUP_DIR"
        else
            echo "Not installed at $SKILLS_HOME"
        fi
    done < <(resolve_skill_targets "$TARGET")

elif [ "$TYPE" = "hook" ]; then
    SETTINGS="$CLAUDE_HOME/.claude/settings.json"
    HOOK_DIR="$CLAUDE_HOME/.claude/hooks/$NAME"
    HOOK_PATH="~/.claude/hooks/$NAME/"

    BACKUP_DIR=$(create_backup "uninstall" "$NAME" "$SETTINGS" "$HOOK_DIR")

    if [ -d "$HOOK_DIR" ]; then
        rm -rf "$HOOK_DIR"
        echo "Removed scripts from $HOOK_DIR"
    else
        echo "No scripts found at $HOOK_DIR"
    fi

    if [ -f "$SETTINGS" ] && jq -e '.hooks.PreToolUse | type == "array"' "$SETTINGS" &>/dev/null; then
        UPDATED=$(jq --arg hook_path "$HOOK_PATH" '
          .hooks.PreToolUse = [
            .hooks.PreToolUse[] |
            select(
              (.hooks | all(.command | tostring | startswith($hook_path))) | not
            )
          ]
        ' "$SETTINGS")
        echo "$UPDATED" | jq '.' > "$SETTINGS"
        echo "Removed hook config from settings.json"
    fi

    echo "Uninstalled $NAME hook."
    print_backup_info "$BACKUP_DIR"
fi
