---
id: TASK-021
title: Plan modular PICO-8 source layout and asset packing strategy
status: In Progress
assignee: []
created_date: '2026-04-15 22:41'
updated_date: '2026-04-15 22:54'
labels: []
dependencies: []
references:
  - '~/iCloud/pico-8/carts/poom'
  - 'https://www.excamera.com/sphinx/article-compression.html'
documentation:
  - docs/architecture.md
  - AGENTS.md
  - scripts/generate_cart.py
  - spec/helper.lua
priority: medium
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create an implementation plan to migrate this project from a single monolithic `mario.p8` Lua section toward a more traditional source layout (for example `src/`, `common/`, `utils/`) while preserving the current cartridge workflow constraints. The plan should be informed by analysis of `~/iCloud/pico-8/carts/poom`, including their multi-cart data loading pattern and serialization/decompression approach, and should recommend what to adopt (or avoid) for pico_mario.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Proposed target repository structure is documented with clear mapping from current monolithic responsibilities to new modules and folders.
- [ ] #2 Build pipeline approach is specified for assembling Lua sources into `mario.p8` without regenerating non-Lua sections contrary to project constraints.
- [ ] #3 Migration is broken into phased, reviewable steps with risks, rollback strategy, and explicit test/verification checkpoints.
- [ ] #4 Plan includes a decision record on asset packing strategy (single cart vs multi-cart streaming vs LZ-style compression) and explains tradeoffs in the context of PICO-8 limits.
- [ ] #5 Plan identifies required updates to developer tooling and tests (including cart loading helpers) so local workflows continue to work during and after migration.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->

## Implementation Plan

### 1. Target Directory Structure

```
pico_mario/
  mario.p8              -- assembled cart (build output, still checked in as canonical artifact)
  src/
    main.lua            -- PICO-8 entry points: _init(), _update60(), _draw()
    constants.lua       -- physics tuning, map dims, sprite flags, game states
    helpers.lua         -- tile_at, tile_flag_at, is_solid, is_hazard, is_goal, collect_coin
    player.lua          -- make_player, player_move, player_check_tiles, get_player_spr
    camera.lua          -- update_cam
    particles.lua       -- particles table, spawn_particles, update_particles, draw_particles
    states.lua          -- update_play, update_dead, update_clear (state machine handlers)
  scripts/
    generate_cart.py    -- existing sprite/flag patcher (updated to also assemble src/*.lua)
  spec/                 -- unchanged location, but helper.lua updated
    helper.lua
    pico8_shim.lua
    *_spec.lua
  docs/
    architecture.md     -- updated with new layout
    testing.md
```

#### File-by-file mapping from current mario.p8 __lua__

| Current lines (in .p8) | Responsibility | Target file |
|---|---|---|
| 4-33 | constants (physics, map dims, sprite flags, game states) | `src/constants.lua` |
| 34-75 | section header + tile query helpers + collect_coin | `src/helpers.lua` |
| 77-172 | section header + player object: constructor, movement, tile checks | `src/player.lua` |
| 174-186 | section header + camera | `src/camera.lua` |
| 188-222 | section header + particle system | `src/particles.lua` |
| 224-263 | section header + _init, _update60 (state dispatch) | `src/main.lua` |
| 266-302 | _draw | `src/main.lua` |
| 304-398 | section header + update_play, get_player_spr | `src/states.lua` |
| 400-418 | section headers + update_dead, update_clear | `src/states.lua` |

### 2. Build Pipeline: Assembling src/*.lua into mario.p8

**Approach: Extend generate_cart.py**

Add an assembly step to the existing `generate_cart.py` that:
1. Reads `src/*.lua` files in a defined order
2. Concatenates them into a single Lua string
3. Replaces the `__lua__` section in the parsed .p8 structure
4. Then patches `__gfx__` and `__gff__` as before
5. Writes the assembled `mario.p8`

The include order is defined in a list at the top of the script:
```python
LUA_SOURCES = [
    "src/constants.lua",
    "src/helpers.lua",
    "src/player.lua",
    "src/camera.lua",
    "src/particles.lua",
    "src/states.lua",
    "src/main.lua",
]
```

**Why not PICO-8 #include?** The `#include` directive works inside PICO-8's editor and CLI but:
- Our test infrastructure (`spec/helper.lua`) parses the .p8 file directly with standard Lua -- it cannot resolve `#include` directives
- `generate_cart.py` already parses and writes the .p8 -- adding concatenation is trivial
- Keeping the assembled `mario.p8` as a complete self-contained cart means it works in PICO-8 without any preprocessing

**Why not a separate assemble.py?** One script is simpler. The assembly and sprite patching are both "build the cart" operations. If the script gets too large later, extract then.

### 3. Decision Record: Asset Packing Strategy

**Decision: Stay single-cart. No multi-cart streaming or LZ compression.**

**Context:** POOM uses 25+ data carts because it has a 3D BSP renderer with hundreds of wall/floor/ceiling textures and level geometry that far exceeds a single cart's data budget. pico_mario is a 2D platformer with ~10 sprites and a 64x16 tile map.

**Budget analysis for pico_mario:**
- Sprite sheet: 128x128 pixels = 8KB. Currently using ~10 sprites (< 1KB). Even with the planned 7-row expansion (TASK-001), we use ~112 sprites = ~3.5KB. Well within budget.
- Map: 64x16 tiles = 1KB of the available 4KB map section.
- SFX: 4 effects used of 64 available.
- Code: ~418 lines, likely well under the 8192 token limit. Even 3-4x growth stays safe.

