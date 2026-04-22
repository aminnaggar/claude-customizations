#!/bin/bash
# Shared test setup/teardown for all bats test files.

# Create a sandboxed fake home directory for each test
setup() {
    export CLAUDE_HOME="$(mktemp -d)"
    mkdir -p "$CLAUDE_HOME/.claude/skills"
    mkdir -p "$CLAUDE_HOME/.claude/hooks"
    mkdir -p "$CLAUDE_HOME/.gemini/skills"

    # Create a minimal settings.json with existing hooks
    cat > "$CLAUDE_HOME/.claude/settings.json" << 'SETTINGS'
{
  "permissions": {
    "allow": []
  },
  "hooks": {
    "PreToolUse": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/some/existing-hook.sh",
            "timeout": 5,
            "async": true
          }
        ]
      }
    ]
  }
}
SETTINGS

    # Track the project root
    export PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

    # Clean any backups from prior test runs
    rm -rf "$PROJECT_ROOT/backups"
}

teardown() {
    rm -rf "$CLAUDE_HOME"
    rm -rf "$PROJECT_ROOT/backups"
}
