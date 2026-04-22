#!/usr/bin/env bats

load test_helper

@test "restore reverses a skill install" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    local backup_name
    backup_name=$(ls "$PROJECT_ROOT/backups" | head -1)

    [ -f "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/SKILL.md" ]

    run "$PROJECT_ROOT/scripts/restore.sh" "$backup_name"
    [ "$status" -eq 0 ]
    [ ! -d "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs" ]
}

@test "restore reverses a hook install" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    local backup_name
    backup_name=$(ls "$PROJECT_ROOT/backups" | head -1)

    [ -d "$CLAUDE_HOME/.claude/hooks/aminnaggar_uv_antipattern" ]
    local count
    count=$(jq '.hooks.PreToolUse | length' "$CLAUDE_HOME/.claude/settings.json")
    [ "$count" -eq 2 ]

    run "$PROJECT_ROOT/scripts/restore.sh" "$backup_name"
    [ "$status" -eq 0 ]
    count=$(jq '.hooks.PreToolUse | length' "$CLAUDE_HOME/.claude/settings.json")
    [ "$count" -eq 1 ]
}

@test "restore reverses a skill uninstall" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    rm -rf "$PROJECT_ROOT/backups"

    "$PROJECT_ROOT/scripts/uninstall.sh" aminnaggar_adrs claude
    local backup_name
    backup_name=$(ls "$PROJECT_ROOT/backups" | head -1)

    [ ! -d "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs" ]

    run "$PROJECT_ROOT/scripts/restore.sh" "$backup_name"
    [ "$status" -eq 0 ]
    [ -f "$CLAUDE_HOME/.claude/skills/aminnaggar_adrs/SKILL.md" ]
}

@test "restore fails for nonexistent backup" {
    run "$PROJECT_ROOT/scripts/restore.sh" "nonexistent_backup"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Backup not found"* ]]
}

@test "list-backups shows available backups" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    run "$PROJECT_ROOT/scripts/list-backups.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"aminnaggar_adrs"* ]]
}

@test "list-backups handles no backups" {
    run "$PROJECT_ROOT/scripts/list-backups.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No backups found"* ]]
}

@test "clear-backups removes all backups" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_adrs claude
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern

    run "$PROJECT_ROOT/scripts/clear-backups.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Cleared 2 backup(s)"* ]]
    [ -z "$(ls -A "$PROJECT_ROOT/backups" 2>/dev/null)" ]
}

@test "clear-backups handles no backups" {
    run "$PROJECT_ROOT/scripts/clear-backups.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"No backups to clear"* ]]
}

@test "backup manifest contains correct metadata" {
    "$PROJECT_ROOT/scripts/install.sh" aminnaggar_uv_antipattern
    local backup_dir
    backup_dir=$(find "$PROJECT_ROOT/backups" -mindepth 1 -maxdepth 1 -type d | head -1)

    local operation
    operation=$(jq -r '.operation' "$backup_dir/manifest.json")
    [ "$operation" = "install" ]

    local target
    target=$(jq -r '.target' "$backup_dir/manifest.json")
    [ "$target" = "aminnaggar_uv_antipattern" ]

    local count
    count=$(jq '.backed_up | length' "$backup_dir/manifest.json")
    [ "$count" -ge 1 ]
}
