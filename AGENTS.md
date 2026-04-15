# AGENTS.md

## Project overview

Single-level Mario clone for the PICO-8 fantasy console. One `.p8` cartridge file contains all game code, sprites, map, and audio. A Python helper script patches sprite data into the cart.

## Source of truth

`mario_clone.p8` is the canonical artifact. It contains `__lua__`, `__map__`, `__sfx__`, and `__music__` sections that are hand-authored. Never regenerate these sections from scratch — only patch `__gfx__` and `__gff__` via the script.

## Key files

- `mario_clone.p8` — the PICO-8 cartridge (Lua game code + all data sections)
- `scripts/generate_cart.py` — reads the `.p8`, patches `__gfx__` and `__gff__` from sprite definitions in the script, preserves everything else
- `docs/pico-8_cheatsheet.png` — PICO-8 API quick reference (image)
- `docs/llms.txt` — extracted PICO-8 manual snippets for LLM context

## Runtimes and tools

Managed via `mise` (see `.tool-versions`):
- Python 3.13, uv, ruff for the helper script
- Lua 5.5 (not used by PICO-8 directly — PICO-8 has its own Lua dialect)

## Commands

```bash
# Patch sprites into the cart (in-place)
uv run scripts/generate_cart.py

# Patch sprites, write to a different file
uv run scripts/generate_cart.py -i mario_clone.p8 -o output.p8

# Lint/format the Python script
ruff format scripts/
ruff check scripts/
```

## .p8 format gotchas

- **SFX lines must be exactly 168 hex chars**: 8-char header + 32 notes x 5 chars. Wrong lengths cause silent load failures in PICO-8.
- **GFX section**: 128 lines of 128 hex nibbles (one nibble per pixel, left-to-right, top-to-bottom).
- **GFF section**: 2 lines of 256 hex chars (one byte per sprite, 256 sprites total).
- **Map section**: 32 lines of 256 hex chars (one byte per tile, 128x32 tiles, but only 64x16 used).
- `reload(0x2000,0x2000,0x1000)` restores map from ROM — this is how collected coins reappear on restart.

## Sprite and flag conventions

| Sprite | Purpose       | Flags                    |
|--------|---------------|--------------------------|
| 0      | empty         | —                        |
| 1      | player idle   | —                        |
| 2      | player run    | —                        |
| 3      | player jump   | —                        |
| 4      | ground        | 0x01 (solid)             |
| 5      | brick         | 0x01 (solid)             |
| 6      | spawn marker  | — (removed at runtime)   |
| 7      | coin          | 0x08 (coin)              |
| 8      | spike/hazard  | 0x02 (hazard)            |
| 9      | goal flag     | 0x04 (goal)              |

Flag bits: 0=solid, 1=hazard, 2=goal, 3=coin.

## SFX assignments

| SFX | Trigger     |
|-----|-------------|
| 0   | jump        |
| 1   | coin pickup |
| 2   | death       |
| 3   | level clear |

## Python script conventions

Scripts use PEP 723 inline metadata with `uv run --script` shebang. See `CLAUDE.md` for the exact pattern (decouple-based env loading, specific docstring format, no `from __future__`).

## Level design

The map is 64 tiles wide x 16 tall. Ground at rows 14-15, three pit gaps with spike hazards, scattered platforms and coins, goal flag at column 62. Player hitbox is 6x8 pixels with axis-separated collision.
