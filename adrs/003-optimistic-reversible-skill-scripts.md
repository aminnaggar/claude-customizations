---
id: ADR-003
title: "Optimistic reversible scripts for skill actions"
date: 2026-04-04
status: proposed

supersedes: []
superseded_by: null

tags:
  - architecture
  - skills
  - scripting

deciders:
  - Amin

context-critical: true
summary: "Skills: Scripts own side effects and make them reversible; agent owns content only"
---

# Optimistic Reversible Scripts for Skill Actions

## Context

The tickets skill evolved through several iterations and arrived at a pattern where scripts do all filesystem side effects (create directories, generate IDs, manage fields) in a single command and immediately provide an undo path. The agent's only job is to write content using the Write tool. This "optimistic" approach -- act first, offer reversal -- proved far more reliable and token-efficient than the original "deterministic" approach where scripts are passive queries and the agent coordinates multiple steps manually.

The ADR skill still uses the older deterministic pattern: `next-adr.sh` returns a number, then the agent must separately generate a slug, construct a filename, create the file with the right naming convention, and fill all frontmatter fields. This multi-step coordination is fragile and consumes more tokens.

## Decision

All skill scripts that perform mutations will follow the optimistic-reversible pattern:

1. **Scripts own all side effects.** The script creates directories, generates IDs, computes slugs, and sets up filesystem state. The agent never runs `mkdir`, `rm`, or manual filename construction.

2. **Scripts output a template + Write instruction.** After acting, the script prints the file path and a ready-to-use template. The agent fills in content and writes it with the Write tool.

3. **Script output includes decision context.** The single command's output provides enough surrounding context for the agent to judge whether the action was correct -- e.g., `create.sh` lists existing items so the agent can spot duplicates or conflicts without a second call. The agent should never need to run a follow-up query to decide whether to undo.

4. **Every mutation has a printed undo command.** The script's output includes the exact command to reverse the action (e.g., `safe-delete.sh <id>`). Combined with the decision context above, the agent can immediately evaluate and undo in the same turn if needed.

5. **One command per action.** No multi-step workflows where the agent calls one script for an ID, then manually does the rest. Each action is a single script invocation that leaves the system in a consistent state.

6. **Scripts are idempotent where possible.** Status changes exit early if already in the target state. Undo commands handle already-cleaned-up state gracefully.

7. **Queries are free, mutations are guarded.** Read-only scripts (list, search, show) have no side effects and need no undo. Only mutating scripts (create, delete, set-status) follow the optimistic-reversible pattern.

## Rationale

- **Fewer tokens per action**: One script call replaces a multi-step agent workflow. The agent doesn't need to reason about filenames, slugs, or directory structures.
- **Fewer errors**: The agent can't get the filename format wrong, forget to zero-pad an ID, or create a file in the wrong location -- the script handles all of that.
- **Informed reversibility**: Acting optimistically is safe because every action can be undone, and the output includes enough context to judge whether it *should* be undone -- all in one turn, no follow-up queries needed. This matches how `git` works -- commit freely, `git log` and revert if needed.
- **Clean separation of concerns**: Scripts handle mechanics (filesystem, naming, numbering). The agent handles judgment (what to write, what status to set). Neither crosses into the other's domain.
- **Battle-tested**: The tickets skill proved this pattern over multiple iterations. The older query-then-manually-create pattern in ADRs was the source of recurring issues.

## Consequences

### Positive
- Skills become more reliable -- less agent coordination means fewer failure modes
- Token cost per action drops significantly (one script call vs. multi-step workflow)
- New skills can follow a consistent, proven pattern
- Users get undo commands for free on every mutation

### Negative
- Scripts are slightly more complex (they do more per invocation)
- Requires a `safe-delete` or equivalent undo script for each mutating action

### Neutral
- SKILL.md instructions become simpler (less workflow documentation needed)
- The agent's role shifts from orchestrator to content author

## Alternatives Considered

### Deterministic query-then-create (current ADR pattern)
- Script returns an ID, agent does the rest manually
- Rejected because: fragile multi-step coordination, more tokens, more error-prone, no built-in undo

### Fully automated scripts (script writes the file too)
- Script creates the file with placeholder content, agent edits it
- Rejected because: the agent needs to use the Write tool for new files (Edit requires reading first), and placeholder content is wasted tokens -- better to let the agent write final content directly
