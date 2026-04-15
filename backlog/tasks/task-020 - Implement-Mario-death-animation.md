---
id: TASK-020
title: Implement Mario death animation
status: To Do
assignee: []
created_date: '2026-04-15 20:49'
labels: []
milestone: m-4
dependencies:
  - TASK-008
priority: low
ordinal: 20000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current instant-death behavior with the classic Mario death animation: Mario pops upward, pauses briefly at apex, then falls off the bottom of the screen. All other gameplay freezes during this animation.

Current behavior: on death, immediately spawn particles and show retry prompt. New behavior: set death animation state, give Mario an upward velocity (dy = -4), disable collision, let gravity pull him down and off screen. After ~90 frames (1.5s), show retry prompt.

During death animation: enemies and items freeze (don't update), camera freezes, only Mario and particles update. Use the death sprite (sprite 5) during animation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Mario pops upward then falls off screen on death (not instant disappear)
- [ ] #2 Death animation takes ~1.5 seconds before respawn prompt
- [ ] #3 Death SFX plays at start of animation
- [ ] #4 All gameplay pauses during death animation (enemies freeze)
- [ ] #5 Animation looks like classic Mario death (arms up, float, fall)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
