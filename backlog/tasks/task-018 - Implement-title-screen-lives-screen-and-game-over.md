---
id: TASK-018
title: 'Implement title screen, lives screen, and game over'
status: To Do
assignee: []
created_date: '2026-04-15 20:49'
labels: []
milestone: m-4
dependencies:
  - TASK-016
priority: medium
ordinal: 18000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the game flow screens: title screen, lives/world screen, and game over screen. These wrap the gameplay loop.

Title screen: black background, game title text, 'PRESS O TO START'. On press, transition to lives screen.

Lives screen: black background, 'WORLD 1-1' text, Mario icon, 'x 3' (or current life count). Display for ~2 seconds then start gameplay.

Game over: 'GAME OVER' text centered. After ~3 seconds or button press, return to title screen.

Death flow: if lives > 0, decrement lives, show lives screen, restart level. If lives == 0, show game over screen.

This extends the current game state machine (st_play, st_dead, st_clear) with new states: st_title, st_lives, st_gameover.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Title screen shows game title and 'PRESS O TO START'
- [ ] #2 Lives screen shows 'WORLD 1-1' with Mario icon and life count
- [ ] #3 Game over screen shows 'GAME OVER' with option to restart
- [ ] #4 Death with lives remaining shows lives screen then restarts level
- [ ] #5 Death with 0 lives shows game over screen
- [ ] #6 Player starts with 3 lives
- [ ] #7 Pressing O on title screen transitions to lives screen then gameplay
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
