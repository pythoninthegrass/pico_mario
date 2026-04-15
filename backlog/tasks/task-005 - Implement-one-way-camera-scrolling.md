---
id: TASK-005
title: Implement one-way camera scrolling
status: To Do
assignee: []
created_date: '2026-04-15 20:47'
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
- [ ] #1 Camera only scrolls right, never left
- [ ] #2 Small dead zone before camera starts following player rightward
- [ ] #3 Camera clamps to map bounds
- [ ] #4 Player cannot walk off the left edge of the visible screen
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
