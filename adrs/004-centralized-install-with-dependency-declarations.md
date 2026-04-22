---
id: ADR-004
title: "Centralized install with dependency declarations"
date: 2026-04-08
status: accepted

supersedes: []
superseded_by: null

tags:
  - deployment
  - architecture
deciders:
  - Amin

context-critical: true
summary: "Install logic is centralized in scripts/; skills and hooks declare dependencies in their manifests (SKILL.md / HOOK.md) rather than owning install logic"
---

# Centralized install with dependency declarations

## Context

As the repo grew from skills-only to include hooks and other customizations, we needed to decide who owns the install/uninstall logic. Three approaches were considered:

1. **Centralized** — `scripts/` owns all install logic. Every skill/hook installs the same way.
2. **Spoke-owned** — Each skill/hook ships its own `install.sh` with full control.
3. **Hub and spoke** — Central scripts handle framework concerns (backup, copy, merge), individual skills can extend via lifecycle hooks (pre-install, post-install).

The key insight was that the only bespoke need any skill or hook has today is declaring external dependencies (e.g., `jq`, `yq`, `bats`). Full lifecycle hooks are overkill.

## Decision

We will use a **centralized install** model where:

1. All install/uninstall logic lives in `scripts/` and is invoked via the justfile.
2. Skills declare metadata and dependencies in `SKILL.md` frontmatter (existing file, new `deps` field).
3. Hooks declare metadata and dependencies in `HOOK.md` frontmatter (new file, mirrors `SKILL.md` pattern).
4. The centralized installer reads the manifest, checks dependencies are on `$PATH`, and either proceeds or errors with guidance.
5. A single `just install <name>` command auto-detects whether the target is a skill or hook based on directory structure (`src/skills/` vs `src/hooks/`).

### Manifest format

**SKILL.md** (existing, extended):
```yaml
---
name: aminnaggar_adrs
version: 0.2.0
deps: [jq, yq]
---
```

**HOOK.md** (new):
```yaml
---
name: aminnaggar_uv_antipattern
version: 0.1.0
deps: [jq]
---
```

### Dependency checking

The installer extracts `deps` from frontmatter, checks each via `command -v`, and on failure reports: `Missing dependency: jq (install with: brew install jq)`.

## Rationale

- The only bespoke need today is dependency checking — a declarative `deps` list handles this without per-project install scripts.
- Centralized logic guarantees backups always happen, restore always works, and messaging is consistent.
- `HOOK.md` mirrors `SKILL.md`, giving hooks a proper manifest for discovery, versioning, and description.
- If bespoke install needs arise in the future, this decision can be revisited — but we don't build for hypotheticals.

## Consequences

### Positive
- Single install command (`just install <name>`) regardless of type
- Dependency failures are caught early with clear messaging
- No risk of individual skills/hooks forgetting to back up or message incorrectly
- Hooks get a proper manifest file for the first time

### Negative
- If a skill genuinely needs a bespoke install step in the future, this ADR must be revisited
- Adding a new dependency type (e.g., Python packages, not just CLI tools) requires extending the central checker

### Neutral
- Existing `SKILL.md` files need a `deps` field added
- Each hook needs a new `HOOK.md` file created
