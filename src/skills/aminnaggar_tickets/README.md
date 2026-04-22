# Tickets Skill

A Claude Code skill for lightweight, file-based ticket management.

## Why?

Most ticket systems are overkill for solo projects or small teams. They live in a browser, require accounts, and separate your task tracking from your code.

This skill takes a different approach: tickets are markdown files that live in your project's `tickets/` directory. They're human-readable, git-tracked, and always where your code is.

## Philosophy

- **File-based**: Markdown with YAML frontmatter. No database, no server, no account.
- **Collocated**: Tickets live in the project they belong to.
- **Portable**: Relative paths mean you can move or copy projects freely.
- **Minimal**: Four statuses (`draft` → `todo` → `current` → `done`). Nothing more.

## How It Works

Ask Claude to manage your tickets:

- "Add a ticket for user authentication"
- "What tickets are open?"
- "Mark ticket 007 as done"
- "Show me tickets related to database"

Claude creates and manages `tickets/` in your project with a clean directory structure, proper numbering, and consistent formatting.

## Installation

```bash
just install
```

To uninstall:

```bash
just uninstall
```

## Documentation

- [SKILL.md](src/SKILL.md) - Full skill instructions
- [reference.md](src/reference.md) - Ticket format specification
