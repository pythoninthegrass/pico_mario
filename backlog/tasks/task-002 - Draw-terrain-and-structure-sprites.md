---
id: TASK-002
title: Draw terrain and structure sprites
status: To Do
assignee: []
created_date: '2026-04-15 20:46'
updated_date: '2026-04-15 20:47'
labels: []
milestone: m-0
dependencies:
  - TASK-001
references:
  - maps/smb_1-1.png
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create 8x8 pixel art for all static terrain tiles needed for the 1-1 map: ground, brick, ? block (2 animation frames), empty/hit block, hard block/stone, pipe segments (top-left, top-right, body-left, body-right), flagpole (ball, shaft), flag, castle pieces (block, battlement, door).

These are the building blocks for the entire map. Use NES SMB color palette approximated to PICO-8's 16 colors. Ground = brown/orange, bricks = brown with mortar lines, ? block = yellow with ? mark, pipes = green, castle = grey/brown.

Depends on sprite sheet layout task for ID assignments.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Ground tile visually reads as brown brick ground
- [ ] #2 Brick block has visible mortar lines
- [ ] #3 ? block has yellow body with visible ? symbol and animation frame
- [ ] #4 Pipe tiles assemble into recognizable green pipes (2 wide, variable height)
- [ ] #5 Flagpole and castle tiles assemble into recognizable end-of-level structures
- [ ] #6 All sprites defined in generate_cart.py and patched into cart via uv run scripts/generate_cart.py
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
