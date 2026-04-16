---
id: TASK-001
title: Design sprite sheet layout and flag scheme
status: In Progress
assignee: []
created_date: '2026-04-15 20:46'
updated_date: '2026-04-16 20:38'
labels: []
milestone: m-0
dependencies: []
references:
  - maps/smb_1-1.png
  - AGENTS.md
  - scripts/generate_cart.py
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Plan the full 256-sprite allocation for the PICO-8 sprite sheet. Assign sprite IDs for all game objects (Mario states, terrain, pipes, enemies, items, decorations, castle, flagpole). Define the 8 flag bits used across all sprites. This plan drives every subsequent sprite and map task.

Current sprite assignments (0-9) are documented in AGENTS.md but need to be expanded to ~42 sprites. The sprite sheet is 16 sprites wide x 16 tall (128x128 pixels). Group related sprites in rows for clarity (e.g., row 0 = player, row 2 = terrain, row 3 = pipes, row 4 = enemies, etc.).

Flag bits currently: 0=solid, 1=hazard, 2=goal, 3=coin. Need to add: 4=breakable, 5=question, 6=pipe. Bit 7 reserved.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Sprite ID table covers all ~42 needed sprites with no conflicts
- [x] #2 Flag bit definitions documented (8 bits covering solid/hazard/goal/coin/breakable/question/pipe)
- [x] #3 AGENTS.md updated with new sprite and flag tables
- [x] #4 generate_cart.py updated with new sprite pixel data and flag assignments
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
generate_cart.py already had full SPRITES (42 sprites) and SPRITE_FLAGS dicts from prior work. This task finalized the design by: (1) adding spr_* ID constants and f_breakable/f_question/f_pipe flag constants to constants.lua, (2) replacing the planned/current tables in architecture.md with finalized per-row tables, (3) adding the sprite sheet summary to AGENTS.md. Cart builds successfully with --no-sprites. Unit tests have a pre-existing failure (PICO-8 += syntax not supported by standard Lua parser in test shim) unrelated to this task.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
