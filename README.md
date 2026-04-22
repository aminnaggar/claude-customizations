# Claude Customizations

Monorepo for Claude Code and Gemini CLI customizations — skills, hooks, and other configuration.

## What's in here

### Skills

| Name | Description |
|------|-------------|
| `aminnaggar_adrs` | Manage Architecture Decision Records with auto-syncing summaries to CLAUDE.md |
| `aminnaggar_tickets` | Lightweight file-based ticket management that lives alongside project code |

### Hooks

| Name | Description |
|------|-------------|
| `aminnaggar_uv_antipattern` | Blocks common uv/pip anti-patterns and nudges toward correct `uv` workflow |

## Prerequisites

- [just](https://github.com/casey/just) — task runner
- [jq](https://jqlang.github.io/jq/) — JSON processor
- [yq](https://github.com/mikefarah/yq) — YAML processor
- [bats-core](https://github.com/bats-core/bats-core) — for running tests

```bash
brew install just jq yq bats-core
```

## Usage

```bash
just install <name>             # Install a skill or hook (auto-detected)
just uninstall <name>           # Uninstall a skill or hook
just install-all                # Install all skills and hooks
just uninstall-all              # Uninstall all skills and hooks
```

Skills are deployed to `~/.claude/skills/` and `~/.gemini/skills/`. Hooks are deployed to `~/.claude/hooks/` and configured in `~/.claude/settings.json`.

## Backups

Every destructive operation automatically creates a timestamped backup. If something goes wrong:

```bash
just list-backups               # See what's available
just restore <id>               # Restore from a specific backup
just clear-backups              # Delete all backups
```

## Project Layout

```
src/
  skills/                       # Skill source code
    aminnaggar_adrs/src/
    aminnaggar_tickets/src/
  hooks/                        # Hook source code
    aminnaggar_uv_antipattern/
scripts/                        # Centralized install/uninstall/backup logic
tests/                          # Bats test suite
tickets/                        # Project tickets
adrs/                           # Architecture Decision Records
```

## Testing

```bash
just test
```

## Adding a new skill

1. Create `src/skills/<name>/src/` with a `SKILL.md` manifest
2. Declare dependencies in `SKILL.md` frontmatter: `deps: [jq, yq]`
3. Run `just install <name>`

## Adding a new hook

1. Create `src/hooks/<name>/` with a `HOOK.md` manifest and `settings.json`
2. Declare dependencies in `HOOK.md` frontmatter: `deps: [jq]`
3. Add individual `.sh` scripts for each blocked pattern
4. Run `just install <name>`
