---
id: ADR-001
title: "Directory name as unique skill identifier"
date: 2026-01-29
status: accepted

supersedes: []
superseded_by: null

tags:
  - architecture
  - skills
  - naming

deciders:
  - Amin

context-critical: true
summary: "Skill ID: Use directory name (aminnaggar_adrs) instead of frontmatter id field"
---

# Directory Name as Unique Skill Identifier

## Context

When building Claude Code skills that may be shared or installed alongside other skills, we need a way to uniquely identify each skill to:
- Avoid conflicts with other skills of the same name
- Ensure uninstall commands don't accidentally remove the wrong skill

Initially, we added an `id` field to the SKILL.md frontmatter (e.g., `id: aminnaggar-adrs`) and had the justfile verify this ID before uninstalling.

## Decision

Use the installation directory name as the unique identifier instead of a frontmatter field.

- Directory: `~/.claude/skills/aminnaggar_adrs/`
- Skill name (for invocation): `adrs`

The directory path itself provides uniqueness. If someone else has an `adrs` skill, they would install to a different directory (e.g., `~/.claude/skills/otherperson_adrs/`).

## Rationale

- **Simpler**: No need for ID field in frontmatter or ID verification logic in justfile
- **Filesystem is the source of truth**: The directory path already uniquely identifies where files live
- **Convention over configuration**: Follow the pattern of using namespaced directory names
- **Less code to maintain**: Uninstall just removes the directory, no parsing required

## Consequences

- Skill creators should use a namespaced directory pattern: `{author}_{skillname}`
- The `name` field in SKILL.md remains the user-facing invocation name
- Uninstall is a simple `rm -rf` of the known directory path
