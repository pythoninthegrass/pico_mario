---
id: TASK-014
title: Implement star power-up and invincibility
status: To Do
assignee: []
created_date: '2026-04-15 20:48'
labels: []
milestone: m-3
dependencies:
  - TASK-013
priority: medium
ordinal: 14000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement star power-up: spawns from specific ? block, bounces along ground, gives temporary invincibility when collected.

Star behavior: bounces with high arc (dy = -3 on each ground hit), moves right at ~1 px/frame. Player collects by touching.

Invincibility: ~10 second timer, Mario sprite flashes (pal() color cycling each frame), touching any enemy kills it instantly. Invincibility music replaces overworld theme, reverts when timer expires.

In 1-1 there is one star block (in the brick row area).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Star bounces along ground with high arc
- [ ] #2 Collecting star gives ~10 seconds of invincibility
- [ ] #3 During invincibility Mario sprite flashes/cycles colors
- [ ] #4 Invincible Mario kills enemies on contact (no stomp needed)
- [ ] #5 Invincibility music plays during star power (reverts to normal after)
- [ ] #6 Star spawns from the correct ? block in 1-1
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
