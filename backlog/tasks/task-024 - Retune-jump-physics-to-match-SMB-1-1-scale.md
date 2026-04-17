---
id: TASK-024
title: Retune jump physics to match SMB 1-1 scale
status: To Do
assignee: []
created_date: '2026-04-17 22:26'
labels: []
milestone: m-0
dependencies:
  - TASK-004
references:
  - maps/smb_1-1.png
  - src/constants.lua
  - src/states.lua
  - src/player.lua
priority: high
ordinal: 4500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Current jump constants undershoot the SMB 1-1 map scale: row-8 coins (66-68) are unreachable, high row-6 blocks are unreachable, and the iconic staircase-to-pole-top high-score flag jump is impossible. Map was authored to SMB scale in TASK-004, but src/constants.lua physics was set for an earlier smaller layout. Retune jump_str and run_jump_str to restore reachability without changing the level layout.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Walking jump can land on top of row-10 ? block from ground (current: can only head-bump)
- [ ] #2 Running jump reaches row-8 coins at cols 66-68 from ground
- [ ] #3 Running jump head-bumps row-6 high blocks (star ? at col 17, bricks at cols 62-64) from ground
- [ ] #4 High-score flag jump: running jump off col-97 staircase top reaches pole_top at (108, 6)
- [ ] #5 Flag still reachable via the walk-off-and-fall path (no regression)
- [ ] #6 Walking jump still clears pit 1 (cols 52-53) and pit 2 (cols 72-73) and pit 3 (cols 87-88)
- [ ] #7 Cart plays through end-to-end without soft-locks
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
### Evidence (verified by frame-step physics sim against the parsed cart map)

Current physics (src/constants.lua:7-13):
- `grav = 0.4`, `max_fall = 3`
- `jump_str = -4.16`, `run_jump_str = -5.2`
- `move_spd = 1.2`, `run_spd = 2.0`

Derived reach (cumul rise = sum of `|jump_str| - grav*i` while positive):
- Walking jump rise: **19.6 px = 2.45 tiles**. Apex `p.y = 84.4` from ground (y=104).
- Running jump rise: **31.2 px = 3.90 tiles**. Apex `p.y = 72.8` from ground.

Reachability failures confirmed by sim:
1. Coins at `(66-68, 8)` — tile y-range 64–72. Running-jump apex `p.y = 72.8` never enters that range. Check-points are `p.y` and `p.y+4`, both floor to row 9 at apex. Unreachable from ground; also unreachable via any nearby pipe top (pipes at cols 36-37 and 44-45 are 21+ tiles away from col 66, beyond any jump arc).
2. High `?` at `(17, 6)` and high bricks at `(62-64, 6)` — need rise > 48 px to head-bump from ground. Current run-jump rise is 31 px.
3. Staircase-to-pole-top "high-score" flag jump — from staircase top (col 97 row 6, `p.y=40`) the running jump apex is only `p.y = 8.8`. By the time `p.x` reaches col 108 at frame ~41, `p.y` has fallen to row 10 (mid-shaft), not row 6 (pole_top).

Reachability that works today (do not regress):
- Running-jump-to-row-10 head-bump from ground (apex 72.8 enters row 10 y 80–88 during ascent at frame 4 at `p.y=87.2`).
- Running-jump LAND on top of row 10 blocks (descent at frame 14 lands at `p.y=72`).
- Flag reachable via "walk off staircase top → fall to ground → walk right into pole shaft at row 13".

### Target physics

SMB1 small-Mario heuristic (1 NES tile = 1 PICO tile):
- Walking jump should rise ~4 tiles (32 px)
- Running jump should rise ~6 tiles (48 px)

Proposed values (keep grav=0.4 so feel/timing stays familiar):
- `jump_str: -4.16 → -5.4` → rise 33.80 px ≈ 4.23 tiles
- `run_jump_str: -5.2 → -6.5` → rise 49.60 px ≈ 6.20 tiles

Keep `move_spd=1.2`, `run_spd=2.0`, `max_fall=3` unchanged. These give the required horizontal jump arc length for the level (running jump horizontal range ≈ 64 px = 8 tiles).

### Steps

