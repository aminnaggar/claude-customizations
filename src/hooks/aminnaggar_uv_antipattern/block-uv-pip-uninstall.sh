#!/bin/bash
COMMAND=$(jq -r '.tool_input.command // empty')
[[ "$COMMAND" =~ ^uv[[:space:]]+pip[[:space:]]+uninstall([[:space:]]|$) ]] || exit 0
echo "BLOCKED: 'uv pip uninstall' bypasses pyproject.toml and the lockfile." >&2
echo "Instead: use 'uv remove <package>' to remove a dependency, then 'uv sync'." >&2
exit 2
