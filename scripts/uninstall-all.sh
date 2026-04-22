#!/bin/bash
# Uninstall all skills and hooks.
# Usage: uninstall-all.sh [target]
#   target applies to skills only; hooks are always Claude-only.

source "$(dirname "$0")/_common.sh"

TARGET=$(prompt_target "${1:-prompt}")

# Uninstall all skills
for manifest in "$SKILLS_SRC"/*/src/SKILL.md; do
    [ -f "$manifest" ] || continue
    name=$(basename "$(dirname "$(dirname "$manifest")")")
    "$SCRIPT_DIR/uninstall.sh" "$name" "$TARGET"
done

# Uninstall all hooks
for manifest in "$HOOKS_SRC"/*/HOOK.md; do
    [ -f "$manifest" ] || continue
    name=$(basename "$(dirname "$manifest")")
    "$SCRIPT_DIR/uninstall.sh" "$name"
done
