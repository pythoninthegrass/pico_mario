---
id: TASK-018
title: 'Implement title screen, lives screen, and game over'
status: Done
assignee: []
created_date: '2026-04-15 20:49'
updated_date: '2026-04-22 17:51'
labels: []
milestone: m-4
dependencies:
  - TASK-016
priority: medium
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the game flow screens: title screen, lives/world screen, and game over screen. These wrap the gameplay loop.

Title screen: sky-blue background with HUD bar at top and ground/hill/bush scenery strip at bottom (matches SMB 1-1 reference). 'SUPER MARIO BROS.' logo centered, '(C)1985 NINTENDO' credit, 'PRESS O TO START' prompt. On press, transition to lives screen.

Lives screen: black background, HUD bar at top, 'WORLD 1-1' text centered, Mario icon and 'x 3' (or current life count) below. Display for ~2 seconds then start gameplay.

Game over: black background, 'GAME OVER' text centered. After ~3 seconds or button press, return to title screen.

Death flow: if lives > 0, decrement lives, show lives screen, restart level. If lives == 0, show game over screen.

This extends the current game state machine (st_play, st_dead, st_clear) with new states: st_title, st_lives, st_gameover.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Title screen shows 'PICO MARIO' title and 'PRESS O TO START'
- [x] #2 Title screen renders sky background, HUD bar at top, and ground/scenery strip at bottom
- [x] #3 Lives screen shows HUD bar, 'WORLD 1-1', Mario icon, and life count
- [x] #4 Game over screen shows 'GAME OVER' with option to restart
- [x] #5 Death with lives remaining shows lives screen then restarts level
- [x] #6 Death with 0 lives shows game over screen
- [x] #7 Player starts with 3 lives
- [x] #8 Pressing O on title screen transitions to lives screen then gameplay
- [x] #9 Lives screen auto-advances to gameplay after ~2 seconds
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Reference observations from `maps/smb_1-1.mp4` (first 4 seconds, frames in `/tmp/smb_frames/`):

**Title screen (0.0-1.0s):**
- Sky-blue background (palette: `#5C94FC`, PICO-8 color 12).
- HUD bar along the top: `MARIO / 000000`, coin icon `x03`, `WORLD 1-1`, `TIME` labels. Uses the top-score value from a prior run (reference shows `002000`).
- Centered orange plaque with `SUPER MARIO BROS.` logo and `©1985 NINTENDO` underneath. For this clone, substitute our own title text (e.g. `MARIO-ISH` or retain `SUPER MARIO BROS.`); confirm wording with Lance before hard-coding.
- Menu lines `1 PLAYER GAME` / `2 PLAYER GAME` with mushroom cursor, plus `TOP- 002000` under them. We collapse this to `PRESS O TO START` since the clone is single-player.
- Ground strip (brown bricks), small hill, and two bushes along the bottom quarter — reuse the existing level-start tile strip for continuity.

**Lives screen (1.5-3.0s):**
- Pure black background with HUD bar still visible at the top (same layout as title screen but `MARIO 000000 x00`).
- Centered `WORLD 1-1` (white), with `<mario-sprite> x 3` on the line below. Approximate vertical position: row 64-80 in 128px PICO-8 coordinates.
- Transitions to gameplay at ~3.5s via a brief full-black fade (frame 08).

**State machine additions (`src/constants.lua`, `src/main.lua`, `src/states.lua`):**
- Add `st_title`, `st_lives`, `st_gameover` constants.
- `_init()` should enter `st_title` (not `st_play`).
- `update_title`: wait for `btnp(4)` (O = button 4), then set `state=st_lives` with a ~120-frame timer.
- `update_lives`: decrement timer; at 0 call `start_level()` and `state=st_play`.
- `update_gameover`: decrement timer; on 0 or `btnp(4)`, reset lives to 3 and `state=st_title`.
- Extend `update_dead` end-branch: if `lives>0` decrement and `state=st_lives`; else `state=st_gameover`.

**Drawing helpers:**
- Factor the HUD draw into a reusable function (used by title, lives, and play states).
- Reuse sprite `spr_idle` (small Mario) for the lives-screen icon.

**Open questions / flags:**
- Title screen logo: confirm whether to render `SUPER MARIO BROS.` text (risks copyright concerns) or a custom title.
- Music: reference plays the SMB title jingle; may be out of scope for this task, defer to a follow-up SFX task if needed.
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
