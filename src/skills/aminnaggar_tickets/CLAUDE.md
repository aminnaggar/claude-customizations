# Tickets Skill - Development

Development workspace for the Claude Code tickets skill.

## Project Structure

```
aminnaggar_tickets/
├── CLAUDE.md           # This file - dev instructions
├── README.md           # Public-facing docs
├── src/                # Deployable skill files
│   ├── SKILL.md        # Main skill definition (triggers, instructions)
│   ├── reference.md    # Ticket format specification
│   └── scripts/        # Helper scripts
│       ├── _common.sh      # Shared utilities (YAML helpers, dir resolution, numbering)
│       ├── create.sh       # Create a new ticket
│       ├── find.sh         # Search tickets
│       ├── list.sh         # List tickets with status
│       ├── safe-delete.sh  # Delete draft tickets
│       └── set-status.sh   # Change ticket status
└── .claude/
    └── settings.local.json
```

## About the Skill

A lightweight, file-based ticket management skill that lives alongside project code.

**Philosophy**: Simple over complex - markdown files with YAML frontmatter, git-friendly, no database.

**Status workflow**: `draft` → `todo` → `current` → `done`

**Key features**:
- Auto-numbered tickets (001, 002...) with sub-tickets (005a, 005b...)
- Dependencies and references via relative paths
- Scripts enforce consistency (status values, `completed` field format)
- List filtering: `open` (not done), `closed` (done), or specific status
- Auto-discovery of tickets directory (`$PWD/tickets/` by default)

See `src/SKILL.md` for full skill instructions and `src/reference.md` for the ticket format spec.
