---
id: TASK-013
title: Implement big Mario power-up state
status: In Progress
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 06:23'
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
- [ ] #1 Collecting mushroom transforms small Mario into big Mario (taller sprite)
- [ ] #2 Big Mario hitbox is 6x16 pixels (two tiles tall)
- [ ] #3 Big Mario can break brick blocks by bumping from below
- [ ] #4 Getting hit as big Mario shrinks back to small Mario (with brief invincibility flash)
- [ ] #5 Getting hit as small Mario triggers death
- [ ] #6 Power-up transition has brief animation (growing/shrinking over ~0.5s)
- [ ] #7 Power-up SFX plays on transformation
- [ ] #8 Collision detection works correctly for both small and big hitboxes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
