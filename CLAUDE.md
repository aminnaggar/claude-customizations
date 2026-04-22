# Claude Customizations

Monorepo for Claude Code and Gemini CLI customizations — skills, hooks, and other configuration.

## Project Layout

- **Skills:** Source code lives in `src/skills/<skill_name>/src/`. The installed (runtime) copy lives at `~/.claude/skills/` and `~/.gemini/skills/`. Never edit the installed copy directly; work here, then deploy.
- **Hooks:** Hook definitions and supporting scripts live in `src/hooks/<hook_name>/`.
- **Tickets:** Project tickets live in `tickets/` at the repo root.
- **ADRs:** Architecture Decision Records live in `adrs/` at the repo root.

## Deploying

Use the justfile. `just install` auto-detects whether a name is a skill or hook:

```bash
just install <name>             # Install a skill or hook (auto-detected)
just uninstall <name>           # Uninstall a skill or hook
just install-all                # Install all skills and hooks
just uninstall-all              # Uninstall all skills and hooks
just list-backups               # List available backups
just restore <id>               # Restore from a backup
just test                       # Run bats test suite
```

Every destructive operation creates a timestamped backup with a one-liner restore command.

## Hook Conventions

- Use `if` filters in settings.json to prevent unnecessary process spawning — don't match inside the script.
- Create **separate handlers per pattern** with specific messages, not one monolithic script.
- Each hook script should be minimal: echo a corrective message to stderr and `exit 2` to block.
- Deploy hook scripts to `~/.claude/hooks/<hook_name>/`.

## ADRs

- Skill ID: Use directory name (aminnaggar_adrs) instead of frontmatter id field - ADR-001
- Versioning: Add version field to SKILL.md frontmatter for discoverability - ADR-002
- Skills: Scripts own side effects and make them reversible; agent owns content only - ADR-003
- Install logic is centralized in scripts/; skills and hooks declare dependencies in their manifests (SKILL.md / HOOK.md) rather than owning install logic - ADR-004
