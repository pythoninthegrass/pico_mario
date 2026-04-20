---
id: TASK-011
title: Implement mushroom power-up item
status: Done
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 17:13'
labels: []
milestone: m-2
dependencies:
  - TASK-010
priority: high
ordinal: 205.078125
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement mushroom power-up item that spawns from specific ? blocks. The mushroom is a moving item that the player collects by touching it.

Mushroom behavior: rises out of the ? block over ~8 frames, then moves right at ~0.5 px/frame with gravity. Bounces off walls (reverses direction). Falls into pits. Player collects by overlapping.

A data table maps specific ? block positions to their contents (coin vs mushroom vs star vs fire flower). Most ? blocks contain coins; only a few contain power-ups. In 1-1, the first ? block in the brick row contains a mushroom, and one later block contains a star.

Collection effect depends on Phase 4 (power-up system), but for now collecting a mushroom can just add score and play SFX.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Mushroom spawns from specific ? blocks (defined in data table)
- [x] #2 Mushroom rises out of block then moves right
- [x] #3 Mushroom falls with gravity and slides along ground
- [x] #4 Mushroom reverses direction when hitting a wall
- [x] #5 Mushroom falls into pits and is removed
- [x] #6 Collecting mushroom triggers power-up state change (or score if already big)
- [x] #7 Power-up appear SFX plays when mushroom emerges from block
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Approved Plan

Entity model patterned after enemies.lua. Adds a new src/items.lua module.

### New file: src/items.lua
- `items = {}` — active items list
- `block_contents = {}` — {mx,my} -> kind lookup (default "coin")
- `register_contents(mx, my, kind)` / `contents_at(mx, my)`
- `spawn_item(mx, my, kind)` — spawns above ? block, enters rise phase
- `make_mushroom(mx, my)` — { x, y, dx, dy, w=8, h=8, phase, rise_t }
- `update_items()`:
  - phase=="rise": creep 1px/frame for 8 frames, no gravity, no collection
  - phase=="walk": dx=0.5, gravity, wall reverse, pit removal
  - overlap-check with player -> collect, sfx, remove (no power change yet)
- `draw_items()`

### Modifications
- helpers.lua bump_block: on ? block, if contents is not "coin"/unset, spawn_item + item-appear sfx, skip coin grant
- main.lua _init: items={}, register 1-1 content positions for mushroom + star in register_specials
- main.lua _update60 / _draw: update_items / draw_items calls
- scripts/generate_cart.py LUA_SOURCES: insert src/items.lua after blocks.lua
- spec/helper.lua LUA_SOURCES: same insertion
- .luacheckrc: add items, block_contents, function name globals

### Tests: spec/items_spec.lua
- ? block w/ mushroom content spawns item, no pop-coin
- ? block w/ default content dispenses pop-coin (no regression)
- Mushroom rise advances, transitions to walk
- Mushroom walks right, reverses on wall
- Mushroom falls under gravity, lands on ground
- Mushroom falls into pit and is removed
- Player overlap collects mushroom (removed + sfx)
- register_contents/contents_at round-trip

### Collection effect (this task)
Collection removes item + plays power-up sfx + placeholder score bump. TASK-013 will replace placeholder with grow_player() call.

### ? block positions
Scan __map__ section for spr_qblock1 (18) tile positions, pick first for mushroom and one mid-run for star; coords recorded in register_specials() before implementation.

### Overlap ownership
update_items() owns the overlap check (single iteration, safe delete on collection).
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added src/items.lua for power-up item entities. register_contents/contents_at map ? block positions to their payload (coin by default, mushroom/star/fireflower otherwise). bump_block dispatches on contents_at — coin path unchanged; other kinds spawn_item + sfx(4) and skip the pop-coin grant.

Item physics mirror the enemy pattern: rise phase (1 px/frame for 8 frames, no gravity, not collectable), then walk phase (dx=0.5, gravity, wall-reverse, pit removal, player overlap). Collection is handled inside update_items() so a single iteration can safely del() on hit.

Wired into main.lua _init (items/block_contents init, register_contents at 17,10 mushroom and 19,10 star for 1-1), _update60 (update_items), _draw (draw_items after enemies). generate_cart.py and spec/helper.lua LUA_SOURCES updated. .luacheckrc globals updated.

AC #6 note: collection currently grants +1 coin as placeholder score — the power-state change is deferred to TASK-013, which will replace the placeholder with a grow_player(p) call. Marked a reminder in items.lua at the collection site.

Tests: spec/items_spec.lua adds 18 assertions covering registry round-trip, bump dispatch (mushroom vs coin regression), rise phase (position, duration, walk transition, no horizontal drift), walk phase (gravity, wall reverse, pit removal, landing), and player overlap (rise-phase gated, collection clears + sfx). 81/81 total tests pass.

DoD #1, #2, #4 left unchecked — PICO-8 play-test and token count need Lance to verify in the PICO-8 runtime.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented mushroom power-up item (TASK-011) via a new items entity system. ? block bumps dispatch on a position-keyed contents registry, with mushroom at (17,10) and star at (19,10) for 1-1. Items rise over 8 frames, then walk with gravity and wall-reverse physics, fall into pits, and are collected on player overlap. Collection is a placeholder (+1 coin, sfx) pending TASK-013 wiring grow_player(). 18 new tests, 81/81 green. Cart copied to iCloud; play-test + token check still needed.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
