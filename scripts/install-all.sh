#!/bin/bash
# Install all skills and hooks.
# Usage: install-all.sh [target]
#   target applies to skills only; hooks are always Claude-only.

source "$(dirname "$0")/_common.sh"

TARGET=$(prompt_target "${1:-prompt}")

# Install all skills in two passes so that `requires:` dependencies are
# satisfied: leaves (no requires) first, dependents second.
# Two passes is sufficient for single-level dependency trees; if/when we have
# transitive deps, replace this with a proper topological sort.
_skill_requires_count() {
    awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$1" \
        | yq -r '.requires // [] | length'
}

# Pass 1: skills without requires
for manifest in "$SKILLS_SRC"/*/src/SKILL.md; do
    [ -f "$manifest" ] || continue
    [ "$(_skill_requires_count "$manifest")" -gt 0 ] && continue
    name=$(basename "$(dirname "$(dirname "$manifest")")")
    "$SCRIPT_DIR/install.sh" "$name" "$TARGET"
done

# Pass 2: skills with requires
for manifest in "$SKILLS_SRC"/*/src/SKILL.md; do
    [ -f "$manifest" ] || continue
    [ "$(_skill_requires_count "$manifest")" -eq 0 ] && continue
    name=$(basename "$(dirname "$(dirname "$manifest")")")
    "$SCRIPT_DIR/install.sh" "$name" "$TARGET"
done

# Install all hooks
for manifest in "$HOOKS_SRC"/*/HOOK.md; do
    [ -f "$manifest" ] || continue
    name=$(basename "$(dirname "$manifest")")
    "$SCRIPT_DIR/install.sh" "$name"
done
