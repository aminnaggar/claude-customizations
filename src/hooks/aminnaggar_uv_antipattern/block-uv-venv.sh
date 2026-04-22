#!/bin/bash
COMMAND=$(jq -r '.tool_input.command // empty')
[[ "$COMMAND" =~ ^uv[[:space:]]+venv([[:space:]]|$) ]] || exit 0
echo "BLOCKED: 'uv venv' is unnecessary — 'uv sync' creates and manages the virtualenv automatically." >&2
echo "Instead: just run 'uv sync' and let uv handle the venv." >&2
exit 2
