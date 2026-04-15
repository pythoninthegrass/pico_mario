---
id: TASK-015
title: Implement acceleration-based movement physics
status: To Do
assignee: []
created_date: '2026-04-15 20:49'
labels: []
milestone: m-3
dependencies:
  - TASK-004
priority: medium
ordinal: 15000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current instant-speed movement with acceleration-based physics to match the NES Mario feel. Currently p.dx is set directly to move_spd or 0 each frame. Instead, apply acceleration toward target speed and friction to decelerate.

Ground movement: accelerate toward target speed (move_spd or run_spd depending on X button) at ~0.1 px/frame^2. Friction when no input: decelerate at ~0.15 px/frame^2. Skid when reversing: higher deceleration (~0.2) with skid animation.

Air movement: reduced acceleration (~0.05 px/frame^2), no friction (maintain horizontal speed from takeoff). This gives the characteristic Mario feel of committing to a jump direction.

These values will need tuning through play-testing. The key is that movement feels weighty but responsive.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Player accelerates gradually to walk/run speed (not instant)
- [ ] #2 Player decelerates with friction when no input (slides to stop)
- [ ] #3 Air control is reduced compared to ground control
- [ ] #4 Skid occurs when reversing direction while running (brief slide in old direction)
- [ ] #5 Physics feel responsive but not twitchy at 60fps
- [ ] #6 All existing mechanics (jump, coyote time, variable jump, run) still work correctly
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
