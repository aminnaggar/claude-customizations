---
id: ADR-002
title: "Version field in skill frontmatter"
date: 2026-01-29
status: accepted

supersedes: []
superseded_by: null

tags:
  - architecture
  - skills
  - versioning

deciders:
  - Amin

context-critical: true
summary: "Versioning: Add version field to SKILL.md frontmatter for discoverability"
---

# Version Field in Skill Frontmatter

## Context

When skills are updated over time, users and AI assistants need a way to know which version is currently installed. This helps with:
- Debugging ("what version are you running?")
- Ensuring updates were applied
- Communicating about features available in specific versions

## Decision

Add a `version` field to the SKILL.md frontmatter following semver:

```yaml
---
name: adrs
version: 0.1.0
description: ...
---
```

This replaces a standalone `VERSION` file that was previously in the src/ directory.

## Rationale

- **Single source of truth**: Version lives with the skill definition, not in a separate file
- **AI-accessible**: Claude can read the SKILL.md and report the version when asked
- **Standard practice**: Follows common conventions for metadata in frontmatter
- **Less file clutter**: One less file to maintain

## Consequences

- Version should be updated in SKILL.md when releasing changes
- AI can answer "what version of the skill is installed?" by reading the frontmatter
- The standalone VERSION file was removed as redundant
