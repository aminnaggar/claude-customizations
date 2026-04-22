---
name: adrs
version: 0.2.0
deps: [jq, yq]
description: Manage Architecture Decision Records with auto-syncing summaries to CLAUDE.md. Use when user discusses architectural decisions, technology choices, or says "/adr".
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
---

# ADR Management

## Commands (run directly, do not search)

| Action | Run exactly |
|--------|-------------|
| create ADR | `~/.claude/skills/aminnaggar_adrs/scripts/create.sh "<title>"` |
| list / filter | `~/.claude/skills/aminnaggar_adrs/scripts/list-adrs.sh [filter]` |
| show full ADR | `~/.claude/skills/aminnaggar_adrs/scripts/show-adr.sh <id>` |
| search | `~/.claude/skills/aminnaggar_adrs/scripts/search-adrs.sh "query"` |
| summaries | `~/.claude/skills/aminnaggar_adrs/scripts/summary-adrs.sh` |
| set status | `~/.claude/skills/aminnaggar_adrs/scripts/set-status.sh <id> <status>` |
| delete proposed ADR | `~/.claude/skills/aminnaggar_adrs/scripts/safe-delete.sh <id>` |
| sync to CLAUDE.md | `~/.claude/skills/aminnaggar_adrs/scripts/sync-claude-md.sh` |
| skill version | Read SKILL.md frontmatter `version` field |

**Filters for list**: `active` (default), `all`, `proposed`, `accepted`, `deprecated`, `superseded`

All scripts default to `$PWD/adrs/`. Override with `-p <path>` or the `ADR_PATH` env var.

**Do not search or glob for ADR files.** Scripts provide compact output.
Only read individual ADR files when detailed content is needed (rationale, consequences).

## Creating an ADR

```bash
~/.claude/skills/aminnaggar_adrs/scripts/create.sh "<title>"
```

The script lists existing ADRs (for conflict/supersession context), creates the ID, and outputs a template. After running the script, use the **Write** tool to create the ADR file at the path shown in the output — the file does not exist yet, so do not use Read or Edit.

**Principle**: Infer everything from conversation context. Only ask the user for judgment calls (context-critical? supersedes another ADR?).

To supersede existing ADRs at creation time:

```bash
~/.claude/skills/aminnaggar_adrs/scripts/create.sh -s ADR-001,ADR-003 "<title>"
```

The `-s` flag updates the old ADRs' status and `superseded_by` field automatically.

## Setting Status

```bash
~/.claude/skills/aminnaggar_adrs/scripts/set-status.sh <id> <status>
```

Valid statuses: `proposed`, `accepted`, `deprecated`

For supersession, use `create.sh -s` instead — supersession is a creation-time decision.

## Deleting an ADR

```bash
~/.claude/skills/aminnaggar_adrs/scripts/safe-delete.sh <id>
```

Only proposed ADRs can be deleted. If the ADR superseded others, those changes are reversed.

## Syncing to CLAUDE.md

```bash
~/.claude/skills/aminnaggar_adrs/scripts/sync-claude-md.sh
```

Outputs the `## ADRs` section content. Find the `## ADRs` section in the project's CLAUDE.md and replace everything under that header until the next `##` or EOF. If no section exists, add it at the end.

## Context-Critical Criteria

Set `context-critical: true` when:
- Non-obvious technology/library choice (would Claude suggest differently?)
- Contradicts common conventions or defaults
- Reversing would require significant refactoring
- External constraints not visible in code (regulatory, business, API limitations)

NOT context-critical: standard best practices, decisions obvious from reading the code, minor implementation details.

## Configuration

Set in your project's `.claude/settings.json`:

```json
{
  "env": {
    "ADR_PATH": "/path/to/adrs"
  }
}
```

| Variable | Values | Default |
|----------|--------|---------|
| `ADR_PATH` | Path to ADRs directory | `$PWD/adrs/` |

## Conventions

- IDs: `ADR-001`, `ADR-002`, etc.
- Filenames: `{NNN}-{kebab-case-title}.md`
- Status lifecycle: `proposed` → `accepted` → `deprecated` or `superseded`
- `supersedes` is an array (can replace multiple ADRs)
- `superseded_by` is singular (only one ADR can replace this one)
- **Never** use mkdir, rm, or other filesystem operations for ADR management — use the scripts

For ADR format specification, see [reference.md](reference.md).
