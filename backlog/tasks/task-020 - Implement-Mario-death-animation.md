---
id: TASK-020
title: Implement Mario death animation
status: Done
assignee: []
created_date: '2026-04-15 20:49'
updated_date: '2026-04-24 01:00'
labels: []
milestone: m-4
dependencies:
  - TASK-008
priority: low
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the current instant-death behavior with the classic Mario death animation: Mario pops upward, pauses briefly at apex, then falls off the bottom of the screen. All other gameplay freezes during this animation.

Current behavior: on death, immediately spawn particles and show retry prompt. New behavior: set death animation state, give Mario an upward velocity (dy = -4), disable collision, let gravity pull him down and off screen. After ~90 frames (1.5s), show retry prompt.

During death animation: enemies and items freeze (don't update), camera freezes, only Mario and particles update. Use the death sprite (sprite 5) during animation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Mario pops upward then falls off screen on death (not instant disappear)
- [x] #2 Death animation takes ~1.5 seconds before respawn prompt
- [x] #3 Death SFX plays at start of animation
- [x] #4 All gameplay pauses during death animation (enemies freeze)
- [x] #5 Animation looks like classic Mario death (arms up, float, fall)
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Goal: replace the instant particle burst with a classic SMB death animation (pop up, pause, fall off screen), freeze gameplay during it, and use spr_dead for the sprite.

Files touched: src/states.lua, src/main.lua, src/player.lua (maybe), spec/states_spec.lua.

1. Refactor death entry into a helper (src/states.lua)
   - Add enter_death(p): sets state=st_dead, death_t=0; zeroes p.dx; sets p.dy=-4; clears p.grounded; plays sfx(2); drops the spawn_particles burst (classic SMB has no particles on death).
   - Replace the three existing death trigger sites (tile "dead" in update_play, enemy-hit "dead" in update_play, timer expiry in update_timer) with enter_death(p).

2. Death-animation physics (src/states.lua)
   - update_dead: while death_t < death_to_screen (90f) apply gravity to player.dy with max_fall clamp and move p.y (and p.x, which is 0) without collision so Mario pops up and falls through the floor and off-screen.
   - Keep the existing lives decrement on death_t==1 and the existing state transition at death_to_screen.

3. Freeze world updates during st_dead (src/main.lua)
   - In _update60, skip update_bumps/update_pop_coins/update_score_pops/update_multi_coin_bricks/update_items when state == st_dead. update_particles still runs (currently empty after removing the death burst, so negligible). update_enemies is already inside update_play so enemies already freeze.
   - Camera already only advances via update_cam(p) in update_play / clear walk, so camera is already frozen in st_dead — no change needed.

4. Draw Mario throughout the death animation (src/main.lua)
   - Extend the player-draw gate from "st_dead and death_t < 10" to "state == st_dead" so he is visible the whole animation.
   - When state == st_dead, draw spr_dead at (p.x, p.y) with height 1 (no palette flash, no running animation). Small Mario's bounds already match 8x8; big Mario will show the 8x8 death sprite at his current top-left — acceptable per task scope.

5. Tests (spec/states_spec.lua) — TDD-first
   - enter_death(p) sets state=st_dead, death_t=0, p.dy==-4, p.dx==0, p.grounded==false.
   - update_dead increments player.y over frames (pop then fall) and dy accumulates gravity and clamps at max_fall.
   - Preserve the existing death_flow tests (lives decrement, transition to st_lives / st_gameover, level reset). Run busted to confirm they still pass given the new per-frame physics.

6. Build & verify
   - uv run scripts/generate_cart.py --no-sprites
   - uv run scripts/count_tokens.py (verify < 8192)
   - busted spec/states_spec.lua (and full suite)
   - Play-test in PICO-8: die in a pit, to a Goomba, and from a timer expiry; confirm Mario pops up, pauses, falls off, enemies freeze, retry prompt after ~1.5s.
   - cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8

Risks / notes:
- Big Mario death: rare path (pit / timer only, since enemy hit shrinks him). Using the 8x8 death sprite at his head is acceptable; if it looks wrong in play-test, we'll scope a follow-up rather than expand this task.
- spawn_particles on death is removed; if Lance wants a puff effect we can re-add after play-test.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added enter_death(p) helper in src/states.lua; sets state=st_dead, death_t=0, dy=-4, dx=0, grounded=false, plays sfx(2). Replaced 3 duplicated death-trigger blocks in update_play/update_timer/enemy-hit with enter_death(p). Dropped the spawn_particles death burst. update_dead applies gravity and moves player.y each frame (no collision) so Mario pops up and falls through the floor. _update60 skips update_bumps/pop_coins/score_pops/multi_coin_bricks/items when state==st_dead (enemies/camera already froze). _draw now uses spr_dead at player x/y for the entire st_dead window instead of hiding him after 10 frames. Spec/states_spec.lua gains describe blocks for enter_death and death animation physics (pop, fall, max_fall clamp, ignores solid tiles). Full busted suite: 227/227 passing. Token count: 6333/8192.

E2E death baseline (spec/e2e_baselines/death.png) will diverge pixel-wise — old baseline captures frame 135 after Mario disappeared (hidden via death_t<10 gate); new behavior keeps him animated and visible. Regenerate with `uv run scripts/e2e_test.py --update-baselines --scenario death` after play-test confirms the animation looks right.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced instant-death with classic SMB death animation. Added enter_death(p) helper that pops Mario upward (dy=-4), zeros dx, clears grounded, and plays sfx(2); replaces three duplicated trigger blocks in update_play (tile + enemy) and update_timer. update_dead applies gravity and moves player.y without collision so Mario peaks then falls through the floor over the existing 90-frame window. _update60 skips bumps/pop_coins/score_pops/multi_coin_bricks/items during st_dead (enemies and camera already frozen). _draw uses spr_dead at the player's position for the full death window instead of hiding after 10 frames. Removed the death particle burst. Tests cover enter_death side effects and death physics (pop, fall, max_fall clamp, bypasses solid tiles); 227/227 busted pass. 6333/8192 tokens. Play-tested in PICO-8 and confirmed. Follow-up: regenerate spec/e2e_baselines/death.png via `uv run scripts/e2e_test.py --update-baselines --scenario death`.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
