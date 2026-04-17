---
id: TASK-005
title: Implement one-way camera scrolling
status: Done
assignee: []
created_date: '2026-04-15 20:47'
updated_date: '2026-04-17 19:14'
labels: []
milestone: m-0
dependencies: []
priority: medium
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current bidirectional smooth camera with NES-style one-way scrolling. The camera should only move right, never left. This is a defining characteristic of SMB.

Current camera code (update_cam function) uses lerp in both directions with clamping. Change to: camera tracks player rightward only, with a dead zone so small movements don't scroll. Camera X never decreases. Camera Y can remain fixed (1-1 is flat) or have minimal vertical tracking.

Also clamp camera to map bounds (0 to map_w*8-128).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Camera only scrolls right, never left
- [x] #2 Small dead zone before camera starts following player rightward
- [x] #3 Camera clamps to map bounds
- [x] #4 Player cannot walk off the left edge of the visible screen
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
update_cam rewritten: tx = p.x - 60; if tx > cam_x then cam_x = tx; clamp 0..map_w*8-128; cam_y hard-pinned to 0 (1-1 is flat). Gives a 60px left dead zone and one-way rightward tracking. player_move now locks p.x >= cam_x (and zeros p.dx if the player would have crossed the left screen edge), replacing the old map-left clamp. Added 7 new busted tests in spec/helpers_spec.lua covering no-left-scroll, dead zone, monotonic cam_x, right-edge clamp, cam_y fixed, and player left-edge lock (21/21 pass). E2E smoke launches the cart and reaches state=0 without errors; rough token estimate ~1864, well under 8192.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
