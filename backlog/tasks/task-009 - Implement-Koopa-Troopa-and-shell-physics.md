---
id: TASK-009
title: Implement Koopa Troopa and shell physics
status: Done
assignee: []
created_date: '2026-04-15 20:48'
updated_date: '2026-04-20 21:35'
labels: []
milestone: m-1
dependencies:
  - TASK-008
priority: medium
ordinal: 440.91796875
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement Koopa Troopa enemy with shell mechanics. Koopa walks like Goomba but when stomped, retreats into shell instead of dying. Shell can be kicked by walking into it, and a moving shell kills other enemies on contact.

Shell states: stationary (safe to touch/kick), moving (dangerous, kills enemies and player). Stomping a moving shell stops it. Shell bounces off walls.

SMB 1-1 has 1 Koopa Troopa (green). Shell speed ~2 px/frame when kicked.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Koopa walks left, reverses on walls, animates between 2 frames
- [x] #2 Stomping a Koopa turns it into a stationary shell
- [x] #3 Walking into a stationary shell kicks it in that direction
- [x] #4 Moving shell kills goombas and other enemies on contact
- [x] #5 Moving shell bounces off walls and reverses direction
- [x] #6 Moving shell kills player if it hits them from the side
- [x] #7 Stomping a moving shell stops it
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Added shell kick + bounce mechanics to enemies.lua and states.lua; koopa spawn at x=43 from smb_1-1 enemy map.

Token verification: wrote scripts/count_tokens.py (PICO-8 rules: brackets/strings 1 each, commas/periods/local/semicolons/end/comments not counted). Current mario.p8 is 4603 / 8192 tokens (56.2%). Well under the hard limit.

New constants: shell_spd=2.0, kick_grace_len=4 (frames after kick where shell-player collision is ignored so kicker isn't immediately hit).

Shell states covered:
- alive koopa -> shell on stomp
- stationary shell + side contact -> kicked in player's direction away
- stationary shell + stomp -> kicked in player's facing direction
- moving shell + stomp -> halts
- moving shell vs alive enemy -> kills that enemy with chain score
- kick_t grace prevents instant self-hit after kicking

Tests: 135 passes (spec/shell_spec.lua added).
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Koopa Troopa + shell physics implemented. Koopa walks/reverses/animates like a goomba; stomping turns it into a stationary shell. Side contact or stomp on a parked shell kicks it; moving shells kill enemies on contact with chain scoring, bounce off walls, and hurt the player. Stomping a moving shell halts it. A 4-frame kick grace prevents the kicker from being immediately hit.

Added scripts/count_tokens.py to sanity-check the 8192 PICO-8 token limit in CI without needing to open the editor. Cart is currently 4603 / 8192 tokens (56.2%).
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
