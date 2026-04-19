# SMB 1-1 Enemy Locations

Enemy positions extracted from `maps/smb_1-1.mp4` (frames 1-1709, 0-57s) and
cross-referenced with `maps/smb_1-1.png` reference map.

## NES-to-PICO-8 Landmark Mapping

The PICO-8 level (128 tiles) compresses the NES level (~209 tiles). Key
correspondences used for position mapping:

| Landmark        | NES tile | P8 tile |
|-----------------|----------|---------|
| Spawn           |    2     |    2    |
| First ?-block   |   20     |   13    |
| Pipe 1 (short)  |   28     |   24    |
| Pipe 2          |   38     |   29    |
| Pipe 3 (tall)   |   46     |   36    |
| Pipe 4 (tall)   |   57     |   44    |
| Gap 1           |   69     |   52    |
| Brick platform  |   80     |   62    |
| Brick row       |   97     |   71    |
| Staircase 1     |  120     |   80    |
| Staircase 2     |  130     |   90    |
| Flagpole        |  198     |  108    |

## Enemy Table

Ground row is Y=13 in PICO-8 tile coords (enemies stand on row 14 ground).

| #  | Type          | NES tile X | P8 tile X | P8 Y | Context                           | Video frame |
|----|---------------|------------|-----------|------|-----------------------------------|-------------|
| 1  | Goomba        |   22       |   16      |  13  | Before ?-block/brick row          | f00200-220  |
| 2  | Goomba        |   40       |   31      |  13  | Between pipe 2 and pipe 3         | (map ref)   |
| 3  | Goomba        |   51       |   40      |  13  | Between pipe 3 and pipe 4 (pair)  | f00700      |
| 4  | Goomba        |   52       |   41      |  13  | Between pipe 3 and pipe 4 (pair)  | f00700      |
| 5  | Koopa Troopa  |   55       |   43      |  13  | Just before pipe 4                | (map ref)   |
| 6  | Goomba        |   79       |   59      |  13  | Approaching brick platform (pair) | (map ref)   |
| 7  | Goomba        |   80       |   60      |  13  | Approaching brick platform (pair) | (map ref)   |
| 8  | Goomba        |   82       |   63      |  13  | Below brick platform (pair)       | (map ref)   |
| 9  | Goomba        |   83       |   64      |  13  | Below brick platform (pair)       | (map ref)   |
| 10 | Goomba        |   97       |   71      |  13  | Below brick row (pair)            | (map ref)   |
| 11 | Goomba        |   98       |   72      |  13  | Below brick row (pair)            | (map ref)   |
| 12 | Goomba        |  108       |   75      |  13  | Before staircases (pair)          | (map ref)   |
| 13 | Goomba        |  109       |   76      |  13  | Before staircases (pair)          | (map ref)   |
| 14 | Goomba        |  168       |  100      |  13  | After staircase area (pair)       | f01400-1450 |
| 15 | Goomba        |  169       |  101      |  13  | After staircase area (pair)       | f01400-1450 |
| 16 | Goomba        |  171       |  103      |  13  | Before final staircase (pair)     | f01500      |
| 17 | Goomba        |  172       |  104      |  13  | Before final staircase (pair)     | f01500      |

Total: 16 Goombas + 1 Koopa Troopa = 17 enemies

## Enemy Summary by Area

### Early area (X 0-23)
- 1 Goomba (P8 X=16): the first enemy the player encounters

### Pipe zone (X 24-45)
- 1 Goomba (P8 X=31): between pipe 2 and pipe 3
- 2 Goombas (P8 X=40-41): walking as a pair between pipe 3 and pipe 4
- 1 Koopa Troopa (P8 X=43): just before pipe 4

### Post-gap / platform area (X 52-70)
- 2 Goombas (P8 X=59-60): pair before the elevated brick platform
- 2 Goombas (P8 X=63-64): pair below the elevated brick platform

### Brick row / pre-staircase (X 71-85)
- 2 Goombas (P8 X=71-72): pair below the brick row
- 2 Goombas (P8 X=75-76): pair approaching the staircases

### End section (X 98-108)
- 2 Goombas (P8 X=100-101): pair in the open area after staircases
- 2 Goombas (P8 X=103-104): pair near the final hill before flagpole

## Notes

- Enemies #6-13 (map ref only) were skipped in the video because the player
  used the underground warp pipe. Positions derived from reference map.
- The Koopa Troopa (#5) is the only non-Goomba enemy in SMB 1-1.
- Enemies #10-11 at P8 X=71-72 overlap with ground gap 2 (72-73). Consider
  shifting to X=69-70 to avoid spawning over the pit.
- Enemies #16-17 at P8 X=103-104 overlap with hill decoration (104-106).
  Consider shifting to X=101-102.
- In the NES original, enemies walk leftward and are spawned when the camera
  approaches. PICO-8 implementation should use a spawn trigger system based on
  camera scroll position.
- All enemies spawn at ground level (Y=13). The NES version has no enemies on
  elevated platforms in 1-1 (the pair near the brick platform walks on ground).
