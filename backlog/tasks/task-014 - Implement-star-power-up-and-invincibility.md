---
id: TASK-014
title: Implement star power-up and invincibility
status: Done
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 21:43'
labels: []
milestone: m-3
dependencies:
  - TASK-013
priority: medium
ordinal: 451.171875
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement star power-up: spawns from specific ? block, bounces along ground, gives temporary invincibility when collected.

Star behavior: bounces with high arc (dy = -3 on each ground hit), moves right at ~1 px/frame. Player collects by touching.

Invincibility: ~10 second timer, Mario sprite flashes (pal() color cycling each frame), touching any enemy kills it instantly. Invincibility music replaces overworld theme, reverts when timer expires.

In 1-1 there is one star block (in the brick row area).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Star bounces along ground with high arc
- [x] #2 Collecting star gives ~10 seconds of invincibility
- [x] #3 During invincibility Mario sprite flashes/cycles colors
- [x] #4 Invincible Mario kills enemies on contact (no stomp needed)
- [x] #5 Invincibility music plays during star power (reverts to normal after)
- [x] #6 Star spawns from the correct ? block in 1-1
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
### Approved plan

**Constants (`src/constants.lua`)**
- `invince_len = 600` (~10s at 60fps)
- `star_bounce = -3` (upward dy on each ground landing)
- `star_spd = 1` (fixed horizontal speed, 1 px/frame right)
- `flip_rise = -3` (upward dy on backflipping enemy)

**Player state (`src/player.lua`)**
- `make_player` adds `invince_t = 0`
- New `star_player(p)`: sets `invince_t = invince_len`, `sfx(7)`, `music(1)`
- `damage_player`: returns "ok" when `invince_t > 0` (takes precedence over both invuln_t and power)

**State loop (`src/states.lua`)**
- Decay `invince_t` each frame; on reaching 0 call `music(0)`
- `check_enemy_hits`: when `p.invince_t > 0`, any enemy contact flips the enemy (new helper `flip_enemy(e)`) and awards points; no damage, no bounce
- Early return for invuln_t stays as-is (post-shrink i-frames separate from star)

**Enemies (`src/enemies.lua`)**
- New state `'flipped'`: sprite drawn vertically flipped; gravity still applies; `is_solid` collision disabled so it falls through floors; removed when off map bottom
- `flip_enemy(e)`: `e.state = 'flipped'`, `e.dx = 0`, `e.dy = flip_rise`, `e.state_t = 0`
- `update_enemies`: flipped branch only applies gravity + vertical position + off-screen removal
- `draw_enemies`: draw with `flip_y = true` when state is 'flipped'

**Items (`src/items.lua`)**
- Star walk physics: `dx = star_spd` (always +1, never reverses on walls — SMB stars bounce off walls too, but MVP keeps it simple: reverse like mushroom)
- On land: `dy = star_bounce` instead of `dy = 0` (auto-bounce) when `kind == 'star'`
- Mushroom and fireflower keep current physics
- Collect branch: `star` calls `star_player(player)` (not `grow_player`)

**Draw (`src/main.lua`)**
- When `player.invince_t > 0`: `pal()` cycle colors 8,9,10,11,12 → rotated by `invince_t % 4` before `spr`, then reset `pal()` after
- Existing invuln_t blink stays for post-shrink flashing

**Tooling**
- `.luacheckrc`: add globals (`invince_len`, `star_bounce`, `star_spd`, `flip_rise`, `star_player`, `flip_enemy`, `music`)

**Tests**
- `spec/player_spec.lua`: `star_player` sets invince_t, plays sfx, calls music(1); `damage_player` no-op when invincible; invincibility precedence over power state
- `spec/items_spec.lua`: star walk physics (bounces on land, moves right), star collect triggers `star_player` and NOT `grow_player`
- `spec/stomp_spec.lua` or new `spec/invincibility_spec.lua`: enemy contact during invincibility flips enemy + awards score; flipped enemy falls through floor and is removed

**Music caveat**
- `__music__` in mario.p8 is empty (hand-authored). Wiring is in place via `music(0)` / `music(1)` calls; actual tracks require future authoring in the PICO-8 music editor. Flagged in implementation notes.

