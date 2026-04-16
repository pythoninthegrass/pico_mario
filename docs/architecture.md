# Architecture

Game architecture and data conventions for the PICO-8 Mario clone.

## Source layout

Game code lives in `src/*.lua` and is assembled into `mario.p8` by `generate_cart.py`. See `AGENTS.md` for the file list and include order.

## .p8 format

- **SFX lines must be exactly 168 hex chars**: 8-char header + 32 notes x 5 chars. Wrong lengths cause silent load failures in PICO-8.
- **GFX section**: 128 lines of 128 hex nibbles (one nibble per pixel, left-to-right, top-to-bottom).
- **GFF section**: 2 lines of 256 hex chars (one byte per sprite, 256 sprites total).
- **Map section**: 32 lines of 256 hex chars (one byte per tile, 128x32 tiles, but only 64x16 used).
- `reload(0x2000,0x2000,0x1000)` restores map from ROM — this is how collected coins reappear on restart.

## Sprite and flag conventions

### Current sprite sheet layout

| ID | Sprite        | GFF  | Flags                              |
|----|---------------|------|------------------------------------|
| 0  | empty         | 0x00 | —                                  |
| 1  | mario idle    | 0x00 | —                                  |
| 2  | mario run 1   | 0x00 | —                                  |
| 3  | mario jump    | 0x00 | —                                  |
| 4  | ground        | 0x01 | solid                              |
| 5  | brick         | 0x01 | solid                              |
| 6  | spawn marker  | 0x00 | — (removed at runtime)             |
| 7  | coin          | 0x08 | coin                               |
| 8  | spike/hazard  | 0x02 | hazard                             |
| 9  | goal flag     | 0x04 | goal                               |

### Current flag bits (4 used)

| Bit | Mask | Name   | Purpose                                |
|-----|------|--------|----------------------------------------|
| 0   | 0x01 | solid  | blocks movement                        |
| 1   | 0x02 | hazard | kills player on contact                |
| 2   | 0x04 | goal   | triggers level clear                   |
| 3   | 0x08 | coin   | collectible, removed from map on touch |

### Planned sprite expansion (TASK-001)

Target layout uses 7 rows with IDs spaced at multiples of 16:

- Row 0 (0-15): mario states, spawn marker, hazard
- Row 1 (16-31): terrain — ground, brick, ? block, hit block, hard block
- Row 2 (32-47): pipes (4 tiles: TL, TR, body-L, body-R)
- Row 3 (48-63): enemies — goomba (3), koopa (3)
- Row 4 (64-79): items — coin (2), mushroom, star, fire flower
- Row 5 (80-95): flagpole (3), castle (3)
- Row 6 (96-111): decorations — clouds (3), bushes (3), hills (3)

Additional flag bits planned: breakable (4), question (5), pipe (6).

## SFX assignments

| SFX | Trigger     |
|-----|-------------|
| 0   | jump        |
| 1   | coin pickup |
| 2   | death       |
| 3   | level clear |

## Controls

| Button | PICO-8 | Action          |
|--------|--------|-----------------|
| arrows | btn 0-3| move left/right |
| O      | btn 4  | jump            |
| X      | btn 5  | run (hold)      |

Hold X + direction for run speed. Jump while running for higher/longer arc.

## Level design

The map is 64 tiles wide x 16 tall. Ground at rows 14-15, three pit gaps with spike hazards, scattered platforms and coins, goal flag at column 62. Player hitbox is 6x8 pixels with axis-separated collision.
