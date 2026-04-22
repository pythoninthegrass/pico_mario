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
- `docs/pico-8_cheatsheet.md` — PICO-8 API quick reference

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

# Count PICO-8 tokens in mario.p8 (hard limit: 8192)
# Approximates PICO-8's counter: brackets/strings = 1 each;
# commas, periods, local, end, semicolons, comments are free.
uv run scripts/count_tokens.py

# Lint/format the Python script
ruff format scripts/
ruff check scripts/

# Run pre-commit hooks (via prek)
prek run --all-files

# Run a specific hook
prek run luacheck --all-files

# Run unit tests (busted)
busted

# Run a specific test file
busted spec/helpers_spec.lua

# Run visual E2E tests (all scenarios, requires PICO-8)
uv run scripts/e2e_test.py

# Run specific E2E scenarios
uv run scripts/e2e_test.py --scenario idle jump death

# Regenerate E2E baselines
uv run scripts/e2e_test.py --update-baselines

# Copy cart to PICO-8 iCloud carts folder for play-testing
cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8

# Launch cart directly in PICO-8
pico8 -run mario.p8

# ! IMPORTANT: Quit PICO-8 after manual testing
pkill -f pico8
```

## Reference asset inspection

Mario/level references live in `maps/` (`smb_1-1.png` static level, `smb_1-1.mp4` gameplay video). These files are large — read selectively, not whole:

```bash
# Probe video metadata first (duration, resolution, fps)
ffprobe -i maps/smb_1-1.mp4 2>&1 | grep -E "Duration|Stream"

# Extract a single frame at a given timestamp
ffmpeg -y -ss 00:00:10 -i maps/smb_1-1.mp4 -frames:v 1 /tmp/frame.png

# Crop + upscale a region (e.g. Mario) so 8x8 pixels are legible
# -crop WxH+X+Y picks a region; -scale 800% upsamples with nearest-neighbour by default
magick /tmp/frame.png -crop 60x80+370+330 +repage -scale 800% /tmp/mario_zoom.png

# Crop a region from the static map (3584x480)
magick maps/smb_1-1.png -crop 256x240+0+0 +repage /tmp/smb_start.png
```

Use `magick` (IMv7), not the deprecated `convert`. Always write to `/tmp/` to keep the repo clean.

For programmatic pixel-level inspection (e.g. finding the widest run of a color, dumping a region as ASCII to digitise into 8x8 sprites), use Pillow via `uv run --with pillow python -c '...'`. Avoid awk for 2D pixel scans — basic awk doesn't support multi-dim arrays. Example:

```bash
uv run --with pillow python -c "
from PIL import Image
img = Image.open('maps/smb_1-1.png').convert('RGB')
sky=(92,148,252); white=(252,252,252); shadow=(60,188,252); black=(0,0,0)
for y in range(32, 56):
    row = ''
    for x in range(580, 640):
        px = img.getpixel((x, y))
        row += {sky:'.', white:'#', shadow:'o', black:'X'}.get(px, '?')
    print(f'{y:3}: {row}')
"
```

SMB 1-1 palette reference: sky `#5C94FC`, white `#FCFCFC`, cloud-shadow `#3CBCFC`, dark-green `#00A800`, light-green `#80D010`, darkest-green `#004400`, ground-brown `#C84C0C`.

## macOS gotchas

- **Screenshot filenames contain U+202F**: macOS uses a narrow no-break space before AM/PM in screenshot names (e.g. `Screenshot 2026-04-15 at 3.03.41\u202fPM.png`). This character is invisible and breaks naive path handling. When the user pastes a screenshot path, copy it to `/tmp` first using a printf escape: `cp /path/to/Screenshot\ …$(printf '\xe2\x80\xaf')PM.png /tmp/screenshot.png`

## Sprite sheet layout (TASK-001)

The full sprite sheet is defined in `generate_cart.py` (SPRITES and SPRITE_FLAGS dicts) and documented in `docs/architecture.md`. Sprite ID constants live in `src/constants.lua` as `spr_*` globals. Flag bit constants are `f_solid` through `f_pipe` (bits 0-6).

Summary: 42 sprites across 7 rows (row-aligned at multiples of 16):