1. Edit `src/constants.lua:10` and `:13` with the two new values.
2. Rebuild: `uv run scripts/generate_cart.py --no-sprites` (see CLAUDE.md: `--no-sprites` is the current safe default now that map is migrated; full build is also fine since TASK-004 migrated sprite IDs — but `--no-sprites` keeps diffs minimal).
3. Re-run the verification simulator (see Implementation Notes for full script) and confirm:
   - walk rise 33.8 px, run rise 49.6 px
   - Test 3 ("coin at (66,8)") succeeds (returns a frame where `is_coin` fires)
   - Test 5 ("running jump off staircase top") fires `is_goal` at `p.y` in row 6 (pole_top)
4. Play-test in PICO-8: `pico8 -run mario.p8`. Verify each AC manually.
5. Copy cart to iCloud per DoD.
6. (Optional) If feel is off — e.g., jumps feel floaty — try grav=0.45 and scale jump constants proportionally.

### Non-goals / out of scope

- Do NOT add acceleration-based ground movement (that is TASK-015's scope — different concern).
- Do NOT move map tiles. The layout was authored to SMB scale intentionally.
- Do NOT touch variable-jump cut (`p.dy *= 0.4` in src/states.lua:47-49) unless play-test shows short-hops feel wrong with new constants.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
### Verification simulator

Drop-in Python sim that parses `mario.p8` and runs the exact player_move/update_play loop to verify reachability without booting PICO-8. Use this to confirm each AC before play-testing.

```python
# /tmp/sim.py — physics mirror of src/player.lua + src/states.lua
# Parses mario.p8 __map__ and __gff__, steps the player at 60Hz, and checks
# coin/goal overlap using the same 4-point sample as player_check_tiles.
#
# Usage: edit the constants block at top, then `python3 /tmp/sim.py`.
```

Parsing: `__map__` is 16+ rows of 256 hex chars each (128 tiles per row, 2 hex per tile). `__gff__` first line is 256 hex chars = flag byte per sprite id. Flag bits: 0=solid, 1=hazard, 2=goal, 3=coin, 4=breakable, 5=question, 6=pipe. Frame loop order must match src/states.lua exactly: set dy on jump → variable cut → `dy += grav` → cap → move x → resolve side → move y → resolve vertical → stationary-grounded check.

### Landmark coordinates (parsed from mario.p8 as of 2026-04-17)

- spawn: (2, 13)
- first ? block: (13, 10); cluster (16-20, 10) brick-?-brick-?-brick
- high star ?: (17, 6)
- coins: (14-15, 11), (50-52, 10), (66-68, 8), (75-77, 11)
- pipes: heights 2/3/4/4 at cols 24-25, 29-30, 36-37, 44-45 (bottom at row 13)
- high bricks: (62-64, 6)
- brick-platform-over-pit-2: (71-74, 10)
- up-down hardblock staircase: cols 77-80 (up) and 82-85 (down), gap at col 81
- final ascending staircase: (90, 13) → (97, 6-13), one tile wider per step going right
- pole_top (80): (108, 6); flag (82): (108, 7); pole_shaft (81): (108, 8-13)
- castle (83-85): cols 118-122, rows 10-13
- ground (16): rows 14-15, gaps at cols 52-53, 72-73, 87-88

### Why the current values are as they are

Before TASK-004, the map was 64 tiles wide with a simpler layout authored to match the original smaller jump constants. TASK-004 replaced the map with a full 128-tile SMB 1-1 recreation but left physics untouched. No test or acceptance criterion forces these values; there are no spec files referencing `jump_str` / `run_jump_str`.

### Test impact

- No unit tests (`spec/helpers_spec.lua`) touch jump constants.
- E2E baselines (`spec/e2e_baselines/*`) are already broken (per TASK-004 notes) because they were authored for the old 64-tile map. New physics may further shift baselines. Plan to rebaseline as part of whatever follow-up task re-authors the E2E scenarios — do NOT rebaseline within this task.

### Potential feel gotchas

- Variable jump cut (`p.dy *= 0.4` when button released while rising) multiplies current dy by 0.4. With bigger `|jump_str|`, short-hop becomes proportionally bigger too: short-hop rise ≈ 0.4 × full rise. At `jump_str=-5.4` short-hop rise ≈ 13.5 px; at `run_jump_str=-6.5` short-hop rise ≈ 19.8 px. Probably fine but watch during play-test.
- With higher `run_jump_str`, a running jump can now overshoot single-tile platforms that used to be safe landing targets (staircase steps). Player may need to release jump earlier — that's the variable cut working as intended.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
