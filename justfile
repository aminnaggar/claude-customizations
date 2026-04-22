# Claude & Gemini Customizations

# Default recipe - show available commands
default:
    @just --list

# Install a skill or hook by name (auto-detected)
install name target="prompt":
    ./scripts/install.sh "{{name}}" "{{target}}"

# Uninstall a skill or hook by name (auto-detected)
uninstall name target="prompt":
    ./scripts/uninstall.sh "{{name}}" "{{target}}"

# Install all skills and hooks
install-all target="prompt":
    ./scripts/install-all.sh "{{target}}"

# Uninstall all skills and hooks
uninstall-all target="prompt":
    ./scripts/uninstall-all.sh "{{target}}"

# Restore from a backup
restore backup:
    ./scripts/restore.sh "{{backup}}"

# List all skills, hooks, and git hooks that can be installed from this repo
list-installable:
    ./scripts/list-installable.sh

# List available backups
list-backups:
    ./scripts/list-backups.sh

# Clear all backups
clear-backups:
    ./scripts/clear-backups.sh

# Run tests
test:
    bats tests/
