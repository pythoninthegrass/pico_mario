---
id: TASK-009
title: Implement Koopa Troopa and shell physics
status: In Progress
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-19 19:44'
labels: []
milestone: m-1
dependencies:
  - TASK-008
priority: medium
ordinal: 1421.875
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement Koopa Troopa enemy with shell mechanics. Koopa walks like Goomba but when stomped, retreats into shell instead of dying. Shell can be kicked by walking into it, and a moving shell kills other enemies on contact.

Shell states: stationary (safe to touch/kick), moving (dangerous, kills enemies and player). Stomping a moving shell stops it. Shell bounces off walls.

SMB 1-1 has 1 Koopa Troopa (green). Shell speed ~2 px/frame when kicked.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Koopa walks left, reverses on walls, animates between 2 frames
- [ ] #2 Stomping a Koopa turns it into a stationary shell
- [ ] #3 Walking into a stationary shell kicks it in that direction
- [ ] #4 Moving shell kills goombas and other enemies on contact
- [ ] #5 Moving shell bounces off walls and reverses direction
- [ ] #6 Moving shell kills player if it hits them from the side
- [ ] #7 Stomping a moving shell stops it
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
