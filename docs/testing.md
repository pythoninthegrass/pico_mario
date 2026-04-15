# Testing

Test strategy and infrastructure for the PICO-8 Mario clone.

## Overview

Testing is split into three tiers:

| Tier | Scope | Tool | Directory |
|------|-------|------|-----------|
| Unit | pure functions (helpers, math, constructors) | busted | `spec/` |
| Integration | multi-function interactions (player movement + collision, tile checks + coin collection) | busted | `spec/` |
| E2E | full game loops (`_init` -> `_update60` -> `_draw` sequences) | busted | `spec/` |

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
| `spec/helper.lua` | extracts `__lua__` from `mario.p8`, transpiles PICO-8 shorthand, provides `load_game()` |
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

The helper extracts the `__lua__` section from `mario.p8` and transpiles PICO-8 shorthand into standard Lua before `load()`:

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