**Out of scope**
- Composed music tracks (blocked on music authoring; AC#5 structural wiring only)
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Star power-up + invincibility implemented per approved plan.

Constants: invince_len=600 (~10s), star_spd=1, star_bounce=-3, flip_rise=-3.

Player state: `invince_t` added to make_player. `star_player(p)` sets invince_t, plays sfx(7), calls music(1). `damage_player` now returns "ok" when invince_t>0 (takes precedence over invuln_t and power>0 shrink).

Items: star gets kind-specific physics — `dx = star_spd` constant, initial `dy = star_bounce` on rise-to-walk transition, and on every ground landing dy is reset to star_bounce (auto-bounce loop). Wall reverse is shared with mushroom logic. Collection branch routes star to star_player instead of grow_player.

Enemies: new `'flipped'` state. `flip_enemy(e)` sets state/dx/dy. update_enemies flipped branch applies gravity + vertical movement only (no is_solid check) so the enemy rises then falls through floor; removed when below map_h*8+16. draw_enemies passes flip_y=true when state=='flipped'; flipped goombas use the flat sprite and flipped koopas use the shell sprite as placeholder art.

States: update_play decays invince_t and calls music(0) on expiry. check_enemy_hits gains an invincibility branch (before stomp/side logic) that flips the enemy, awards chain_scores points, and plays sfx(6). invuln_t early-return stays at top, so post-shrink i-frames still short-circuit (intentional — player can't double-collect points through i-frames).

Draw: when invince_t>0, pal() rotates colors 8/4/12 through a 4-hue cycle {8,9,10,14} keyed off (invince_t % 4). pal() is reset after the player spr call. invuln_t blink is preserved as a separate branch.

Music: wiring uses music(0)=overworld and music(1)=invincibility. Actual __music__ tracks are not authored yet (cart has no music rows). The calls are silent in game but the structural AC is satisfied; track authoring is follow-up work.

Tests: 20 new specs across 3 files, 155/155 pass.
- spec/player_spec.lua: make_player invince_t default, star_player (5 specs: invince_t set, sfx, music, state preserved, stacks with big), damage_player under invincibility (2 specs: small + big preserved).
- spec/items_spec.lua: star walk physics (3 specs: dx=star_spd, initial dy=star_bounce, bounce on land), star collection (2 specs: star_player triggered + no grow_player). Added music stub to before_each.
- spec/invincibility_spec.lua (new): flip_enemy fields, flipped physics (falls off map, still affected by gravity), check_enemy_hits under star (flips + scores, no damage, no bounce, koopa too), invuln_t precedence short-circuits enemy hits.

Lint: .luacheckrc extended with invince_len, star_spd, star_bounce, flip_rise, star_player, flip_enemy, kick_shell, and pre-existing shell_spd + kick_grace_len (stray warnings in enemies.lua from TASK-009 cleaned up in passing). stomp_enemy duplication in states + enemies sections is harmless.

Token count: 4913 / 8192 (60%). PICO-8 cart loads via `pico8 -run mario.p8` without error. Cart copied to iCloud path.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented star power-up and invincibility (TASK-014). Star item bounces along ground with high arc (star_bounce=-3 on every landing, star_spd=1 horizontal, wall-reversing). Collecting star activates star_player() which grants 600 frames (~10s) of invincibility via player.invince_t; music(1) is called on pickup, music(0) on timer expiry. damage_player short-circuits with "ok" while invince_t>0, taking precedence over both invuln_t and the big-mario shrink path. check_enemy_hits gains an invincibility branch that invokes flip_enemy(e) — enemies enter a new 'flipped' state, launch upward at flip_rise=-3, ignore solid collisions, and fall off-screen under gravity. Player sprite color-cycles via pal() rotating 3 key palette entries through a 4-hue cycle. Star spawns from the existing ? block registration at (19, 10). Music tracks are not authored (only 4 sfx in the cart currently) — the music(0)/music(1) wiring is structurally in place and will activate once tracks are added.

Verified via 155/155 busted specs (20 new: 7 in player_spec, 5 in items_spec, 8 in new invincibility_spec). Cart loads in PICO-8 without error; token count 4913/8192 (60%). Lint clean. Cart copied to iCloud.

DoD #2 (play-test) requires manual verification in PICO-8 since automated E2E baselines don't cover star-specific behavior yet.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
