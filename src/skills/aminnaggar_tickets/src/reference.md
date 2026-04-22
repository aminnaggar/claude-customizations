# Ticket Format Reference

## Directory Structure

Default (`TICKET_FILENAME` unset or `default`):
```
tickets/
├── 001_requirements_forming/
│   ├── ticket.md
│   └── artifacts/
│       └── design.pdf
├── 005a_outcomes/           # sub-ticket of 005
│   └── ticket.md
└── 006_mock_database/
    └── ticket.md
```

With `TICKET_FILENAME=id_prefix` (for Obsidian compatibility):
```
tickets/
├── 001_requirements_forming/
│   ├── 001_ticket.md
│   └── artifacts/
│       └── design.pdf
├── 005a_outcomes/           # sub-ticket of 005
│   └── 005a_ticket.md
└── 006_mock_database/
    └── 006_ticket.md
```

## Directory Naming

- Main tickets: `{NNN}_{slug}/` (e.g., `007_realistic_mock_data/`)
- Sub-tickets: `{NNN}{letter}_{slug}/` (e.g., `005a_outcomes/`)
- Slug: lowercase, underscores, no spaces

## Ticket File Frontmatter

```yaml
---
id: "007"
title: "Realistic Mock Data Generation"
description: Generate comprehensive, realistic mock data based on real-world service schedules.
status: done
created: 2026-01-16
completed: 2026-01-16
depends_on:
  - '../006_mock_database/ticket.md'
parent: '../005_phase3_orchestrator/ticket.md'
references:
  - './service_schedules_reference.md'
  - '../001_requirements_forming/portal_design_plan_v3_amin.md#section-name'
---
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Matches directory prefix: `"007"` or `"005a"` |
| `title` | string | Human-readable title |
| `description` | string | One-line summary |
| `status` | enum | `draft`, `todo`, `current`, or `done` |
| `created` | date | `YYYY-MM-DD` format |

### Optional Fields

| Field | Type | When Used |
|-------|------|-----------|
| `completed` | date | Only when `status: done` |
| `depends_on` | list | Relative paths to dependency ticket files |
| `parent` | string | Relative path to parent ticket file (sub-tickets only) |
| `references` | list | Relative paths to related files, can include `#anchor` |

## Ticket File Body Structure

```markdown
---
[frontmatter]
---

# {Title}

## Objective

What this ticket aims to accomplish.

## Context

Background information, links to designs, etc.

## Acceptance Criteria

- [ ] First criterion
- [ ] Second criterion
- [ ] Third criterion

## Notes

Additional information, decisions made, etc.
```

## Reference Path Conventions

All paths in `depends_on`, `parent`, and `references` are **relative paths** from the ticket directory:

```yaml
# Default mode (from 007_realistic_mock_data/ticket.md):
depends_on:
  - '../006_mock_database/ticket.md'        # sibling ticket
references:
  - './service_schedules_reference.md'       # file in same directory
  - '../001_requirements_forming/design.md#wireframes'  # with anchor

# id_prefix mode (from 007_realistic_mock_data/007_ticket.md):
depends_on:
  - '../006_mock_database/006_ticket.md'    # sibling ticket
```

## Status Transitions

```
draft ──────► todo ──────► current ──────► done
                ▲                            │
                └────────────────────────────┘
                     (can reopen if needed)
```

When transitioning to `done`:
- Add `completed: YYYY-MM-DD`

When transitioning from `done`:
- Remove `completed` field

## ID Numbering

- Main tickets: sequential integers, zero-padded to 3 digits (`001`, `002`, ..., `099`, `100`)
- Sub-tickets: parent number + lowercase letter (`005a`, `005b`, `005c`)
- Letters continue: a-z (26 sub-tickets per parent should be plenty)
