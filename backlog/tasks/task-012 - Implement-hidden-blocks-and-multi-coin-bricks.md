---
id: TASK-012
title: Implement hidden blocks and multi-coin bricks
status: Done
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 16:45'
labels: []
milestone: m-2
dependencies:
  - TASK-010
priority: low
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement special block types from SMB 1-1: hidden blocks (invisible until bumped from below) and multi-coin bricks (dispense multiple coins on repeated bumps).

Hidden blocks: not drawn on map, but a data table marks their positions. When player head-bumps the position, the block appears as an empty block and releases its item (usually 1-up mushroom). In 1-1 there is one hidden 1-up block.

Multi-coin bricks: a specific brick that gives a coin each time it's bumped, up to 10 coins. After 10 bumps or a time limit (~4 seconds), it becomes an empty block. In 1-1 there is one multi-coin brick.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Hidden blocks are invisible until hit from below
- [x] #2 Hitting a hidden block from below reveals it as a solid empty block
- [x] #3 Hidden 1-up block at correct 1-1 position gives extra life
- [x] #4 Multi-coin brick dispenses coins on repeated bumps (up to 10)
- [x] #5 Multi-coin brick becomes empty block after coins exhausted or time expires
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
Approach:

Hidden blocks and multi-coin bricks registered at _init via data tables; head-bump path in player_move reveals hidden tiles before the is_solid check so they snap the jump; multi-coin bricks are routed through bump_block with a per-tile counter + 4s timer.

Scope decisions:
- Hidden 1-up grants +1 life directly (pop-coin visual + sfx). No mushroom entity — TASK-011 covers that and can layer proper 1-up pickup later.
- lives counter introduced as a global (default 3) at _init. HUD display deferred to TASK-018.
- Positions for SMB 1-1 picked at implementation time from the existing map; kept in register_* calls so they are easy to retune.

Files:
1. src/blocks.lua — hidden_blocks, multi_coin_bricks tables; register_hidden, register_multi_coin, find_hidden, find_multi_coin, reveal_hidden, update_multi_coin_bricks
2. src/helpers.lua — bump_block routes breakable tiles through find_multi_coin; dispenses coin, decrements bumps_left, starts 240-frame timer on first hit; non-registered bricks unchanged
3. src/player.lua — in head-bump branch, call reveal_hidden at both head tile positions before is_solid check so the newly-revealed tile blocks the jump
4. src/main.lua — _init sets lives = 3, clears hidden_blocks and multi_coin_bricks, registers SMB 1-1 entries; _update60 calls update_multi_coin_bricks
5. spec/blocks_spec.lua — tests: hidden block invisible pre-bump, reveal → hit block + dispenses content, hidden 1-up increments lives, multi-coin dispenses up to 10 then converts to hit block, multi-coin converts after timer expires

Validation:
- busted (full suite)
- uv run scripts/generate_cart.py --no-sprites
- Token count verified under 8192
- Play-test in PICO-8 (copy to iCloud carts)
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Hidden blocks and multi-coin bricks registered at _init via register_specials(). Hidden 1-up placed at (60, 7); multi-coin brick at (55, 10) — first brick of the row 10 brick group. hidden_blocks and multi_coin_bricks live in src/blocks.lua alongside spawn_bump/pop_coin.

Flow:
- player_move head-bump branch calls reveal_hidden for both head tile positions before is_solid, so the newly-revealed tile snaps the jump that same frame
- reveal_hidden does mset(spr_hitblock) + spawn_bump + dispenses content (pop coin + coins++ OR lives++ + pop coin visual); hidden block is consumed
- bump_block routes breakable tiles through find_multi_coin: if registered and not exhausted, dispenses one coin per bump; first bump starts a 240-frame window; non-registered bricks unchanged
- update_multi_coin_bricks ticks the timer post-first-bump; when timer<=0 or bumps_left<=0 and no active bump is animating on that tile, mset(spr_hitblock) and drop the entry

lives introduced as a global (lives = lives or 3) in _init; HUD display deferred to TASK-018. 1-up gives +1 life directly — mushroom-entity pickup is TASK-011 scope.

Tests: 13 unit tests added in spec/blocks_spec.lua covering hidden block visibility, reveal → hit block transition, coin dispense, 1-up life increment, multi-coin dispense-then-convert, timer expiry, and no-timer-before-first-bump. Full busted suite: 63/63 green.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added hidden blocks and multi-coin bricks for SMB 1-1.

Hidden blocks live in a runtime-only table (invisible on map); player_move's head-bump branch reveals them just before the is_solid check so the freshly-revealed spr_hitblock snaps the jump the same frame. Content "coin" dispenses a pop coin; "1up" grants +1 life (pop-coin visual for now — mushroom-entity pickup is TASK-011).

Multi-coin bricks register per-tile state (bumps_left=10, 240-frame window, active flag). bump_block routes breakable tiles through find_multi_coin — if registered and not exhausted, dispenses one coin per head-bump and starts the timer on first hit. update_multi_coin_bricks converts the tile to spr_hitblock once the counter or timer is exhausted (guarded so the rewrite doesn't clobber an active bump animation).

lives global introduced (lives = lives or 3 in _init) so restarts preserve the counter; HUD hookup is TASK-018 scope.

Positions tuned in register_specials(): hidden 1-up at (60, 7), multi-coin brick at (55, 10).

Tests: 13 new specs covering visibility, reveal, content dispensing, timer expiry, and the no-tick-before-first-bump edge case. Full busted suite 63/63.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
