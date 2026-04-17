#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13,<3.14"
# dependencies = [
#     "python-decouple>=3.8",
# ]
# [tool.uv]
# exclude-newer = "2026-04-30T00:00:00Z"
# ///

# pyright: reportMissingImports=false

"""
Usage:
    uv run scripts/generate_cart.py [-i PATH] [-o PATH]

Args:
    -i, --input:  Input .p8 cartridge to read as base.
                  Default: <repo>/mario.p8
    -o, --output: Output path for the .p8 cartridge file.
                  Default: same as input (in-place).

Env:
    CART_INPUT:  Override the default input path.
    CART_OUTPUT: Override the default output path.

Note:
    Reads an existing .p8 cartridge, optionally patches the __gfx__
    and __gff__ sections from human-readable sprite definitions, and
    writes the result back.  The .p8 file is the source of truth for
    __lua__, __map__, __sfx__, and __music__.
"""

import argparse
import re
import sys
from pathlib import Path


# ============================================================
# .p8 parser / writer
# ============================================================

# Ordered list of sections in a .p8 file
SECTION_ORDER = [
    "__lua__",
    "__gfx__",
    "__gff__",
    "__map__",
    "__sfx__",
    "__music__",
]

SECTION_RE = re.compile(r"^(__\w+__)$")


# Ordered list of Lua source files to concatenate into __lua__
LUA_SOURCES = [
    "src/constants.lua",
    "src/helpers.lua",
    "src/player.lua",
    "src/camera.lua",
    "src/particles.lua",
    "src/main.lua",
    "src/states.lua",
]


def parse_p8(text: str) -> tuple[list[str], dict[str, list[str]]]:
    """Parse a .p8 text cartridge into header lines and section dict.

    Returns (header_lines, sections) where sections maps e.g.
    "__lua__" -> list of content lines (without the section marker).
    """
    lines = text.split("\n")
    header: list[str] = []
    sections: dict[str, list[str]] = {}
    current_section: str | None = None

    for line in lines:
        m = SECTION_RE.match(line)
        if m:
            current_section = m.group(1)
            sections[m.group(1)] = []
        elif current_section is None:
            header.append(line)
        else:
            sections[current_section].append(line)

    return header, sections


def emit_p8(header: list[str], sections: dict[str, list[str]]) -> str:
    """Reassemble a .p8 cartridge from header and sections."""
    parts: list[str] = list(header)
    for sec in SECTION_ORDER:
        if sec in sections:
            parts.append(sec)
            parts.extend(sections[sec])
    # include any non-standard sections that may exist
    for sec, lines in sections.items():
        if sec not in SECTION_ORDER:
            parts.append(sec)
            parts.extend(lines)
    return "\n".join(parts)


# ============================================================
# Sprite pixel grid (128x128, one nibble per pixel)
# ============================================================

