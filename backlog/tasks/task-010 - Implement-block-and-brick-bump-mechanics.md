---
id: TASK-010
title: Implement ? block and brick bump mechanics
status: To Do
assignee: []
created_date: '2026-04-15 20:48'
labels: []
milestone: m-2
dependencies:
  - TASK-004
priority: high
ordinal: 10000
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
- [ ] #1 Hitting a ? block from below releases its contents and turns it into an empty block
- [ ] #2 Coin pops out of ? block with upward animation then disappears
- [ ] #3 Hitting a brick block from below as small Mario bumps it (no break)
- [ ] #4 Block bump has visual animation (block shifts up ~2px then returns)
- [ ] #5 Bump SFX plays when hitting a block from below
- [ ] #6 Coin SFX plays when coin is released from ? block
- [ ] #7 Only head collision (player.dy < 0 and top of player hits bottom of block) triggers bump
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
