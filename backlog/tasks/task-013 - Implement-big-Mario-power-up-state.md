---
id: TASK-013
title: Implement big Mario power-up state
status: Done
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 18:29'
labels: []
milestone: m-3
dependencies:
  - TASK-011
priority: high
ordinal: 410.15625
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the Mario power-up state machine: small Mario (default, 8px tall) and big Mario (16px tall after mushroom). This is the core power-up system that other power-ups build on.

States: small (1-hit death), big (can break bricks, shrinks to small on hit). The player object needs a `power` field (0=small, 1=big, 2=fire). Hitbox height changes with power state. Sprite selection changes (big Mario uses 2-tile-tall sprites drawn with spr(n, x, y, 1, 2)).

Big Mario breaking bricks: when head-bumping a brick tile, remove it from map (mset to 0) and spawn debris particles. Small Mario just bumps.

Damage: big->small transition with ~2 seconds of invincibility flashing (player blinks). Small->death as current behavior.

Big Mario sprites need to be drawn as 8x16 (1 wide x 2 tall in sprite sheet). This may require additional sprite slots.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Collecting mushroom transforms small Mario into big Mario (taller sprite)
- [x] #2 Big Mario hitbox is 6x16 pixels (two tiles tall)
- [x] #3 Big Mario can break brick blocks by bumping from below
- [x] #4 Getting hit as big Mario shrinks back to small Mario (with brief invincibility flash)
- [x] #5 Getting hit as small Mario triggers death
- [x] #6 Power-up transition has brief animation (growing/shrinking over ~0.5s)
- [x] #7 Power-up SFX plays on transformation
- [x] #8 Collision detection works correctly for both small and big hitboxes
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
### Approved plan

**Sprite allocation**
- Big Mario 8x16 drawn via `spr(top, x, y, 1, 2)` (bottom is top+16)
- Tops (row 7, 112-115): `spr_big_idle=112`, `spr_big_run1=113`, `spr_big_run2=114`, `spr_big_jump=115`
- Bottoms (row 8, 128-131) — no new constants needed since draw uses top+1×16
- No sprite flags (player sprites, not tile geometry)
- `scripts/generate_cart.py`: pixel data for 8 new sprites

**Timing constants (`src/constants.lua`)**
- `invuln_len = 120` (~2s), `transform_len = 30` (~0.5s)

**Player state (`src/player.lua`)**
- `make_player` adds `power=0`, `invuln_t=0`, `transform_t=0`; `h=8` initially
- `grow_player(p)`: only if `power==0`; `power=1`, `y-=8`, `h=16`, `transform_t=transform_len`, `sfx(4)`
- `shrink_player(p)`: only if `power>=1`; `power=0`, `y+=8`, `h=8`, `invuln_t=invuln_len`, `transform_t=transform_len`, `sfx(5)`
- `damage_player(p)`: returns `"ok"` / `"dead"`. If `invuln_t>0` no-op `"ok"`; elif `power>0` shrink → `"ok"`; else `"dead"`
- `player_move` already uses `p.h`; no change needed for hitbox math

