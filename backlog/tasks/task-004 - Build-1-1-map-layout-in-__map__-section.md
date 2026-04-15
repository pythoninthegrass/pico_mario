---
id: TASK-004
title: Build 1-1 map layout in __map__ section
status: To Do
assignee: []
created_date: '2026-04-15 20:47'
updated_date: '2026-04-15 20:47'
labels: []
milestone: m-0
dependencies:
  - TASK-002
references:
  - maps/smb_1-1.png
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Recreate SMB 1-1 in the PICO-8 128x16 tile map. The NES level is ~210 columns at 16px per tile. PICO-8 uses 8px tiles with 128 columns available, giving 1024px total width. Strategy: compress empty space between landmarks while preserving relative distances and gameplay feel.

Key landmarks from the reference map (left to right):
- Spawn area with initial coins
- First ? block cluster and brick row (cols ~16-20 in NES)
- 4 pipes of increasing height
- Brick/? block rows with hidden star
- 2 pit gaps with ground breaks
- Staircase pyramids (ascending then descending blocks)
- Flagpole at end
- Castle after flagpole

Ground is 2 tiles thick at bottom. Pits are gaps in ground with nothing below. Pipes are 2 tiles wide, varying 2-5 tiles tall. ? blocks and bricks at specific heights above ground.

Map rows 0-15 are the overworld. Rows 16-31 can hold the underground bonus room if space permits.

The current map (64 tiles wide, simple layout) must be completely replaced.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Map uses full 128-tile width for the overworld
- [ ] #2 Ground segments match 1-1 reference with correct pit placements
- [ ] #3 4 pipes placed at correct relative positions with correct heights
- [ ] #4 Brick and ? block rows match reference layout
- [ ] #5 Staircase structures at end of level match reference
- [ ] #6 Flagpole and castle placed at level end
- [ ] #7 Coins placed at correct positions (visible map coins)
- [ ] #8 Background decorations (clouds/bushes/hills) placed in repeating pattern
- [ ] #9 map_w constant updated to 128 in Lua code
- [ ] #10 Player spawn position updated for new map layout
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
