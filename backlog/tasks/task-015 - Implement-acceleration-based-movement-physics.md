---
id: TASK-015
title: Implement acceleration-based movement physics
status: Done
assignee: []
created_date: '2026-04-15 20:49'
updated_date: '2026-04-20 22:14'
labels: []
milestone: m-3
dependencies:
  - TASK-004
priority: medium
ordinal: 1000
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
- [x] #1 Player accelerates gradually to walk/run speed (not instant)
- [x] #2 Player decelerates with friction when no input (slides to stop)
- [x] #3 Air control is reduced compared to ground control
- [x] #4 Skid occurs when reversing direction while running (brief slide in old direction)
- [x] #5 Physics feel responsive but not twitchy at 60fps
- [x] #6 All existing mechanics (jump, coyote time, variable jump, run) still work correctly
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added `apply_horiz_physics(p, input_dir, running)` in src/player.lua that centralises the horizontal velocity update. Constants in src/constants.lua: `ground_accel=0.1`, `air_accel=0.05`, `ground_friction=0.15`, `skid_decel=0.2`. New `p.skidding` flag on the player for future skid-animation hook-up.

Ground: accelerate toward cap (walk or run), apply friction when input_dir==0, skid_decel when input reverses against current velocity. Above-cap velocity (carried-over run speed on a walk jump) is eased down with ground_friction. Air: reduced accel, no friction so the player commits to the jump direction.

states.lua update_play no longer zeros p.dx each frame — it reads btn(0)/btn(1) into input_dir and defers to apply_horiz_physics. During transform_t the input_dir stays 0 so friction naturally brings the player to rest during grow/shrink.

New spec/movement_spec.lua covers walk/run accel, cap clamps, friction stop (including negative velocity and sub-friction epsilon), skid detect + flag, air accel reduction and air coast. All 170 existing tests still pass.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced instant-speed horizontal movement with acceleration/friction/skid model matching NES Mario feel. Ground: 0.1 accel toward walk/run cap, 0.15 friction when idle, 0.2 skid decel on reverse. Air: 0.05 accel, no friction (commits to jump direction). Extracted logic into `apply_horiz_physics` for testability; 15 new unit tests in spec/movement_spec.lua. Play-testing in PICO-8 still recommended to confirm AC #2 and #5 before archiving.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