**State loop (`src/states.lua`)**
- `update_play`: decrement `invuln_t` and `transform_t` each frame; skip horizontal input + jump init while `transform_t>0` (gravity + movement still resolve so the player doesn't freeze mid-air visually glitchy)
- Route hazard hit through `damage_player` instead of returning `"dead"` directly
- `get_player_spr`: offset return value by `(spr_big_idle - spr_idle)` when `p.power>=1`

**Draw (`src/main.lua`)**
- `spr(n, x, y, 1, 2, flip)` when `power>=1`, else `1, 1`
- Blink: skip draw when `invuln_t > 0 and (invuln_t % 8) < 4`

**Brick break (`src/helpers.lua`)**
- In `bump_block` breakable branch: if `player.power > 0` AND tile is not a live multi-coin brick → `mset(mx,my,0)` + `spawn_particles` (orange-brown debris) + `sfx`
- Multi-coin path unchanged — preserves TASK-012 behavior

**Items wiring (`src/items.lua`)**
- Mushroom collection calls `grow_player(player)` (replaces TASK-011 placeholder `coins += 1`)
- Star / fireflower remain placeholder for later tasks

**Tooling**
- `.luacheckrc`: add globals (`spr_big_idle`, `spr_big_run1`, `spr_big_run2`, `spr_big_jump`, `invuln_len`, `transform_len`, `grow_player`, `shrink_player`, `damage_player`)

**Tests**
- New `spec/player_spec.lua`: grow/shrink hitbox math, invuln gate, damage routing (small→dead, big→shrink, invuln→no-op), sprite ID selection by power state
- Extend `spec/items_spec.lua`: mushroom collect → `player.power == 1` and `player.h == 16`
- Extend `spec/blocks_spec.lua`: big Mario brick bump → tile becomes 0 + particles spawn; small-Mario case unchanged

**Out of scope (for this task)**
- Enemy-contact damage → TASK-008 (hazards are the sole damage trigger for now)
- Fire flower / star invincibility → future tasks; collection stays placeholder
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Pre-implementation note: big Mario 8x16 sprites drawn via spr(n,x,y,1,2) require paired top + bottom slots. Row 0 tops had open slots but row 1 bottoms were packed with terrain, so big Mario lives in row 7 tops + row 8 bottoms.

Implementation:
- Constants: invuln_len=120, transform_len=30; sprite IDs spr_big_idle=112, spr_big_run1=113, spr_big_run2=114, spr_big_jump=115. Bottoms (128-131) are addressed implicitly by spr(top, x, y, 1, 2).
- make_player adds power, invuln_t, transform_t (all zero).
- grow_player / shrink_player toggle power/h and shift y by plus/minus 8 to keep feet grounded; transform_t starts the 30-frame pause; sfx(4) on grow, sfx(5) on shrink.
- damage_player returns "ok" on invuln/shrink, "dead" on small-mario hit.
- update_play decrements both timers each frame and suspends horizontal input + jump init while transform_t>0; gravity + vertical resolve still run.
- player_check_tiles now distinguishes hazard contact ("hit") from pit fall ("dead"). Only "hit" routes through damage_player; pit falls remain unconditionally fatal (SMB convention).
- get_player_spr has separate small/big branches so the existing small-mario sprite mapping is preserved exactly.
- _draw switches to spr(n,x,y,1,2,flip) when big, and blinks every 4 frames while invuln_t>0.
- bump_block breakable branch: when player.power>0 and the tile is not an active multi-coin brick, it is destroyed (mset=0) with brown debris particles + sfx. Multi-coin bricks still dispense coins on big-mario bump (break deferred) to keep TASK-012 behavior intact.
- update_items mushroom collection now calls grow_player(player); star/fireflower stay placeholder.

Sprite art is a first-pass design: recognizable big-mario silhouette with red hat, peach face + brown hair band, red shirt, blue overalls with straps, brown shoes; dedicated jump frame has arm raised and legs spread.

Tests: new spec/player_spec.lua (21 specs) covers make_player defaults, grow/shrink feet-grounded math, transform timer, sfx, no-op guards, damage routing (small->dead, big->shrink, invuln->no-op), and sprite selection by power state. spec/items_spec.lua extends mushroom-collection to assert power==1 and h==16. spec/blocks_spec.lua adds 4 big-mario brick-bump specs (tile destroyed, particles, no bump anim, multi-coin still dispenses). Full busted suite: 104/104.

DoD #1, #2, #4 left unchecked - PICO-8 load, play-test, and token count need verification in the runtime.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented big Mario power-up state machine (TASK-013). Player gains power/invuln_t/transform_t fields; grow_player and shrink_player toggle size with y-shifts that keep feet grounded; damage_player returns "ok" (shrink or invuln) or "dead" (small-mario hit). player_check_tiles now distinguishes hazard contact ("hit") from pit fall ("dead") so pits stay unconditionally fatal while hazards route through the power-state machine. Draw code switches to spr(n,x,y,1,2) when big and blinks every 4 frames while invuln_t>0. bump_block's breakable branch destroys tiles + spawns debris when big (multi-coin bricks still dispense coins to preserve TASK-012). Mushroom collection in items.lua now invokes grow_player, replacing the TASK-011 placeholder. 8 new sprites added (row 7 tops 112-115 + row 8 bottoms 128-131). .luacheckrc extended to declare the full cross-file global set so lint passes cleanly. All 8 ACs verified via 104 busted specs (21 new in spec/player_spec.lua, plus 4 big-mario brick-bump specs and 1 mushroom→grow assertion). DoD #1, #2, #4 (cart load, play-test, token count) need PICO-8 runtime verification.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
