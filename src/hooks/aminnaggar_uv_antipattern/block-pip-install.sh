#!/bin/bash
COMMAND=$(jq -r '.tool_input.command // empty')
[[ "$COMMAND" =~ ^pip3?[[:space:]]+install([[:space:]]|$) ]] || exit 0
echo "BLOCKED: Do not use 'pip' or 'pip3' directly — this project uses uv for dependency management." >&2
echo "Instead: use 'uv add <package>' to add a dependency, then 'uv sync' to install." >&2
exit 2
