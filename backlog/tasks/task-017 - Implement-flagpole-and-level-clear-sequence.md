---
id: TASK-017
title: Implement flagpole and level clear sequence
status: In Progress
assignee: []
created_date: '2026-04-15 20:49'
updated_date: '2026-04-20 21:58'
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
- [ ] #1 Touching flagpole triggers level clear sequence
- [ ] #2 Mario slides down flagpole to base
- [ ] #3 Score awarded based on height of flagpole grab
- [ ] #4 After sliding down, Mario walks right toward castle
- [ ] #5 Mario enters castle door and disappears
- [ ] #6 Timer remaining converts to score (50 pts per tick with fast countdown)
- [ ] #7 Level clear fanfare plays
- [ ] #8 After sequence completes, game restarts (or shows victory screen)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
