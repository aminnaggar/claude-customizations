#!/bin/bash
COMMAND=$(jq -r '.tool_input.command // empty')
[[ "$COMMAND" =~ ^uv[[:space:]]+pip[[:space:]]+freeze([[:space:]]|$) ]] || exit 0
echo "BLOCKED: 'uv pip freeze' is not the right way to inspect dependencies." >&2
echo "Instead: use 'uv tree' to view the dependency tree, or 'uv lock --check' to verify the lockfile." >&2
exit 2
