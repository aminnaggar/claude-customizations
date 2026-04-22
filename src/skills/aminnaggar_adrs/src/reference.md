# ADR Format Reference

## Directory Structure

```
adrs/
├── 001-use-drizzle-orm.md
├── 002-grpc-internal-rest-edge.md
└── 003-custom-jwt-auth.md
```

## Filename Convention

Pattern: `{NNN}-{kebab-case-title}.md`

- Three-digit zero-padded number
- Kebab-case title (lowercase, hyphens)
- `.md` extension

Examples:
- `001-use-drizzle-orm.md`
- `012-grpc-internal-rest-edge.md`

## Frontmatter Schema

```yaml
---
id: ADR-003
title: "Short descriptive title"
date: 2026-01-28
status: proposed

supersedes: []
superseded_by: null

tags:
  - architecture
  - grpc
  - gateway
deciders:
  - Name

context-critical: false
summary: "ORM: Drizzle for edge compatibility"
---
```

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Format: `ADR-{NNN}`, must match filename number |
| `title` | string | Short descriptive title, 50 chars max |
| `date` | date | `YYYY-MM-DD` format |
| `status` | enum | `proposed`, `accepted`, `deprecated`, or `superseded` |

### Optional Fields

| Field | Type | When Used |
|-------|------|-----------|
| `supersedes` | list | Array of ADR IDs this replaces (set via `create.sh -s`) |
| `superseded_by` | string | ADR ID that replaced this one (set automatically) |
| `tags` | list | Categorization: component, domain, technology |
| `deciders` | list | Who made the decision |
| `context-critical` | boolean | `true` = surface in CLAUDE.md via `/adr sync` |
| `summary` | string | One-liner for CLAUDE.md display. **Required** when `context-critical: true`. Format: "Domain: Decision" |

## Body Structure

```markdown
# Title

## Context
What's the situation? What problem are we solving?
(3-5 sentences)

## Decision
We will [do X].
(1 sentence - clear, decisive)

## Rationale
Why this decision?
- Reason 1
- Reason 2
- Reason 3

## Consequences

### Positive
- What we gain

### Negative
- What we sacrifice

### Neutral
- What changes (neither good nor bad)

## Alternatives Considered

### Option A: [Name]
- Why considered
- Why rejected
```

## Status Lifecycle

```
proposed ──► accepted ──► deprecated
                    └──► superseded (via create.sh -s)
```

When superseding (handled by `create.sh -s`):
1. New ADR created with `supersedes: [ADR-XXX]`
2. Old ADR updated: `status: superseded`, `superseded_by: ADR-YYY`

When undoing (`safe-delete.sh`):
1. New ADR deleted
2. Old ADRs restored: `status: accepted`, `superseded_by` removed

## Tags

Three categories:
- **component**: Which part of the system (gateway, auth, api)
- **domain**: What kind of decision (architecture, security, performance)
- **technology**: What tech is involved (grpc, kubernetes, python)
