---
id: TASK-003
title: Draw background decoration sprites
status: In Progress
assignee: []
created_date: '2026-04-15 20:47'
updated_date: '2026-04-17 23:24'
labels: []
milestone: m-0
dependencies:
  - TASK-001
references:
  - maps/smb_1-1.png
priority: low
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create 8x8 pixel art for background decoration tiles: clouds (3 tiles: left, mid, right), bushes (3 tiles: left, mid, right), hills (3 tiles: body, top, edge). These are non-interactive scenery placed behind the playable layer.

In SMB 1-1, clouds and bushes share the same shape (just different colors: white vs green). Hills are green mounds in the background. These repeat in a pattern across the level.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Cloud tiles assemble into recognizable white clouds
- [ ] #2 Bush tiles assemble into recognizable green bushes
- [ ] #3 Hill tiles form green background mounds
- [ ] #4 Decoration sprites have no flags set (non-interactive)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
