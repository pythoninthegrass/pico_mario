---
id: TASK-011
title: Implement mushroom power-up item
status: To Do
assignee: []
created_date: '2026-04-15 20:48'
labels: []
milestone: m-2
dependencies:
  - TASK-010
priority: high
ordinal: 11000
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
- [ ] #1 Mushroom spawns from specific ? blocks (defined in data table)
- [ ] #2 Mushroom rises out of block then moves right
- [ ] #3 Mushroom falls with gravity and slides along ground
- [ ] #4 Mushroom reverses direction when hitting a wall
- [ ] #5 Mushroom falls into pits and is removed
- [ ] #6 Collecting mushroom triggers power-up state change (or score if already big)
- [ ] #7 Power-up appear SFX plays when mushroom emerges from block
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