**Tradeoffs:**

| Strategy | Pros | Cons | Verdict |
|---|---|---|---|
| Single cart | Simple tooling, no runtime complexity, easy testing | Hard limit on total data | Sufficient for scope |
| Multi-cart streaming (POOM-style) | Virtually unlimited data | Complex runtime loader, harder testing, multiple .p8 files to manage | Overkill |
| LZ compression | More data per cart | Complex encode/decode, burns tokens on decompressor, harder debugging | Overkill |

**Revisit trigger:** If we ever need >128 unique sprites, >64x32 map tiles, or >64 SFX, revisit this decision. That would indicate scope beyond a single-level Mario clone.

### 4. Phased Migration Steps

#### Phase 0: Snapshot baseline (prerequisite)
- Run `busted` and record passing test count
- Run `pico8 -run mario.p8` and verify gameplay works
- Commit current state as the "before" reference point
- Record current token count (if available via PICO-8 CLI)

#### Phase 1: Create src/ files by extracting from mario.p8 (mechanical split)
- Create `src/` directory
- Copy each code section from `mario.p8` `__lua__` into the corresponding `src/*.lua` file per the mapping table above
- Add a brief header comment to each file (e.g. `-- src/constants.lua: physics and game constants`)
- Do NOT modify any logic -- this is a pure extraction
- **Verification:** Each `src/*.lua` file contains exactly the lines from the mapping table. Concatenating all src files in order produces identical output to the original `__lua__` section (minus the header comment line).

#### Phase 2: Update generate_cart.py to assemble src/*.lua
- Add `LUA_SOURCES` list and concatenation logic to `generate_cart.py`
- The assembly replaces the `__lua__` section content with the concatenated sources
- Run `uv run scripts/generate_cart.py` and diff the output `mario.p8` against the Phase 0 snapshot
- **Verification:** `diff` shows zero changes to `mario.p8` (byte-identical). If not, fix ordering or whitespace until it matches.

#### Phase 3: Update test infrastructure
- Modify `spec/helper.lua` `load_cart()` to read `src/*.lua` files directly instead of extracting `__lua__` from `mario.p8`
  - New approach: read each file in LUA_SOURCES order, concatenate, transpile, load
  - Keep the old `load_cart()` as `load_cart_from_p8()` for fallback/validation
- Run `busted` -- all existing tests must pass with zero changes to test files
- **Verification:** Same test count, same pass/fail results as Phase 0.

#### Phase 4: Verify assembled cart in PICO-8
- Run `uv run scripts/generate_cart.py` to build the cart from `src/` files
- Run `pico8 -run mario.p8` and play-test: movement, jumping, running, coins, death, level clear
- Copy to iCloud: `cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8`
- **Verification:** Game behaves identically to Phase 0 baseline.

#### Phase 5: Remove __lua__ duplication and update docs
- The `__lua__` section in `mario.p8` is now generated from `src/`. Remove any manual editing workflow for it.
- Update `AGENTS.md` to document: "Edit Lua code in `src/*.lua`, run `generate_cart.py` to assemble into `mario.p8`"
- Update `docs/architecture.md` with the new source layout
- Update `docs/testing.md` if the helper.lua changes affect test workflow
- **Verification:** Documentation is consistent with new workflow.

### 5. Required Tooling Updates

#### generate_cart.py
- Add `LUA_SOURCES` ordered list
- Add `assemble_lua(sources: list[Path]) -> str` function that reads and concatenates
- Modify the build flow to call `assemble_lua()` and inject into `__lua__` section
- Add `--no-assemble` flag to skip Lua assembly (for cases where you want to patch sprites only)
- Run `ruff format` and `ruff check` after changes

#### spec/helper.lua
- Add a `LUA_SOURCES` table mirroring the Python list (or read a shared config)
- New `load_cart_from_sources()` function: reads each src file, concatenates, transpiles, loads
- `load_game()` calls `load_cart_from_sources()` instead of `load_cart('mario.p8')`
- Keep `load_cart()` available for validation tests that want to verify the assembled .p8

#### spec/pico8_shim.lua
- No changes expected. The shim stubs PICO-8 APIs regardless of how code is loaded.

### 6. Risks and Rollback Strategy

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Include order matters (globals defined in one file used in another) | High | Build breaks | Define explicit order in LUA_SOURCES; constants first, then helpers, then consumers |
| Whitespace/newline differences between concatenated sources and original __lua__ | Medium | Diff noise, confusing git history | Normalize line endings; accept one "reformat" commit |
| PICO-8 token counter behaves differently with assembled code vs hand-edited | Low | Token count surprise | Verify token count in Phase 4; assembly adds no tokens vs monolithic |
| Test transpiler breaks on file boundary artifacts | Low | Test failures | Phase 3 verification catches this before any logic changes |
| Future contributors edit mario.p8 __lua__ directly instead of src/ | Medium | Drift between source and cart | Document in AGENTS.md; add a CI check or pre-commit hook that verifies mario.p8 matches assembled output |

**Rollback:** At any phase, if verification fails:
1. `git checkout mario.p8` restores the working cart
2. `git checkout spec/helper.lua` restores the test loader
3. Delete `src/` directory
4. The project is back to its pre-migration state with zero impact

The migration is purely structural -- no game logic changes at any phase. This means rollback is always safe and complete.