- Row 0 (0-15): player (idle, run x2, jump, death), spawn marker, spike
- Row 1 (16-31): ground, brick, ? block x2, hit block, hard block
- Row 2 (32-47): pipe (TL, TR, body-L, body-R)
- Row 3 (48-63): goomba (walk x2, squished), koopa (walk x2, shell)
- Row 4 (64-79): coin x2, mushroom, star, fire flower
- Row 5 (80-95): flagpole (ball, shaft, flag), castle (block, top, door)
- Row 6 (96-111): cloud x3, bush x3, hill x3

## Sprite ID mismatch (current state)

The map (`__map__`) still references old sprite IDs (4=ground, 5=brick, 7=coin, 8=spike, 9=goal). The new layout places these at 16, 17, 64, 8, 80+ respectively. Running `generate_cart.py` without `--no-sprites` overwrites `__gfx__`/`__gff__` with the new layout, breaking the game because the map still points to old IDs. Always use `--no-sprites` until the map is migrated to the new sprite IDs.

## Architecture

See [docs/architecture.md](docs/architecture.md) for .p8 format details, sprite/flag conventions, SFX assignments, controls, and level design.

## Python script conventions

Scripts use PEP 723 inline metadata with `uv run --script` shebang. See `CLAUDE.md` for the exact pattern (decouple-based env loading, specific docstring format, no `from __future__`).

## Testing

See [docs/testing.md](docs/testing.md) for test infrastructure, PICO-8 shim details, gotchas, and the full test strategy (unit, integration, E2E).

## Context7

Always use Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

### Libraries

- j178/prek
- jdx/mise
- microsoft/playwright-python
- mpeterv/luacheck
- mrlesk/backlog.md
- websites/lexaloffle_dl_pico-8_manual
- websites/taskfile_dev

<!-- BACKLOG.MD MCP GUIDELINES START -->

<CRITICAL_INSTRUCTION>

## BACKLOG WORKFLOW INSTRUCTIONS

This project uses Backlog.md MCP for all task and project management.

**CRITICAL RESOURCE**: Read `backlog://workflow/overview` to understand when and how to use Backlog for this project.

- **First time working here?** Read the overview resource IMMEDIATELY to learn the workflow
- **Already familiar?** You should have the overview cached ("## Backlog.md Overview (MCP)")
- **When to read it**: BEFORE creating tasks, or when you're unsure whether to track work

### Key MCP Commands

| Command | Purpose |
|---------|---------|
| `task_create` | Create a new task (status defaults to "To Do") |
| `task_edit` | Edit metadata, check ACs, update notes, change status |
| `task_view` | View full task details |
| `task_search` | Find tasks by keyword |
| `task_list` | List tasks with optional filters |
| `task_complete` | **Moves task to `backlog/completed/`** — only use for cleanup, not for marking done |

### Task Lifecycle

1. **Create**: `task_create` — new task in `backlog/tasks/`
2. **Start**: `task_edit(status: "In Progress")` — mark as active
3. **Done**: `task_edit(status: "Done")` — mark finished, stays in `backlog/tasks/` (visible on kanban)
4. **Archive**: `task_complete` — moves to `backlog/completed/` (use only when explicitly cleaning up)

**IMPORTANT**: Use `task_edit(status: "Done")` to mark tasks as done. Do NOT use `task_complete` unless the user explicitly asks to archive/clean up — it removes the task from the kanban.

### Cross-Branch Task Scanning (disabled)

`check_active_branches` and `remote_operations` are both **disabled** in `backlog/config.yml`. With worktrees, these features scan other branches and pull in tasks that were already completed/archived on `main` but still exist in `backlog/tasks/` on older branches — bloating the kanban with ghost tasks. Do not re-enable without accounting for worktree branch divergence.

### Multiline Field Gotcha

The `finalSummary`, `description`, `implementationNotes`, and `planSet` MCP parameters are single-line JSON strings. Literal `\n` sequences are NOT interpreted as newlines — they render as the two characters `\` `n` in the markdown file. To write multiline content:

- Use `task_edit` with the field for short single-paragraph content
- For multiline content, edit the task markdown file directly with the file editing tool (the file path is shown in `task_view` output)

The overview resource contains additional detail on decision frameworks, search-first workflow, and guides for task creation, execution, and completion.

</CRITICAL_INSTRUCTION>

<!-- BACKLOG.MD MCP GUIDELINES END -->
