# ADR Skill - Development

Development workspace for the Claude Code ADR (Architecture Decision Records) skill.

## Project Structure

```
aminnaggar_adrs/
├── CLAUDE.md           # This file - dev instructions
├── src/                # Deployable skill files
│   ├── SKILL.md        # Main skill definition (triggers, instructions)
│   ├── reference.md    # ADR format specification
│   ├── .templates/
│   │   └── ADR.template.md
│   └── scripts/        # Helper scripts
│       ├── _common.sh      # Shared utilities (YAML helpers, dir resolution, numbering)
│       ├── create.sh       # Create a new ADR (with optional supersession)
│       ├── list-adrs.sh    # List ADRs with status filter
│       ├── show-adr.sh     # Show full ADR content
│       ├── search-adrs.sh  # Search ADRs by content/tags
│       ├── summary-adrs.sh # Active ADR summaries
│       ├── set-status.sh   # Change ADR status
│       ├── safe-delete.sh  # Delete proposed ADRs (reverses supersession)
│       └── sync-claude-md.sh # Output CLAUDE.md ADRs section
└── .claude/
    └── settings.local.json
```

## About the Skill

A two-tier ADR management skill that balances context efficiency with decision traceability.

**Philosophy**: Scripts own all side effects and make them reversible; the agent owns content only (ADR-003). Every mutating script outputs decision context + undo command in a single invocation.

**Status workflow**: `proposed` → `accepted` → `deprecated`/`superseded`

**Key features**:
- Auto-numbered ADRs (001, 002...) with kebab-case filenames
- `context-critical: true` flag to mark ADRs for CLAUDE.md surfacing
- Supersession handled at creation time (`create.sh -s`)
- `/adr sync` regenerates the CLAUDE.md summary section
- No external dependencies (no `yq` -- uses grep/sed YAML helpers)
- Scripts enforce consistency and minimize context consumption

**CLAUDE.md section format**:
```markdown
## ADRs

- ORM: Drizzle over Prisma for edge compatibility - ADR-012
- Auth: Custom JWT, not Auth0 - ADR-015
```

See `src/SKILL.md` for full skill instructions and `src/reference.md` for the ADR format spec.

## ADRs

- Skill ID: Use directory name (aminnaggar_adrs) instead of frontmatter id field - ADR-001
- Versioning: Add version field to SKILL.md frontmatter for discoverability - ADR-002