SPRITES: dict[int, list[str]] = {
    # Colour key (PICO-8 palette):
    #   0=black  1=dk_blue  2=dk_purple  3=dk_green
    #   4=brown  5=dk_grey  6=lt_grey    7=white
    #   8=red    9=orange   a=yellow     b=green
    #   c=lt_blue d=indigo  e=pink       f=peach
    #
    # Sprite sheet layout (16 sprites per row):
    #   Row 0 (0-15):  player, spawn marker
    #   Row 1 (16-31): terrain tiles
    #   Row 2 (32-47): pipes
    #   Row 3 (48-63): enemies
    #   Row 4 (64-79): items / collectibles
    #   Row 5 (80-95): flagpole, castle
    #   Row 6 (96-111): decorations (clouds, bushes, hills)
    # --------------------------------------------------------
    # Row 0: Player sprites
    # --------------------------------------------------------
    # 1: mario idle (red hat, peach face, blue overalls, brown shoes)
    1: [
        "..888...",
        ".88f88..",
        ".fff8f..",
        "..fff...",
        ".81188..",
        ".11811..",
        "..111...",
        "..4.4...",
    ],
    # 2: mario run frame 1
    2: [
        "..888...",
        ".88f88..",
        ".fff8f..",
        "..fff...",
        "..1188..",
        ".11811..",
        "..11....",
        "..4.4...",
    ],
    # 3: mario run frame 2
    3: [
        "..888...",
        ".88f88..",
        ".fff8f..",
        "..fff...",
        ".81188..",
        ".11811..",
        ".1...1..",
        ".4...4..",
    ],
    # 4: mario jump (arms up, legs apart)
    4: [
        ".8.888..",
        ".88f88..",
        ".fff8f..",
        "..fff...",
        ".81188..",
        "..1181..",
        "..1.1...",
        ".4...4..",
    ],
    # 5: mario death (face up, arms out)
    5: [
        "..888...",
        ".88f88..",
        ".fff8f..",
        "8.fff.8.",
        ".81188..",
        ".11811..",
        "..111...",
        "..4.4...",
    ],
    # 6: spawn marker (removed at runtime)
    6: [
        "..a..a..",
        ".a.aa.a.",
        "a.a..a.a",
        "..a..a..",
        "..a..a..",
        "a.a..a.a",
        ".a.aa.a.",
        "..a..a..",
    ],
    # 8: hazard / spike (kept at ID 8 for map compatibility)
    8: [
        "........",
        "........",
        "..8..8..",
        "..8..8..",
        ".88.88..",
        ".88.88..",
        "88888888",
        "88888888",
    ],
    # --------------------------------------------------------
    # Row 1: Terrain tiles (IDs 16-21)
    # --------------------------------------------------------
    # 16: ground (orange SMB overworld brick)
    16: [
        "99999999",
        "99494994",
        "99999999",
        "44444444",
        "99999999",
        "49944994",
        "99999999",
        "44444444",
    ],
    # 17: brick block (breakable, warm brown with mortar)
    17: [
        "99499949",
        "99499949",
        "44444444",
        "49949994",
        "49949994",
        "44444444",
        "99499949",
        "99499949",
    ],
    # 18: question block frame 1 (bright yellow with ? glyph)
    18: [
        "aaaaaaaa",
        "a9aaaa9a",
        "aa4444aa",
        "a44aa44a",
        "aaaa44aa",
        "aaa44aaa",
        "aaaaaaaa",
        "aaa44aaa",
    ],
    # 19: question block frame 2 (dimmer, more shading)
    19: [
        "a9aaaa9a",
        "a9aaaa9a",
        "aa4444aa",
        "a44aa44a",
        "aaaa44aa",
        "aaa44aaa",
        "aaaaaaaa",
        "aaa44aaa",
    ],
    # 20: empty/hit block (dim orange frame, spent ? block look)
    20: [
        "44444444",
        "49999994",
        "49999994",
        "49999994",
        "49999994",
        "49999994",
        "49999994",
        "44444444",
    ],
    # 21: hard block / stone (grey, unbreakable)
    21: [
        "66666666",
        "65555556",
        "65666566",
        "65666566",
        "65666566",
        "65555556",
        "65565656",
        "55555555",
    ],
    # --------------------------------------------------------
    # Row 2: Pipes (IDs 32-35)
    # --------------------------------------------------------
    # 32: pipe top-left (lip cap + highlight stripe)
    32: [
        "33333333",
        "3b7bbbb3",
        "3bbbbbb3",
        "33333333",
        "33bbbbbb",
        "337bbbbb",
        "33bbbbbb",
        "33bbbbbb",
    ],
    # 33: pipe top-right (lip cap + highlight)
    33: [
        "33333333",
        "3bbbbbb3",
        "3bbbbbb3",
        "33333333",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
    ],
    # 34: pipe body-left (with highlight stripe)
    34: [
        "337bbbbb",
        "337bbbbb",
        "337bbbbb",
        "337bbbbb",
        "337bbbbb",
        "337bbbbb",
        "337bbbbb",
        "337bbbbb",
    ],
    # 35: pipe body-right
    35: [
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
        "bbbbbb33",
    ],
    # --------------------------------------------------------
    # Row 3: Enemies (IDs 48-53)
    # --------------------------------------------------------
    # 48: goomba walk frame 1
    48: [
        "..4444..",
        ".444444.",
        ".f44f4..",
        ".444444.",
        "..ffff..",
        ".4ff44..",
        ".44.44..",
        ".44..44.",
    ],
    # 49: goomba walk frame 2
    49: [
        "..4444..",
        ".444444.",
        "..f44f4.",
        ".444444.",
        "..ffff..",
        "..44ff4.",
        "..44.44.",
        ".44..44.",
    ],
    # 50: goomba squished (flat)
    50: [
        "........",
        "........",
        "........",
        "........",
        "........",
        "........",
        ".f44f4..",
        "44444444",
    ],
    # 51: koopa walk frame 1 (green shell, yellow body)
    51: [
        "...bb...",
        "..bbb...",
        "..bbb3..",
        ".3b3b3..",
        ".3bbb3..",
        "..aaf...",
        "..affa..",
        "..4..4..",
    ],
    # 52: koopa walk frame 2
    52: [
        "...bb...",
        "..bbb...",
        "..bbb3..",
        ".3b3b3..",
        ".3bbb3..",
        "..aaf...",
        ".affa...",
        ".4..4...",
    ],
    # 53: koopa shell
    53: [
        "........",
        "..3333..",
        ".3bbbb3.",
        ".3b3bb3.",
        ".3bb3b3.",
        ".3bbbb3.",
        "..3333..",
        "........",
    ],
    # --------------------------------------------------------
    # Row 4: Items / collectibles (IDs 64-68)
    # --------------------------------------------------------
    # 64: coin frame 1
    64: [
        "...aa...",
        "..a99a..",
        "..a9aa..",
        "..a99a..",
        "..a9aa..",
        "..a99a..",
        "...aa...",
        "........",
    ],
    # 65: coin frame 2 (thinner)
    65: [
        "...a....",
        "..a9a...",
        "..a9a...",
        "..a9a...",
        "..a9a...",
        "..a9a...",
        "...a....",
        "........",
    ],
    # 66: mushroom (red cap, white spots, tan stem)
    66: [
        "..8888..",
        ".878878.",
        ".888888.",
        "88888888",
        "..ffff..",
        "..ffff..",
        ".ffffff.",
        ".ffffff.",
    ],
    # 67: star (yellow, bouncing power-up)
    67: [
        "...a....",
        "..aaa...",
        ".aaaaa..",
        "aaaaaaa.",
        ".aa.aa..",
        ".a...a..",
        "a.....a.",
        "........",
    ],
    # 68: fire flower (red/orange petals, green stem)
    68: [
        "..898...",
        ".89898..",
        ".98a89..",
        "..898...",
        "...b....",
        "..bbb...",
        "...b....",
        "..bbb...",
    ],
    # --------------------------------------------------------
    # Row 5: Flagpole and castle (IDs 80-85)
    # --------------------------------------------------------
    # 80: flagpole ball (top)
    80: [
        "........",
        "...bb...",
        "..bbbb..",
        "..bbbb..",
        "...bb...",
        "...66...",
        "...66...",
        "...66...",
    ],
    # 81: flagpole shaft
    81: [
        "...66...",
        "...66...",
        "...66...",
        "...66...",
        "...66...",
        "...66...",
        "...66...",
        "...66...",
    ],
    # 82: flag (green triangle on pole)
    82: [
        "..bb6...",
        ".bbb6...",
        "bbbb6...",
        ".bbb6...",
        "..bb6...",
        "...66...",
        "...66...",
        "...66...",
    ],
    # 83: castle block (dark red-brown, distinct from brick)
    83: [
        "88488848",
        "88488848",
        "44444444",
        "48848884",
        "48848884",
        "44444444",
        "88488848",
        "88488848",
    ],
    # 84: castle top / battlement (crenellation with sky gaps)
    84: [
        "44.44.44",
        "44.44.44",
        "44444444",
        "88488848",
        "44444444",
        "48848884",
        "48848884",
        "44444444",
    ],
    # 85: castle door (arched black opening)
    85: [
        "44444444",
        "45500554",
        "45000054",
        "45000054",
        "45000054",
        "45000054",
        "45000054",
        "45000054",
    ],
    # --------------------------------------------------------
    # Row 6: Decorations (IDs 96-104)
    # --------------------------------------------------------
    # 96: cloud top-left
    96: [
        "........",
        "........",
        "...777..",
        "..77777.",
        ".7777777",
        "77777777",
        "77777777",
        "........",
    ],
    # 97: cloud top-mid
    97: [
        "........",
        "..777...",
        ".77777..",
        "77777777",
        "77777777",
        "77777777",
        "77777777",
        "........",
    ],
    # 98: cloud top-right
    98: [
        "........",
        "........",
        ".777....",
        "77777...",
        "7777777.",
        "77777777",
        "77777777",
        "........",
    ],
    # 99: bush left
    99: [
        "........",
        "........",
        "........",
        "........",
        "...bbb..",
        "..bbbbb.",
        ".bbbbbbb",
        "bbbbbbbb",
    ],
    # 100: bush mid
    100: [
        "........",
        "........",
        "........",
        "..bbb...",
        ".bbbbb..",
        "bbbbbbbb",
        "bbbbbbbb",
        "bbbbbbbb",
    ],
    # 101: bush right
    101: [
        "........",
        "........",
        "........",
        "........",
        "..bbb...",
        ".bbbbb..",
        "bbbbbbb.",
        "bbbbbbbb",
    ],
    # 102: hill body (solid green fill)
    102: [
        "bbbbbbbb",
        "b3b3b3b3",
        "bbbbbbbb",
        "3b3b3b3b",
        "bbbbbbbb",
        "b3b3b3b3",
        "bbbbbbbb",
        "3b3b3b3b",
    ],
    # 103: hill top (rounded peak)
    103: [
        "........",
        "........",
        "...bb...",
        "..bbbb..",
        ".bbbbbb.",
        "bbbbbbbb",
        "b3b3b3b3",
        "bbbbbbbb",
    ],
    # 104: hill edge / small hill
    104: [
        "........",
        "........",
        "........",
        "........",
        "........",
        "...bb...",
        "..bbbb..",
        ".bbbbbb.",
    ],
}

