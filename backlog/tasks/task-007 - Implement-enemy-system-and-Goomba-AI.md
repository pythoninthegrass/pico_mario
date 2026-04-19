---
id: TASK-007
title: Implement enemy system and Goomba AI
status: In Progress
assignee:
  - claude
created_date: '2026-04-15 20:47'
updated_date: '2026-04-19 08:17'
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
- [ ] #1 Goombas walk left at constant speed
- [ ] #2 Goombas reverse direction when hitting a wall or pipe
- [ ] #3 Goombas fall into pits and are removed
- [ ] #4 Goombas animate between 2 walk frames
- [ ] #5 Enemies only spawn when camera approaches their map position (not all at once)
- [ ] #6 Enemy spawn positions defined in a data table (not hardcoded in map tiles)
- [ ] #7 Maximum ~6 active enemies on screen at once to stay within CPU budget
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
New file src/enemies.lua between particles.lua and main.lua. Contains: enemy_spawns table (17 entries from docs/smb_1-1_enemies.md, sorted by X), enemies active list, next_spawn cursor. Functions: make_enemy(), init_enemies(), spawn_enemies() (trigger at cam_x+144), update_enemies() (move 0.5px/frame left, gravity, wall reversal, pit removal, animation), draw_enemies(). Enemy object: {x,y,dx,dy,w=6,h=8,etype,frame,frame_t,spr1,spr2}. New constants: enemy_spd=0.5, max_enemies=6. Modify main.lua (_init, update_play, _draw), spec/helper.lua LUA_SOURCES, generate_cart.py LUA_SOURCES. TDD: spec/enemies_spec.lua covering all 7 ACs.
<!-- SECTION:PLAN:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
