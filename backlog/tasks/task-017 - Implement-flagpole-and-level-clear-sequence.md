---
id: TASK-017
title: Implement flagpole and level clear sequence
status: Done
assignee: []
created_date: '2026-04-15 20:49'
updated_date: '2026-04-22 17:19'
labels: []
milestone: m-4
dependencies:
  - TASK-004
  - TASK-016
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the end-of-level sequence: flagpole grab, slide down, walk to castle, enter castle, score tally.

When player touches the flagpole tile, enter a cutscene state: player snaps to flagpole x position, slides down at ~1 px/frame, flag slides down simultaneously. At bottom, player walks right toward castle entrance. Player disappears into castle door.

Then: timer counts down rapidly (each tick = 50 pts added to score), level clear fanfare plays. After tally, brief pause then restart or victory screen.

Flagpole height scoring: top = 5000, upper = 2000, middle = 800, lower = 400, bottom = 100.

This replaces the current simple goal-flag detection.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Touching flagpole triggers level clear sequence
- [x] #2 Mario slides down flagpole to base
- [x] #3 Score awarded based on height of flagpole grab
- [x] #4 After sliding down, Mario walks right toward castle
- [x] #5 Mario enters castle door and disappears
- [x] #6 Timer remaining converts to score (50 pts per tick with fast countdown)
- [x] #7 Level clear fanfare plays
- [x] #8 After sequence completes, game restarts (or shows victory screen)
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Fixed two bugs in the clear sequence (2026-04-21):

1. Mario underground after slide: pole_bottom_y (104) was hardcoded for small Mario (h=8). Big Mario (h=16) ended up with feet at y=120, 8px below ground (y=112). Fix: enter_clear now computes slide_target_y = 112 - p.h so both small and big Mario land with feet at the ground surface. cp_slide uses slide_target_y instead of pole_bottom_y for the player position.

2. Flag separated from pole: mset(flag_map_x, flag_map_y, 0) left a gap in the pole shaft when the flag tile slid away. Fix: replace with spr_pole_shaft instead of 0 so the pole stays visually continuous as the flag slides down.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
