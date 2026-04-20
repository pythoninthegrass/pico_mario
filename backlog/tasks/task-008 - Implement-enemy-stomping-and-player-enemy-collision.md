---
id: TASK-008
title: Implement enemy stomping and player-enemy collision
status: In Progress
assignee: []
created_date: '2026-04-15 20:47'
updated_date: '2026-04-20 06:22'
labels: []
milestone: m-1
dependencies:
  - TASK-007
priority: high
ordinal: 656.25
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add player-enemy collision detection with stomp mechanics. The core interaction: if player is falling (dy > 0) and overlaps enemy from above, it's a stomp (enemy dies, player bounces). If player touches enemy from the side or below, player takes damage.

Stomp detection: compare player bottom edge with enemy top edge. If player.y + player.h is within a few pixels of enemy.y and player.dy >= 0, it's a stomp. Otherwise it's a hit.

On stomp: enemy enters squished/shell state, player.dy = jump_str * 0.5 (small bounce), play stomp SFX, add score. On hit: player dies (current death behavior) or shrinks (if big Mario, but that's Phase 4).

Score chain tracking: consecutive stomps without touching ground multiply the score (100, 200, 400, 800, 1000).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Landing on top of a Goomba kills it (squish animation, score popup)
- [ ] #2 Landing on top of a Koopa puts it in shell state
- [ ] #3 Player bounces upward after a successful stomp
- [ ] #4 Walking into an enemy from the side kills the player
- [ ] #5 Falling onto an enemy from above (dy > 0) counts as a stomp
- [ ] #6 Stomp SFX plays on successful stomp
- [ ] #7 Score chain: consecutive stomps without landing give 100/200/400/800/1000
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
