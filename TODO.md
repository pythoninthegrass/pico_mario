# TODO

## Reference

Source map: `maps/smb_1-1.png`

## Sprites (8x8 tiles, 256 max)

PICO-8 has a 128x128 sprite sheet (256 8x8 sprites). We need to allocate
carefully. Multi-tile objects use adjacent sprite slots.

- [ ] Mario idle (sprite 1)
- [ ] Mario run frame 1 (sprite 2)
- [ ] Mario run frame 2 (sprite 3)
- [ ] Mario jump (sprite 4)
- [ ] Mario death (sprite 5)
- [ ] Ground/floor tile (sprite 16)
- [ ] Brick block (sprite 17)
- [ ] Question block frame 1 (sprite 18)
- [ ] Question block frame 2 (sprite 19)
- [ ] Empty/hit block (sprite 20)
- [ ] Hard block / stone (sprite 21)
- [ ] Pipe top-left (sprite 32)
- [ ] Pipe top-right (sprite 33)
- [ ] Pipe body-left (sprite 34)
- [ ] Pipe body-right (sprite 35)
- [ ] Goomba walk frame 1 (sprite 48)
- [ ] Goomba walk frame 2 (sprite 49)
- [ ] Goomba squished (sprite 50)
- [ ] Koopa walk frame 1 (sprite 51)
- [ ] Koopa walk frame 2 (sprite 52)
- [ ] Koopa shell (sprite 53)
- [ ] Coin (sprite 64)
- [ ] Coin frame 2 (sprite 65)
- [ ] Mushroom / power-up (sprite 66)
- [ ] Star (sprite 67)
- [ ] Fire flower (sprite 68)
- [ ] Flagpole ball (sprite 80)
- [ ] Flagpole shaft (sprite 81)
- [ ] Flag (sprite 82)
- [ ] Castle block (sprite 83)
- [ ] Castle top/battlement (sprite 84)
- [ ] Castle door (sprite 85)
- [ ] Cloud top-left (sprite 96)
- [ ] Cloud top-mid (sprite 97)
- [ ] Cloud top-right (sprite 98)
- [ ] Bush left (sprite 99)
- [ ] Bush mid (sprite 100)
- [ ] Bush right (sprite 101)
- [ ] Hill body (sprite 102)
- [ ] Hill top (sprite 103)
- [ ] Small hill / hill edge (sprite 104)
- [ ] Spawn marker (sprite 6, removed at runtime)

## Sprite flags

- [ ] Define flag bits: solid, hazard, goal, coin, breakable, question, pipe, enemy
- [ ] Assign flags to all tile sprites in `__gff__` section
- [ ] Update `generate_cart.py` with new sprite definitions and flags

## Map layout (1-1 recreation)

Recreate SMB 1-1 in the PICO-8 128x16 tile map. The NES level is ~210
columns at 16px; we map it into 128 columns at 8px (roughly 2:1 horizontal
compression, or selectively trim empty space).

- [ ] Plan column mapping: NES 1-1 columns to PICO-8 columns
- [ ] Ground segments with correct gap placement
- [ ] Pipe placements (4 pipes of varying height)
- [ ] Brick rows and question blocks (exact positions from reference)
- [ ] Staircase structures (end-of-level pyramids)
- [ ] Flagpole and castle at level end
- [ ] Coin placement (visible coins + hidden in ? blocks)
- [ ] Background decoration layer (clouds, bushes, hills)
- [ ] Underground bonus room (if map space permits, rows 16-31)
- [ ] Warp pipe entry/exit between overworld and underground

## Enemies

- [ ] Goomba AI: walk left, reverse on wall, die when stomped
- [ ] Koopa AI: walk left, reverse on wall, enter shell when stomped
- [ ] Shell physics: kicked shell slides, kills other enemies, bounces off walls
- [ ] Enemy spawn system: spawn enemies when camera approaches their map position
- [ ] Enemy-enemy collision (shell kills goombas)
- [ ] Enemy falls into pits
- [ ] Place enemies at correct 1-1 positions (16 goombas, 1 koopa from reference)

