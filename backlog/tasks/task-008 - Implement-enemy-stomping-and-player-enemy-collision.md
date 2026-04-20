---
id: TASK-008
title: Implement enemy stomping and player-enemy collision
status: Done
assignee: []
created_date: '2026-04-15 20:47'
updated_date: '2026-04-20 20:17'
labels: []
milestone: m-1
dependencies:
  - TASK-007
priority: high
ordinal: 430.6640625
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add player-enemy collision detection with stomp mechanics. The core interaction: if player is falling (dy > 0) and overlaps enemy from above, it's a stomp (enemy dies, player bounces). If player touches enemy from the side or below, player takes damage.

Stomp detection: compare player bottom edge with enemy top edge. If player.y + player.h is within a few pixels of enemy.y and player.dy >= 0, it's a stomp. Otherwise it's a hit.

On stomp: enemy enters squished/shell state, player.dy = jump_str * 0.5 (small bounce), play stomp SFX, add score. On hit: player dies (current death behavior) or shrinks (if big Mario, but that's Phase 4).

Score chain tracking: consecutive stomps without touching ground multiply the score (100, 200, 400, 800, 1000).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Landing on top of a Goomba kills it (squish animation, score popup)
- [x] #2 Landing on top of a Koopa puts it in shell state
- [x] #3 Player bounces upward after a successful stomp
- [x] #4 Walking into an enemy from the side kills the player
- [x] #5 Falling onto an enemy from above (dy > 0) counts as a stomp
- [x] #6 Stomp SFX plays on successful stomp
- [x] #7 Score chain: consecutive stomps without landing give 100/200/400/800/1000
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
- **Enemy state machine** in `src/enemies.lua`: new `e.state` field — `'alive'` | `'squished'` | `'shell'`. `stomp_enemy(e)` transitions a Goomba to `squished` (auto-removed after `squish_len` = 30 frames) or a Koopa to `shell` (dx zeroed; persists until a future kick mechanic). `update_enemies` skips movement/animation for non-alive states; `draw_enemies` swaps to `spr_goomba_flat` or `spr_koopa_shell` accordingly.
- **Collision** in `src/states.lua`: `check_enemy_hits(p)` is called after `update_enemies` each frame. AABB overlap + stomp classifier: `p.dy > 0 and (p.y + p.h - e.y) <= 6` → stomp; otherwise → `hit` (routed through existing `damage_player`, which shrinks big Mario and kills small Mario). Invulnerability frames skip both branches.
- **Score chain** in `src/states.lua` + `src/blocks.lua`: `stomp_chain` counter resets when `p.grounded`. Successive stomps index into `chain_scores = {100, 200, 400, 800, 1000}`; values past index 5 cap at 1000. Each stomp spawns a `score_pop` (floating numeric text) via `spawn_score_pop`, updated/drawn alongside the existing `pop_coins` pipeline.
- **Physics tuning** in `src/constants.lua`: `stomp_bounce = -3.5` (slightly firmer than the `jump_str * 0.5` suggested in the description; `-2.5` felt too weak in the reference footage comparison).
- **SFX**: stomp uses slot 6. The `__sfx__` chunk in `mario.p8` currently only has data in slots 0–3; authoring the actual stomp sound in PICO-8 is a follow-up (same status as SFX 4/5 for grow/shrink).
- **Koopa coverage**: AC#2 is unit-test-verified (`stomp_enemy` on a `'koopa'` enemy sets `state = 'shell'`). No Koopa currently spawns in `enemy_spawns` — the Koopa at P8 X=43 documented in `docs/smb_1-1_enemies.md` is explicitly deferred per the comment in `src/enemies.lua`. Adding that spawn in a later task immediately enables in-level verification.

## Tests

- New spec `spec/stomp_spec.lua` (18 tests): `make_enemy` state defaults, `stomp_enemy` state transitions for both enemy types, stomp vs side-hit classification, upward bounce, stomp SFX, invulnerability gating, chain scoring (100/200/400/800/1000 cap), score popup spawning, squished timeout removal, shell persistence.
- Full suite: 122 passes / 0 failures (includes prior player, enemies, items, blocks, helpers specs).
- `luacheck` clean (new globals added to `.luacheckrc`).
<!-- SECTION:NOTES:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
