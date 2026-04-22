---
name: aminnaggar_uv_antipattern
version: 0.1.0
deps: [jq]
---

# uv Anti-Pattern Hook

Blocks common uv/pip anti-patterns and nudges Claude toward the correct uv workflow.

## Blocked patterns

- `uv pip install` — use `uv add` + `uv sync`
- `uv pip uninstall` — use `uv remove` + `uv sync`
- `uv pip freeze` — use `uv tree` or `uv lock --check`
- `uv venv` — `uv sync` handles venv automatically
- `pip install` / `pip3 install` — use uv instead