## Blocks and items

- [ ] Question block: bump from below to release item, becomes empty block
- [ ] Brick block: bump from below to break (when big Mario) or just bump
- [ ] Coin from question block: animated coin pop + score
- [ ] Mushroom from question block: slides right, falls with gravity
- [ ] Star from question block: bounces, gives invincibility
- [ ] Fire flower from question block (when already big)
- [ ] Hidden 1-up block (invisible until hit from below)
- [ ] Multi-coin brick (10 coins, time-limited)
- [ ] Block bump animation (block moves up slightly then back)

## Power-up system

- [ ] Small Mario (1-hit death, current behavior)
- [ ] Big Mario (mushroom): taller hitbox, can break bricks, shrinks on hit
- [ ] Fire Mario (fire flower): shoot fireballs
- [ ] Star power: invincibility timer, kills enemies on contact, flashing sprite
- [ ] Power-up state transitions with animation

## Player mechanics

- [x] Variable-height jump (release button early = lower arc)
- [x] Coyote time (brief grace period to jump after walking off edge)
- [x] Run mechanic (hold X for faster speed + higher jump)
- [ ] Stomp enemies (bounce off enemy head, kill enemy)
- [ ] Bump blocks from below (head collision with ? and brick blocks)
- [ ] Enter pipes (down on pipe top to enter underground)
- [ ] Fireball shooting (when fire Mario, press O while holding X)
- [ ] Death animation (Mario pops up then falls off screen)
- [ ] Flagpole slide (grab flagpole, slide down, walk to castle)
- [ ] Swimming mechanics (if underground has water, not in 1-1)

## Physics tuning

- [ ] Match NES Mario feel: acceleration/deceleration curves instead of instant speed
- [ ] Separate air vs ground friction
- [ ] Skid animation when reversing direction while running
- [ ] Max speed cap with gradual acceleration
- [ ] Tune gravity, jump strength, run speed to feel right at 8x8 tile scale

## Camera

- [ ] One-way scrolling (camera only moves right, never left — like NES)
- [ ] Camera dead zone (small zone where Mario can move without scrolling)
- [ ] Smooth camera follow within constraints

## HUD and scoring

- [ ] Score display (top of screen)
- [ ] Coin counter with coin icon
- [ ] Timer countdown (400 seconds, like NES)
- [ ] Lives counter
- [ ] World display ("WORLD 1-1")
- [ ] Score popup when stomping enemies (100, 200, etc. chain)

## Audio

- [ ] Overworld theme music (simplified for PICO-8 4-channel limit)
- [ ] Underground theme music
- [ ] Jump SFX (already exists, may need tuning)
- [ ] Coin SFX (already exists)
- [ ] Stomp SFX
- [ ] Bump block SFX
- [ ] Power-up SFX
- [ ] Power-up appear SFX
- [ ] Pipe enter SFX
- [ ] Death SFX (already exists)
- [ ] Level clear fanfare (already exists, may need tuning)
- [ ] Flagpole SFX
- [ ] 1-up SFX
- [ ] Invincibility music
- [ ] Timer warning (speed up music when time low)

## Game flow

- [ ] Title screen ("SUPER MARIO BROS" with press start)
- [ ] Lives screen ("WORLD 1-1" with Mario x 3)
- [ ] Game over screen
- [ ] Level clear: flagpole grab, score tally, fireworks, walk to castle
- [ ] Timer bonus (remaining time * 50 points)
- [ ] Restart from checkpoint or beginning on death

## Validation

- [ ] Load in PICO-8 and play-test full level
- [ ] Verify all SFX play correctly
- [ ] Verify enemy behavior matches reference
- [ ] Verify block interactions work
- [ ] Verify power-up system works
- [ ] Verify level is completable start to finish
- [ ] Token count check (PICO-8 limit: 8192 tokens)
