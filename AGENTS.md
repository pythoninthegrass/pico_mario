# AGENTS.md

## Project overview

Single-level Mario clone for the PICO-8 fantasy console. One `.p8` cartridge file contains all game code, sprites, map, and audio. A Python helper script patches sprite data into the cart.

## Source of truth

`mario.p8` is the canonical artifact. It contains `__lua__`, `__map__`, `__sfx__`, and `__music__` sections that are hand-authored. Never regenerate these sections from scratch — only patch `__gfx__` and `__gff__` via the script.

## Key files

- `mario.p8` — the PICO-8 cartridge (Lua game code + all data sections)
- `scripts/generate_cart.py` — reads the `.p8`, patches `__gfx__` and `__gff__` from sprite definitions in the script, preserves everything else
- `docs/pico-8_cheatsheet.png` — PICO-8 API quick reference (image)
- `docs/llms.txt` — extracted PICO-8 manual snippets for LLM context

## Runtimes and tools

Managed via `mise` (see `.tool-versions`):

- Python 3.13, uv, ruff for the helper script
- Lua 5.5 (not used by PICO-8 directly — PICO-8 has its own Lua dialect)

## Commands

```bash
# Alias for PICO-8 binary (add to shell profile if needed)
alias pico8='/Applications/PICO-8.app/Contents/MacOS/pico8'

# Patch sprites into the cart (in-place)
uv run scripts/generate_cart.py

# Patch sprites, write to a different file
uv run scripts/generate_cart.py -i mario.p8 -o output.p8

# Lint/format the Python script
ruff format scripts/
ruff check scripts/

# Run unit tests (busted)
busted

# Run a specific test file
busted spec/helpers_spec.lua

# Copy cart to PICO-8 iCloud carts folder for play-testing
cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8

# Launch cart directly in PICO-8
pico8 -run mario.p8
```

## macOS gotchas

- **Screenshot filenames contain U+202F**: macOS uses a narrow no-break space before AM/PM in screenshot names (e.g. `Screenshot 2026-04-15 at 3.03.41\u202fPM.png`). This character is invisible and breaks naive path handling. When the user pastes a screenshot path, copy it to `/tmp` first using a printf escape: `cp /path/to/Screenshot\ …$(printf '\xe2\x80\xaf')PM.png /tmp/screenshot.png`

## Architecture

See [docs/architecture.md](docs/architecture.md) for .p8 format details, sprite/flag conventions, SFX assignments, controls, and level design.

## Python script conventions

Scripts use PEP 723 inline metadata with `uv run --script` shebang. See `CLAUDE.md` for the exact pattern (decouple-based env loading, specific docstring format, no `from __future__`).

## Testing

See [docs/testing.md](docs/testing.md) for test infrastructure, PICO-8 shim details, gotchas, and the full test strategy (unit, integration, E2E).

<!-- BACKLOG.MD MCP GUIDELINES START -->

<CRITICAL_INSTRUCTION>

## BACKLOG WORKFLOW INSTRUCTIONS

This project uses Backlog.md MCP for all task and project management activities.

**CRITICAL GUIDANCE**

- If your client supports MCP resources, read `backlog://workflow/overview` to understand when and how to use Backlog for this project.
- If your client only supports tools or the above request fails, call `backlog.get_workflow_overview()` tool to load the tool-oriented overview (it lists the matching guide tools).

- **First time working here?** Read the overview resource IMMEDIATELY to learn the workflow
- **Already familiar?** You should have the overview cached ("## Backlog.md Overview (MCP)")
- **When to read it**: BEFORE creating tasks, or when you're unsure whether to track work

These guides cover:

- Decision framework for when to create tasks
- Search-first workflow to avoid duplicates
- Links to detailed guides for task creation, execution, and finalization
- MCP tools reference

You MUST read the overview resource to understand the complete workflow. The information is NOT summarized here.

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->
