---
id: TASK-007
title: Implement enemy system and Goomba AI
status: Done
assignee:
  - claude
created_date: '2026-04-15 20:47'
updated_date: '2026-04-19 15:59'
labels: []
milestone: m-1
dependencies:
  - TASK-004
  - TASK-006
references:
  - docs/smb_1-1_enemies.md
priority: high
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the enemy object system and Goomba AI. Enemies are code objects (not map tiles) that spawn when the camera scrolls near their defined position.

Enemy system needs: an enemies table, a spawn table with (x, y, type) entries for each enemy in 1-1, a spawn check each frame (spawn when enemy.x < cam_x + 144), per-enemy update (move, animate, gravity, wall collision, pit death), and per-enemy draw.

Goomba behavior: walk left at ~0.5 px/frame, reverse on wall hit, fall with gravity, die when falling off map bottom. No player interaction yet (stomping is a separate task).

SMB 1-1 has ~16 goombas and 1 koopa. Start with goombas only; koopa is a separate task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Goombas walk left at constant speed
- [x] #2 Goombas reverse direction when hitting a wall or pipe
- [x] #3 Goombas fall into pits and are removed
- [x] #4 Goombas animate between 2 walk frames
- [x] #5 Enemies only spawn when camera approaches their map position (not all at once)
- [x] #6 Enemy spawn positions defined in a data table (not hardcoded in map tiles)
- [x] #7 Maximum ~6 active enemies on screen at once to stay within CPU budget
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
New file src/enemies.lua between particles.lua and main.lua. Contains: enemy_spawns table (17 entries from docs/smb_1-1_enemies.md, sorted by X), enemies active list, next_spawn cursor. Functions: make_enemy(), init_enemies(), spawn_enemies() (trigger at cam_x+144), update_enemies() (move 0.5px/frame left, gravity, wall reversal, pit removal, animation), draw_enemies(). Enemy object: {x,y,dx,dy,w=6,h=8,etype,frame,frame_t,spr1,spr2}. New constants: enemy_spd=0.5, max_enemies=6. Modify main.lua (_init, update_play, _draw), spec/helper.lua LUA_SOURCES, generate_cart.py LUA_SOURCES. TDD: spec/enemies_spec.lua covering all 7 ACs.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added src/enemies.lua containing enemy_spawns (16 goombas at row 13), enemies/next_spawn state, and make_enemy/init_enemies/spawn_enemies/update_enemies/draw_enemies. Constants enemy_spd=0.5 and max_enemies=6 in src/constants.lua. Wired init_enemies into _init, spawn_enemies/update_enemies into update_play, and draw_enemies into _draw. Concatenation order updated in scripts/generate_cart.py, scripts/e2e_smoke.py, and spec/helper.lua. Koopa #5 from docs/smb_1-1_enemies.md intentionally omitted (separate task). Spawn cap is enforced inside the while-loop without advancing next_spawn so queued enemies appear after one is removed. Walk reversal uses pixel-aligned snap. Pit removal triggers when y > map_h*8+16. New spec/enemies_spec.lua (16 tests) covers all 7 ACs; full suite 37 passes.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
