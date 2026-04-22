#!/bin/bash
COMMAND=$(jq -r '.tool_input.command // empty')
[[ "$COMMAND" =~ ^uv[[:space:]]+pip[[:space:]]+install([[:space:]]|$) ]] || exit 0
echo "BLOCKED: 'uv pip install' bypasses pyproject.toml and the lockfile." >&2
echo "Instead: use 'uv add <package>' to add a dependency, then 'uv sync' to install." >&2
exit 2
