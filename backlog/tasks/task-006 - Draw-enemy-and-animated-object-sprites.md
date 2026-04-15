---
id: TASK-006
title: Draw enemy and animated object sprites
status: To Do
assignee: []
created_date: '2026-04-15 20:47'
labels: []
milestone: m-1
dependencies:
  - TASK-001
references:
  - maps/smb_1-1.png
priority: high
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create 8x8 pixel art for all animated game objects: Mario (idle, run x2, jump, death), Goomba (walk x2, squished), Koopa (walk x2, shell), coin (2 frames). These are the sprites needed before enemies and items can be implemented.

Mario sprites replace the current placeholders (sprites 1-3). New death sprite needed. Goomba is brown with feet, Koopa is green with shell. Coin is yellow circle/rectangle with shine animation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Goomba has 2 walk animation frames and a squished frame
- [ ] #2 Koopa has 2 walk animation frames and a shell sprite
- [ ] #3 Mario has idle, run (2 frames), jump, and death sprites
- [ ] #4 Coin has 2 animation frames
- [ ] #5 All sprites defined in generate_cart.py and patched into cart
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
