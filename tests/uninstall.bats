#!/usr/bin/env bats

load test_helper

# --- Skill uninstall ---

@test "uninstall removes a skill" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    rm -rf "$PROJECT_ROOT/backups"
    run "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
    [ ! -d "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs" ]
}

@test "uninstall skill handles not-installed gracefully" {
    run "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_adrs claude
    [ "$status" -eq 0 ]
    [[ "$output" == *"Not installed"* ]]
}

@test "uninstall skill creates backup" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    rm -rf "$PROJECT_ROOT/backups"
    "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_adrs claude
    local backup_dir
    backup_dir=$(find "$PROJECT_ROOT/backups" -mindepth 1 -maxdepth 1 -type d | head -1)
    [ -d "$backup_dir/aminnaggar_adrs" ]
}

# --- Hook uninstall ---

@test "uninstall removes a hook's scripts" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    rm -rf "$PROJECT_ROOT/backups"
    run "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_uv_antipattern
    [ "$status" -eq 0 ]
    [ ! -d "$CLAUDE_HOME/.claude/hooks/aminnaggar_uv_antipattern" ]
}

@test "uninstall removes hook config from settings.json" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    rm -rf "$PROJECT_ROOT/backups"
    "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_uv_antipattern
    local count
    count=$(jq '.hooks.PreToolUse | length' "$CLAUDE_HOME/.claude/settings.json")
    [ "$count" -eq 1 ]
}

@test "uninstall hook preserves unrelated hooks" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    rm -rf "$PROJECT_ROOT/backups"
    "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_uv_antipattern
    local existing
    existing=$(jq '.hooks.PreToolUse[0].hooks[0].command' "$CLAUDE_HOME/.claude/settings.json")
    [ "$existing" = '"/some/existing-hook.sh"' ]
}

@test "uninstall hook creates backup" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    rm -rf "$PROJECT_ROOT/backups"
    "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_uv_antipattern
    local backup_dir
    backup_dir=$(find "$PROJECT_ROOT/backups" -mindepth 1 -maxdepth 1 -type d | head -1)
    [ -f "$backup_dir/settings.json" ]
    [ -d "$backup_dir/aminnaggar_uv_antipattern" ]
}

@test "uninstall hook handles not-installed gracefully" {
    run "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_uv_antipattern
    [ "$status" -eq 0 ]
    [[ "$output" == *"No scripts found"* ]]
}

# --- Output ---

@test "uninstall output includes restore command" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    rm -rf "$PROJECT_ROOT/backups"
    run "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_adrs claude
    [[ "$output" == *"To restore:"* ]]
    [[ "$output" == *"just restore"* ]]
}
