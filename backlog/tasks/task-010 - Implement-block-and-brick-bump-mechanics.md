---
id: TASK-010
title: Implement ? block and brick bump mechanics
status: Done
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 06:21'
labels: []
milestone: m-2
dependencies:
  - TASK-004
priority: high
ordinal: 875
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement interactive block mechanics: ? blocks release items when bumped from below, brick blocks can be bumped. This is the core block interaction system.

Detection: when player is moving upward (dy < 0) and head hits a tile with the question or breakable flag, trigger the bump. Use the existing head collision code in player_move as the hook point.

? block behavior: on bump, change the map tile from ? block to empty block (mset), spawn the item (coin by default, mushroom/star for specific blocks defined in a data table), play bump SFX. Coin items pop up with a short arc animation then disappear.

Brick behavior (small Mario): bump animation only, no break. Breaking bricks requires big Mario (Phase 4).

Block bump animation: offset the block sprite draw position up by 2-4 pixels for a few frames, then return. Can be done with a bumped_blocks table tracking {mx, my, timer}.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Hitting a ? block from below releases its contents and turns it into an empty block
- [x] #2 Coin pops out of ? block with upward animation then disappears
- [x] #3 Hitting a brick block from below as small Mario bumps it (no break)
- [x] #4 Block bump has visual animation (block shifts up ~2px then returns)
- [ ] #5 Bump SFX plays when hitting a block from below
- [x] #6 Coin SFX plays when coin is released from ? block
- [x] #7 Only head collision (player.dy < 0 and top of player hits bottom of block) triggers bump
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Defer bump SFX to TASK-019. Coin release uses existing sfx(1).

Plan:
1. New src/blocks.lua — bumped_blocks and pop_coins tables; spawn/update/draw for each.
2. src/helpers.lua — add bump_block(mx, my): f_question → mset to spr_hitblock, spawn pop coin, coins+=1, sfx(1); f_breakable → bump animation only; guard against re-bumping.
3. src/player.lua player_move — in p.dy<0 branch, identify hit tile and call bump_block before resolving p.y.
4. src/main.lua — wire update_bumps/update_pop_coins into _update60; draw_bumps/draw_pop_coins into _draw after map().
5. Visuals: 8-frame bump with offset=min(t,8-t); rectfill sky + spr at offset (block stays solid). Pop coin: 24 frames, dy=-2.5, gravity 0.2, 2-frame anim.
6. Add src/blocks.lua to LUA_SOURCES in scripts/generate_cart.py and spec/helper.lua.
7. Unit tests in spec/blocks_spec.lua.
8. Build with --no-sprites; run busted.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Block bump and pop-coin system implemented in new src/blocks.lua. Head-bump detection in player_move identifies hit tile(s) and delegates to bump_block helper. ? blocks release a coin (coins++, sfx(1)) and convert to spr_hitblock after 8-frame bump; bricks animate only. Visual: rectfill sky color + sprite redrawn with offset min(t, 8-t). Tile remains solid during bump. 12 unit tests in spec/blocks_spec.lua; full busted suite 49/49 green. AC#5 (bump SFX) intentionally unchecked — deferred to TASK-019 per scoping decision.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
