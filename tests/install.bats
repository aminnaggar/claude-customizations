#!/usr/bin/env bats

load test_helper

# --- Skill install ---

@test "install auto-detects and installs a skill to claude" {
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
    [ -f "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/SKILL.md" ]
    [ -d "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/scripts" ]
}

@test "install auto-detects and installs a skill to gemini" {
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs gemini
    [ "$status" -eq 0 ]
    [ -f "$CLAUDE_HOME/.gemini/skills/aminnaggar_adrs/SKILL.md" ]
}

@test "install deploys skill to both targets" {
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs both
    [ "$status" -eq 0 ]
    [ -f "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/SKILL.md" ]
    [ -f "$CLAUDE_HOME/.gemini/skills/aminnaggar_adrs/SKILL.md" ]
}

@test "install skill is idempotent" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
    [ -f "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/SKILL.md" ]
}

# --- Hook install ---

@test "install auto-detects and installs a hook" {
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    [ "$status" -eq 0 ]
    [ -d "$CLAUDE_HOME/.claude/hooks/aminnaggar_uv_antipattern" ]
    [ -x "$CLAUDE_HOME/.claude/hooks/aminnaggar_uv_antipattern/block-uv-pip-install.sh" ]
}

@test "install hook merges config into settings.json" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    local count
    count=$(jq '.hooks.PreToolUse | length' "$CLAUDE_HOME/.claude/settings.json")
    [ "$count" -eq 2 ]
}

@test "install hook preserves existing hooks" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    local existing
    existing=$(jq '.hooks.PreToolUse[0].hooks[0].command' "$CLAUDE_HOME/.claude/settings.json")
    [ "$existing" = '"/some/existing-hook.sh"' ]
}

@test "install hook is idempotent" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    local count
    count=$(jq '.hooks.PreToolUse | length' "$CLAUDE_HOME/.claude/settings.json")
    [ "$count" -eq 2 ]
}

# --- Error cases ---

@test "install fails for nonexistent name" {
    run "$PROJECT_ROOT/scripts/install.sh" nonexistent_thing claude
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "install hook fails without settings.json" {
    rm "$CLAUDE_HOME/.claude/settings.json"
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

# --- Guard: settings.json structure ---

@test "install hook fails if settings.json has no PreToolUse array" {
    echo '{"hooks": {}}' > "$CLAUDE_HOME/.claude/settings.json"
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing a valid .hooks.PreToolUse array"* ]]
}

# --- Guard: first-time skill target directory ---

@test "install skill creates target directory if missing" {
    rm -rf "$CLAUDE_HOME/.claude/skills"
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
    [[ "$output" == *"first-time install"* ]]
    [ -f "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/SKILL.md" ]
}

# --- Dependency checking ---

@test "install checks dependencies and fails on missing dep" {
    # Create a fake skill with a dep that doesn't exist
    mkdir -p "$PROJECT_ROOT/src/skills/fake_skill/src/scripts"
    cat > "$PROJECT_ROOT/src/skills/fake_skill/src/SKILL.md" << 'EOF'
---
name: fake_skill
version: 0.1.0
deps: [nonexistent_binary_xyz123]
---
EOF
    run "$PROJECT_ROOT/scripts/install.sh" fake_skill claude
    [ "$status" -eq 1 ]
    [[ "$output" == *"Missing dependencies"* ]]
    [[ "$output" == *"nonexistent_binary_xyz123"* ]]
    [[ "$output" == *"brew install"* ]]
    rm -rf "$PROJECT_ROOT/src/skills/fake_skill"
}

@test "install succeeds when all deps are present" {
    # jq and yq should be installed on this system
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
}

# --- Backup ---

@test "install creates a backup" {
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
    [ -d "$PROJECT_ROOT/backups" ]
    local count
    count=$(find "$PROJECT_ROOT/backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    [ "$count" -eq 1 ]
}

@test "install backup contains previous installation" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    rm -rf "$PROJECT_ROOT/backups"
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    local backup_dir
    backup_dir=$(find "$PROJECT_ROOT/backups" -mindepth 1 -maxdepth 1 -type d | head -1)
    [ -d "$backup_dir/aminnaggar_adrs" ]
}

@test "install output includes restore command" {
    run "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    [[ "$output" == *"To restore:"* ]]
    [[ "$output" == *"just restore"* ]]
}
