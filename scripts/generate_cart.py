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
                  Default: <repo>/mario_clone.p8
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
            sections[current_section] = []
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
    # Colour key:
    #   0=black  1=dk_blue  2=dk_purple  3=dk_green
    #   4=brown  5=dk_grey  6=lt_grey    7=white
    #   8=red    9=orange   a=yellow     b=green
    #   c=lt_blue d=indigo  e=pink       f=peach
    # 1: player idle
    1: [
        "..888...",
        ".88888..",
        "..fff...",
        ".fffff..",
        "..222...",
        ".22222..",
        "..2.2...",
        ".44.44..",
    ],
    # 2: player run
    2: [
        "..888...",
        ".88888..",
        "..fff...",
        ".fffff..",
        ".2222...",
        "..222...",
        ".2..2...",
        ".44..4..",
    ],
    # 3: player jump
    3: [
        "..888...",
        ".88888..",
        "..fff...",
        ".fffff..",
        "..222...",
        ".22222..",
        ".2...2..",
        ".4...4..",
    ],
    # 4: ground (green top, brown earth)
    4: [
        "bbbbbbbb",
        "3b3b3b3b",
        "44444444",
        "44544454",
        "44444444",
        "45444544",
        "44444444",
        "44444444",
    ],
    # 5: brick / platform
    5: [
        "55555555",
        "56565656",
        "55555555",
        "65656565",
        "55555555",
        "56565656",
        "55555555",
        "65656565",
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
    # 7: coin
    7: [
        "..aaa...",
        ".a999a..",
        ".a9a9a..",
        ".a999a..",
        ".a9a9a..",
        ".a999a..",
        "..aaa...",
        "........",
    ],
    # 8: hazard / spike
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
    # 9: goal flag
    9: [
        ".bbb.7..",
        ".bbb.7..",
        ".bbb.7..",
        ".....7..",
        ".....7..",
        ".....7..",
        ".....7..",
        "....777.",
    ],
}

# flag 0 (0x01) = solid
# flag 1 (0x02) = hazard
# flag 2 (0x04) = goal
# flag 3 (0x08) = coin
SPRITE_FLAGS: dict[int, int] = {
    4: 0x01,
    5: 0x01,
    7: 0x08,
    8: 0x02,
    9: 0x04,
}


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
    default_input = Path(env_input) if env_input else repo_root / "mario_clone.p8"
    default_output = Path(env_output) if env_output else None

    parser = argparse.ArgumentParser(
        description="Patch a .p8 cartridge's sprite and flag sections."
    )
    parser.add_argument(
        "-i",
        "--input",
        type=Path,
        default=default_input,
        help="Input .p8 file (default: mario_clone.p8 or CART_INPUT env var)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=default_output,
        help="Output .p8 file (default: same as input, or CART_OUTPUT env var)",
    )
    args = parser.parse_args()

    input_path: Path = args.input
    output_path: Path = args.output or input_path

    if not input_path.exists():
        print(f"error: input file not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    header, sections = parse_p8(input_path.read_text())

    # patch __gfx__ and __gff__ from the sprite definitions above
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
