---
name: tickets
version: 0.5.1
deps: [jq, yq]
description: Manage project tickets via helper scripts - list, create, find, set status. Use when user mentions tickets. Run scripts directly; never search or glob for ticket.md files.
allowed-tools:
  - Read
  - Write
  - Bash
---

# Ticket Management

## Commands (run directly, do not search)

| Action | Run exactly |
|--------|-------------|
| create ticket | `~/.claude/skills/aminnaggar_tickets/scripts/create.sh "<title>"` |
| list / status / open | `~/.claude/skills/aminnaggar_tickets/scripts/list.sh [filter]` |
| find / search | `~/.claude/skills/aminnaggar_tickets/scripts/find.sh "query"` |
| set status / mark done | `~/.claude/skills/aminnaggar_tickets/scripts/set-status.sh <id> <status>` |
| delete draft ticket | `~/.claude/skills/aminnaggar_tickets/scripts/safe-delete.sh <id>` |
| skill version | Read SKILL.md frontmatter `version` field |

**Filters**: `draft`, `todo`, `current`, `done`, `open` (not done), `closed` (done)

All scripts default to `$PWD/tickets/`. Override with `-p <path>` or the `TICKETS_PATH` env var.

**Do not search or glob for ticket files.** Scripts provide compact output.
Only read individual ticket files when detailed content is needed (acceptance criteria, notes).

## Creating a Ticket

```bash
~/.claude/skills/aminnaggar_tickets/scripts/create.sh "<title>"
```

The script creates the directory and outputs a template. Keep titles concise (3-6 words). After running the script, use the **Write** tool to create the ticket file at the path shown in the output — the file does not exist yet, so do not use Read or Edit. Fill in description and acceptance criteria in the content you write.

For sub-tickets, use `-s <parent_id>`:

```bash
~/.claude/skills/aminnaggar_tickets/scripts/create.sh -s 005 "<title>"
```

## Setting Status

```bash
~/.claude/skills/aminnaggar_tickets/scripts/set-status.sh <id> <status>
```

Valid statuses: `draft`, `todo`, `current`, `done`

The script automatically manages the `completed` date field.

## Deleting a Ticket

```bash
~/.claude/skills/aminnaggar_tickets/scripts/safe-delete.sh <id>
```

Only draft tickets can be deleted. The script will tell you how to proceed if the ticket is not in draft status.

## Configuration

Set in your project's `.claude/settings.json`:

```json
{
  "env": {
    "TICKETS_PATH": "/path/to/tickets",
    "TICKET_FILENAME": "id_prefix"
  }
}
```

| Variable | Values | Default |
|----------|--------|---------|
| `TICKETS_PATH` | Path to tickets directory | `$PWD/tickets/` |
| `TICKET_FILENAME` | `default`, `id_prefix` | `default` |

- `default` → `ticket.md`
- `id_prefix` → `{id}_ticket.md` (e.g., `007_ticket.md`) — for Obsidian compatibility

## Conventions

- Cross-references use **relative paths** to ticket files
- IDs are strings: `"007"` for main, `"005a"` for sub-tickets
- **Status values**: `draft`, `todo`, `current`, `done` only
- **Completion field**: `completed` only (not "completed_at", "implemented", etc.)
- Dates: `YYYY-MM-DD`
- **Never** use mkdir, rm, or other filesystem operations for ticket management — use the scripts

For ticket format specification, see [reference.md](reference.md).
