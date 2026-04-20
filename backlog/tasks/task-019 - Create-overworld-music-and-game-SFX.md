---
id: TASK-019
title: Create overworld music and game SFX
status: To Do
assignee: []
created_date: '2026-04-15 20:49'
updated_date: '2026-04-19 19:46'
labels: []
milestone: m-4
dependencies:
  - TASK-004
priority: medium
ordinal: 26000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the overworld theme music and all game SFX for the PICO-8 4-channel audio system. Current cart has 4 basic SFX (jump, coin, death, clear) that may need replacement.

PICO-8 has 64 SFX slots and 64 music patterns. Each SFX is 32 notes. Music patterns chain SFX across 4 channels.

Overworld theme: simplified arrangement of the SMB overworld theme. Melody on channel 0, bass on channel 1, harmony/percussion on channels 2-3. Should loop seamlessly.

SFX needed: jump (short rising tone), coin (two-note chime), stomp (short thud), bump (dull thud), power-up appear (rising arpeggio), power-up collect (longer rising arpeggio), death (descending tone), level clear (fanfare), flagpole (sliding tone), 1-up (short jingle).

SFX should play on channels 2-3 to avoid cutting the music melody/bass on channels 0-1. Use sfx(n, channel) to control this.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Overworld theme plays during gameplay (loops)
- [ ] #2 Music stops on death and level clear (replaced by SFX/fanfare)
- [ ] #3 Jump, coin, stomp, bump, power-up, death, and clear SFX all sound distinct
- [ ] #4 Music fits within PICO-8 4-channel limit
- [ ] #5 SFX do not cut off music permanently (use appropriate channels)
- [ ] #6 At least 8 SFX defined: jump, coin, stomp, bump, power-up appear, power-up collect, death, clear
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
