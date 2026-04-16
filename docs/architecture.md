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

### Sprite sheet layout

The sprite sheet uses 7 rows (IDs at multiples of 16). Defined in `generate_cart.py` SPRITES dict and `src/constants.lua` spr_* constants.

**Row 0 — Player (0-15)**

| ID | Sprite       | Flags  |
|----|--------------|--------|
| 1  | mario idle   | —      |
| 2  | mario run 1  | —      |
| 3  | mario run 2  | —      |
| 4  | mario jump   | —      |
| 5  | mario death  | —      |
| 6  | spawn marker | — (removed at runtime) |
| 8  | spike/hazard | hazard |

**Row 1 — Terrain (16-31)**

| ID | Sprite       | Flags              |
|----|--------------|--------------------|
| 16 | ground       | solid              |
| 17 | brick        | solid + breakable  |
| 18 | ? block f1   | solid + question   |
| 19 | ? block f2   | solid + question   |
| 20 | hit block    | solid              |
| 21 | hard block   | solid              |

**Row 2 — Pipes (32-47)**

| ID | Sprite         | Flags        |
|----|----------------|--------------|
| 32 | pipe top-left  | solid + pipe |
| 33 | pipe top-right | solid + pipe |
| 34 | pipe body-left | solid + pipe |
| 35 | pipe body-right| solid + pipe |

**Row 3 — Enemies (48-63)**

| ID | Sprite         | Flags |
|----|----------------|-------|
| 48 | goomba walk 1  | —     |
| 49 | goomba walk 2  | —     |
| 50 | goomba squished| —     |
| 51 | koopa walk 1   | —     |
| 52 | koopa walk 2   | —     |
| 53 | koopa shell    | —     |

**Row 4 — Items (64-79)**

| ID | Sprite      | Flags |
|----|-------------|-------|
| 64 | coin f1     | coin  |
| 65 | coin f2     | coin  |
| 66 | mushroom    | —     |
| 67 | star        | —     |
| 68 | fire flower | —     |

**Row 5 — Flagpole / Castle (80-95)**

| ID | Sprite         | Flags |
|----|----------------|-------|
| 80 | flagpole ball  | goal  |
| 81 | flagpole shaft | goal  |
| 82 | flag           | goal  |
| 83 | castle block   | solid |
| 84 | castle top     | solid |
| 85 | castle door    | —     |

**Row 6 — Decorations (96-111)**

| ID | Sprite     | Flags |
|----|------------|-------|
| 96 | cloud left | —     |
| 97 | cloud mid  | —     |
| 98 | cloud right| —     |
| 99 | bush left  | —     |
|100 | bush mid   | —     |
|101 | bush right | —     |
|102 | hill body  | —     |
|103 | hill top   | —     |
|104 | hill small | —     |

### Flag bits (7 used)

| Bit | Mask | Name      | Lua const    | Purpose                                |
|-----|------|-----------|--------------|----------------------------------------|
| 0   | 0x01 | solid     | f_solid      | blocks movement                        |
| 1   | 0x02 | hazard    | f_hazard     | kills player on contact                |
| 2   | 0x04 | goal      | f_goal       | triggers level clear                   |
| 3   | 0x08 | coin      | f_coin       | collectible, removed from map on touch |
| 4   | 0x10 | breakable | f_breakable  | destroyed by big mario                 |
| 5   | 0x20 | question  | f_question   | releases item when bumped              |
| 6   | 0x40 | pipe      | f_pipe       | pipe tile, used for entry detection    |
| 7   | 0x80 | reserved  | —            | —                                      |

### Legacy sprite IDs (map not yet migrated)

The map (`__map__`) still references old sprite IDs: 4=ground, 5=brick, 7=coin, 8=spike, 9=goal. Use `--no-sprites` when building until the map is migrated to the new IDs above.

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
