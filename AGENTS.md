# AGENTS.md

## Project overview

Single-level Mario clone for the PICO-8 fantasy console. Game code lives in `src/*.lua` files. A Python build script assembles these into `mario.p8` (the PICO-8 cartridge) and patches sprite/flag data.

## Source of truth

Lua game code lives in `src/*.lua`. Edit code there, then run `generate_cart.py` to assemble `mario.p8`. The `__map__`, `__sfx__`, and `__music__` sections in `mario.p8` are hand-authored and preserved by the build. Never edit `__lua__` in `mario.p8` directly — it is generated from `src/`.

## Source layout

```text
src/
  constants.lua  -- physics tuning, map dims, sprite flags, game states
  helpers.lua    -- tile_at, tile_flag_at, is_solid, is_hazard, is_goal, collect_coin
  player.lua     -- make_player, player_move, player_check_tiles
  camera.lua     -- update_cam
  particles.lua  -- particles table, spawn/update/draw
  main.lua       -- _init(), _update60(), _draw()
  states.lua     -- update_play, get_player_spr, update_dead, update_clear
```

Files are concatenated in the order listed above to form the `__lua__` section. The order matters because later files reference globals defined in earlier ones.

## Key files

- `src/*.lua` — game source code (edit here)
- `mario.p8` — assembled PICO-8 cartridge (build output, checked in)
- `scripts/generate_cart.py` — assembles `src/*.lua` into `__lua__`, patches `__gfx__` and `__gff__` from sprite definitions
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

# Assemble src/*.lua into the cart (standard build)
uv run scripts/generate_cart.py --no-sprites

# Assemble + patch sprites (only after map uses new sprite IDs)
uv run scripts/generate_cart.py

# Assemble + patch, write to a different file
uv run scripts/generate_cart.py -i mario.p8 -o output.p8

# Patch sprites only (skip Lua assembly)
uv run scripts/generate_cart.py --no-assemble

# Assemble Lua only (skip sprite patching)
uv run scripts/generate_cart.py --no-sprites

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

## Sprite ID mismatch (current state)

The map (`__map__`) references old sprite IDs (4=ground, 5=brick, 7=coin, 8=spike, 9=goal). The `SPRITES` dict in `generate_cart.py` defines sprites at new expanded IDs (16=ground, 17=brick, 64=coin, etc.) for TASK-001. Running `generate_cart.py` without `--no-sprites` overwrites `__gfx__`/`__gff__` with the new layout, which breaks the game because the map still points to old IDs. Always use `--no-sprites` until the map is migrated to the new sprite IDs.

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

### Task lifecycle (kanban)

Tasks follow a kanban flow: **To Do -> In Progress -> Done**. Use `task_edit` to move between statuses:

```text
task_edit(id="XXX", status="In Progress")  # starting work
task_edit(id="XXX", status="Done")         # finished work
```

**Do NOT use `task_complete`** to mark tasks as done. `task_complete` moves the task file to `backlog/completed/`, hiding it from the board. Use it only when you intentionally want to archive a finished task off the board.

| MCP tool | Purpose |
| --- | --- |
| `task_edit(status="Done")` | Mark task done (stays visible on board) |
| `task_complete` | Move to `completed/` folder (hides from board) |
| `task_archive` | Move to archive (permanent removal from board) |

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->