# Flag bit definitions:
#   bit 0 (0x01) = solid (blocks movement)
#   bit 1 (0x02) = hazard (kills player)
#   bit 2 (0x04) = goal (triggers level clear)
#   bit 3 (0x08) = coin (collectible)
#   bit 4 (0x10) = breakable (brick, destroyed by big mario)
#   bit 5 (0x20) = question (? block, releases item when bumped)
#   bit 6 (0x40) = pipe (pipe tile, used for entry detection)
#   bit 7 (0x80) = reserved
SPRITE_FLAGS: dict[int, int] = {
    # hazard (row 0, kept for map compat)
    8: 0x02,  # spike: hazard
    # terrain
    16: 0x01,  # ground: solid
    17: 0x11,  # brick: solid + breakable
    18: 0x21,  # ? block f1: solid + question
    19: 0x21,  # ? block f2: solid + question
    20: 0x01,  # empty/hit block: solid
    21: 0x01,  # hard block: solid
    # pipes
    32: 0x41,  # pipe top-left: solid + pipe
    33: 0x41,  # pipe top-right: solid + pipe
    34: 0x41,  # pipe body-left: solid + pipe
    35: 0x41,  # pipe body-right: solid + pipe
    # items
    64: 0x08,  # coin f1: coin
    65: 0x08,  # coin f2: coin
    # flagpole
    80: 0x04,  # flagpole ball: goal
    81: 0x04,  # flagpole shaft: goal
    82: 0x04,  # flag: goal
    # castle
    83: 0x01,  # castle block: solid
    84: 0x01,  # castle top: solid
}


