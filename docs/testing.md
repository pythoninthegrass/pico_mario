# Testing

Test strategy and infrastructure for the PICO-8 Mario clone.

## Overview

Testing is split into three tiers:

| Tier | Scope | Tool | Directory |
|------|-------|------|-----------|
| Unit | pure functions (helpers, math, constructors) | busted | `spec/` |
| Integration | multi-function interactions (player movement + collision, tile checks + coin collection) | busted | `spec/` |
| E2E (busted) | full game loops (`_init` -> `_update60` -> `_draw` sequences) | busted | `spec/` |
| E2E (visual) | visual regression + functional assertions against real PICO-8 | e2e_test.py | `spec/e2e_baselines/` |

All tiers run under [busted](https://github.com/lunarmodules/busted) (installed via `luarocks install busted` under mise's Lua 5.5).

## Running tests

```bash
# Run all tests
busted

# Run a specific test file
busted spec/helpers_spec.lua

# Run tests matching a name pattern
busted --filter='collect_coin'

# List tests without running
busted --list
```

## Infrastructure

### Key files

| File | Purpose |
|------|---------|
| `.busted` | busted configuration (root dirs, helper, output format) |
| `spec/helper.lua` | reads `src/*.lua` files, transpiles PICO-8 shorthand, provides `load_game()` |
| `spec/pico8_shim.lua` | stubs for all PICO-8 built-in functions with mock map/flag system |

### PICO-8 shim (`spec/pico8_shim.lua`)

Stubs every PICO-8 API function so game code can run under standard Lua 5.x. Graphics and audio functions are no-ops. Map and sprite-flag functions use an in-memory mock controlled via the `_pico8` table:

```lua
-- place sprite 10 at tile column 3, row 2
_pico8.set_tile(3, 2, 10)

-- set sprite 10's flags: bit 0 (solid) + bit 3 (coin) = 0x09
_pico8.set_flags(10, 0x09)

-- reset all mock state (map, flags, buttons)
_pico8.reset()
```

Button input is mocked via `_pico8.btns`:

```lua
_pico8.btns[0] = true  -- left
_pico8.btns[4] = true  -- O (jump)
```

### Transpiler (`spec/helper.lua`)

The helper reads `src/*.lua` files in the defined include order, concatenates them, and transpiles PICO-8 shorthand into standard Lua before `load()`:

| PICO-8 | Standard Lua |
|--------|-------------|
| `x+=y` | `x=x+(y)` |
| `x-=y` | `x=x-(y)` |
| `x*=y` | `x=x*(y)` |
| `a!=b` | `a~=b` |

### `load_game()`

Call `load_game()` in `before_each` to reset mock state and re-execute the cart code. This defines all game functions and constants but does NOT call `_init()` (PICO-8 calls that automatically; tests call it explicitly when needed).

## Gotchas

### Global sandboxing

Busted sandboxes globals per test. When setting globals that game code reads, use `_G`:

```lua
-- correct
_G.cam_x = 0
_G.coins = 0

-- WRONG: sets a local in the test sandbox, game code won't see it
cam_x = 0
```

### PICO-8 Lua vs standard Lua

- PICO-8 uses 16.16 fixed-point numbers; standard Lua uses IEEE 754 doubles. Floating-point edge cases may differ.
- PICO-8's `print()` draws to screen; the shim's `print()` is a no-op. Use `io.write()` for debug output in tests.
- PICO-8's `sub()` is `string.sub()`; the shim maps it accordingly.

## Test tiers

### Unit tests

Test individual pure functions in isolation. Mock map/flag data as needed. No game state initialization required.

**Candidates:**

- `tile_at`, `tile_flag_at`, `is_solid`, `is_hazard`, `is_goal`
- `collect_coin`
- `make_player`
- `update_cam`
- `spawn_particles`, `update_particles`
- `get_player_spr`

### Integration tests

Test interactions between multiple functions. Require setting up map data and player state.

**Candidates:**

- `player_move` -- horizontal/vertical collision resolution against solid tiles
- `player_check_tiles` -- hazard death, goal clear, coin collection with score increment
- Player movement + camera tracking across multiple frames
- Coyote time (jump grace frames after leaving an edge)

### E2E tests

Test full game loop sequences: `_init()` followed by multiple `_update60()` calls, verifying state transitions.

**Candidates:**

- Game start: `_init` sets `st_play`, spawns player at marker, initializes camera
- Death sequence: player contacts hazard -> `st_dead` -> death timer -> respawn
- Level clear: player contacts goal -> `st_clear` -> clear timer
- Coin collection: walk through coin tile -> `coins` increments, tile removed from map
- Fall death: player falls below map bottom -> `st_dead`

## Visual E2E tests

Visual E2E tests run the game in real PICO-8, capture screenshots at deterministic frames, and compare against baseline images. They also assert on game state (player position, coins, game state) via `printh` logging to the clipboard.

### Architecture

```
scripts/e2e_test.py
  |-- defines Scenario (name, inputs, capture_frame, expected_state, expected_coins)
  |-- generates per-scenario Lua driver from spec/e2e_driver.lua template
  |-- assembles test cart: game code + driver -> spec/e2e_<name>.p8
  |-- launches PICO-8, polls for screenshot, reads state from clipboard
  |-- compares screenshot vs spec/e2e_baselines/<name>.png
  |-- checks functional assertions (state, coins)
```

The Lua driver overrides `btn()` with a frame-indexed input table and patches `btnp()` calls to `_tbp()` at assembly time (PICO-8's built-in `btnp` cannot be reliably overridden via global assignment). At the capture frame, the driver writes game state to the clipboard via `printh(msg, "@clip")` and captures a screenshot via `extcmd("screen")`.

### Running visual E2E tests

```bash
# Run all 6 scenarios against baselines (native PICO-8)
uv run scripts/e2e_test.py

# Run specific scenarios
uv run scripts/e2e_test.py --scenario idle jump death

# Regenerate all baselines
uv run scripts/e2e_test.py --update-baselines

# Regenerate specific baselines
uv run scripts/e2e_test.py --update-baselines --scenario level_clear

# Run via Playwright (headless, HTML export)
uv run scripts/e2e_test.py --mode playwright
```

### Scenarios

| Name | Inputs | Capture Frame | Expected State | Description |
|------|--------|---------------|---------------|-------------|
| idle | none | 10 | st_play | Player stands at spawn |
| move_right | hold right 30 frames | 35 | st_play | Player walks right, collects 1 coin |
| jump | hold O frames 5-15 | 12 | st_play | Player jumps in place (mid-air) |
| coin_pickup | hold right 65 frames | 70 | st_play | Player collects 4 coins |
| death | hold right 115 frames | 135 | st_dead | Player falls into first spike pit |
| level_clear | hold right+run, jump at 3 gaps | 265 | st_clear | Full level traversal to goal |

### Key files

| File | Purpose |
|------|---------|
| `scripts/e2e_test.py` | Test runner (scenario definitions, cart assembly, PICO-8 launch, comparison) |
| `spec/e2e_driver.lua` | Lua driver template (native: btn override + printh + extcmd) |
| `spec/e2e_driver_html.lua` | Lua driver template (HTML/Playwright: GPIO I/O) |
| `spec/e2e_baselines/*.png` | Baseline screenshots (one per scenario) |

### Adding a new scenario

1. Define a `Scenario` in the `_register_scenarios()` function in `scripts/e2e_test.py`
2. Run `uv run scripts/e2e_test.py --update-baselines --scenario <name>` to generate the baseline
3. Verify the screenshot and state output look correct
4. Commit the baseline PNG

### GPIO protocol (HTML/Playwright path)

| Byte(s) | Direction | Content |
|---------|-----------|---------|
| 0-5 | JS -> Lua | Button state (0=off, nonzero=on) |
| 64 | Lua -> JS | game state (0=play, 1=dead, 2=clear) |
| 65 | Lua -> JS | coin count |
| 66-67 | Lua -> JS | player.x (low, high byte) |
| 68-69 | Lua -> JS | player.y (low, high byte) |
| 126 | Lua -> JS | frame counter (mod 256) |
| 127 | Lua -> JS | ready flag (1 = running) |

### Gotchas

- PICO-8's `btnp()` cannot be overridden via global function assignment. The test cart assembly patches `btnp(` to `_tbp(` in the concatenated Lua code.
- PICO-8 saves screenshots to Desktop. The runner polls for the file, then moves it to `/tmp/pico8_e2e/`.
- Brick ceilings above gaps cause head-bump collisions. The `level_clear` scenario must jump early enough that the player rises above the ceiling bricks before reaching them horizontally.
- The `printh(msg, "@clip")` writes to the macOS clipboard. The runner reads it via `pbpaste`.

## Naming conventions

- Test files: `spec/<module>_spec.lua`
- Describe blocks: match the function or behavior under test
- Test names: describe the expected behavior, not the implementation

```lua
-- good
it('returns dead when player touches hazard tile', ...)

-- bad
it('test player_check_tiles hazard', ...)
```
