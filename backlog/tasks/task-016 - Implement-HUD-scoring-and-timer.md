---
id: TASK-016
title: 'Implement HUD, scoring, and timer'
status: To Do
assignee: []
created_date: '2026-04-15 20:49'
labels: []
milestone: m-4
dependencies:
  - TASK-008
priority: high
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the full HUD display and scoring system. The HUD shows at the top of the screen: score, coin count, world label, timer, and lives.

Layout (matching NES): MARIO / score on left, coin icon + count in center-left, WORLD 1-1 in center, TIME / countdown on right.

Scoring: coins = 200 pts, stomp chain = 100/200/400/800/1000, block coin = 200, mushroom = 1000, star = 1000, 1-up = no points (extra life).

Timer: counts down from 400. When it reaches 100, music speeds up (timer warning). When it reaches 0, player dies. Remaining time at level clear converts to score (50 pts per tick).

Lives: start at 3. Lose one on death. Game over at 0. 1-up mushroom adds one.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Score displayed at top-left of screen
- [ ] #2 Coin counter with coin icon displayed
- [ ] #3 Timer counts down from 400 (1 tick per ~0.4 seconds to match NES pace)
- [ ] #4 Lives counter displayed
- [ ] #5 WORLD 1-1 label displayed
- [ ] #6 HUD is screen-fixed (does not scroll with camera)
- [ ] #7 Score increases on coin collect (+200), enemy stomp (+100-1000), block coin (+200)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
