---
id: TASK-012
title: Implement hidden blocks and multi-coin bricks
status: In Progress
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 06:23'
labels: []
milestone: m-2
dependencies:
  - TASK-010
priority: low
ordinal: 328.125
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement special block types from SMB 1-1: hidden blocks (invisible until bumped from below) and multi-coin bricks (dispense multiple coins on repeated bumps).

Hidden blocks: not drawn on map, but a data table marks their positions. When player head-bumps the position, the block appears as an empty block and releases its item (usually 1-up mushroom). In 1-1 there is one hidden 1-up block.

Multi-coin bricks: a specific brick that gives a coin each time it's bumped, up to 10 coins. After 10 bumps or a time limit (~4 seconds), it becomes an empty block. In 1-1 there is one multi-coin brick.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hidden blocks are invisible until hit from below
- [ ] #2 Hitting a hidden block from below reveals it as a solid empty block
- [ ] #3 Hidden 1-up block at correct 1-1 position gives extra life
- [ ] #4 Multi-coin brick dispenses coins on repeated bumps (up to 10)
- [ ] #5 Multi-coin brick becomes empty block after coins exhausted or time expires
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
