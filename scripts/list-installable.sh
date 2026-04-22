#!/bin/bash
# list-installable.sh — show all skills and hooks that can be installed
# from this repo. No side effects.

source "$(dirname "$0")/_common.sh"

# Extract a field from a markdown file's YAML frontmatter.
# Usage: get_frontmatter_field <file> <field>
get_frontmatter_field() {
    local manifest="$1"
    local field="$2"
    awk '/^---$/{n++; if(n==2) exit; next} n==1{print}' "$manifest" \
        | yq -r ".${field} // \"\"" 2>/dev/null
}

# Extract the first non-blank, non-heading line from a markdown file's body
# (the paragraph after the frontmatter). Used for HOOK.md which keeps its
# description in prose rather than frontmatter.
get_body_description() {
    local manifest="$1"
    awk '
        /^---$/{n++; next}
        n==2 && /^[^#[:space:]]/{print; exit}
    ' "$manifest"
}

# Truncate to fit the terminal nicely.
truncate() {
    local max="$1"
    local text="$2"
    if [ "${#text}" -gt "$max" ]; then
        printf '%s…' "${text:0:$((max - 1))}"
    else
        printf '%s' "$text"
    fi
}

# --- Skills ---
echo "Skills (src/skills/*):"
any_skills=false
for manifest in "$SKILLS_SRC"/*/src/SKILL.md; do
    [ -f "$manifest" ] || continue
    any_skills=true
    name=$(basename "$(dirname "$(dirname "$manifest")")")
    version=$(get_frontmatter_field "$manifest" "version")
    description=$(get_frontmatter_field "$manifest" "description")
    printf "  %-30s %-8s %s\n" "$name" "${version:-?}" "$(truncate 70 "$description")"
done
if ! $any_skills; then
    echo "  (none)"
fi

# --- Hooks ---
echo ""
echo "Hooks (src/hooks/*):"
any_hooks=false
for manifest in "$HOOKS_SRC"/*/HOOK.md; do
    [ -f "$manifest" ] || continue
    any_hooks=true
    name=$(basename "$(dirname "$manifest")")
    version=$(get_frontmatter_field "$manifest" "version")
    description=$(get_body_description "$manifest")
    printf "  %-30s %-8s %s\n" "$name" "${version:-?}" "$(truncate 70 "$description")"
done
if ! $any_hooks; then
    echo "  (none)"
fi

# --- Usage ---
echo ""
echo "Usage:"
echo "  just install <name>       Install a specific skill or hook"
echo "  just install-all          Install everything above"