def assemble_lua(repo_root: Path) -> list[str]:
    """Read and concatenate Lua source files into __lua__ section lines."""
    parts: list[str] = []
    for src in LUA_SOURCES:
        parts.append((repo_root / src).read_text())
    # concatenate, then strip one trailing newline (the final file's)
    combined = "".join(parts).rstrip("\n")
    return combined.split("\n")


def build_gfx_lines() -> list[str]:
    """Render SPRITES dict into 128 lines of 128 hex nibbles."""
    gfx = [[0] * 128 for _ in range(128)]
    for spr_n, pixels in SPRITES.items():
        ox = (spr_n % 16) * 8
        oy = (spr_n // 16) * 8
        for y, row in enumerate(pixels):
            for x, ch in enumerate(row):
                if ch != ".":
                    gfx[oy + y][ox + x] = int(ch, 16)
    return ["".join(format(gfx[y][x], "x") for x in range(128)) for y in range(128)]


def build_gff_lines() -> list[str]:
    """Render SPRITE_FLAGS dict into 2 lines of 256 hex chars."""
    flags = [SPRITE_FLAGS.get(i, 0) for i in range(256)]
    raw = "".join(format(f, "02x") for f in flags)
    return [raw[:256], raw[256:]]


# ============================================================
# Config helpers
# ============================================================


def get_env(key: str, default: str = "") -> str:
    """Read a config value from .env (if present) or environment."""
    env_file = Path.cwd() / ".env"
    if env_file.exists():
        from decouple import Config, RepositoryEnv

        cfg = Config(RepositoryEnv(env_file))
        return cfg(key, default=default)
    else:
        from decouple import config as cfg

        return cfg(key, default=default)


# ============================================================
# Main
# ============================================================


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    env_input = get_env("CART_INPUT")
    env_output = get_env("CART_OUTPUT")
    default_input = Path(env_input) if env_input else repo_root / "mario.p8"
    default_output = Path(env_output) if env_output else None

    parser = argparse.ArgumentParser(
        description="Patch a .p8 cartridge's sprite and flag sections."
    )
    parser.add_argument(
        "-i",
        "--input",
        type=Path,
        default=default_input,
        help="Input .p8 file (default: mario.p8 or CART_INPUT env var)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=default_output,
        help="Output .p8 file (default: same as input, or CART_OUTPUT env var)",
    )
    parser.add_argument(
        "--no-assemble",
        action="store_true",
        help="Skip Lua assembly from src/ (patch sprites only)",
    )
    parser.add_argument(
        "--no-sprites",
        action="store_true",
        help="Skip __gfx__/__gff__ patching (assemble Lua only)",
    )
    args = parser.parse_args()

    input_path: Path = args.input
    output_path: Path = args.output or input_path

    if not input_path.exists():
        print(f"error: input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    header, sections = parse_p8(input_path.read_text())

    # assemble __lua__ from src/ files unless skipped
    if not args.no_assemble:
        src_dir = repo_root / "src"
        if src_dir.is_dir():
            sections["__lua__"] = assemble_lua(repo_root)

    # patch __gfx__ and __gff__ from the sprite definitions above
    if not args.no_sprites:
        sections["__gfx__"] = build_gfx_lines()
        sections["__gff__"] = build_gff_lines()

    output_path.write_text(emit_p8(header, sections))

    gfx_rows = sum(1 for line in sections["__gfx__"] if any(c != "0" for c in line))
    map_rows = sum(
        1 for line in sections.get("__map__", []) if any(c != "0" for c in line)
    )
    print(f"Wrote {output_path}  ({output_path.stat().st_size} bytes)")
    print(f"  non-empty gfx rows: {gfx_rows}")
    print(f"  non-empty map rows: {map_rows}")


if __name__ == "__main__":
    main()
