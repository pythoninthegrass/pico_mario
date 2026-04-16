#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13,<3.14"
# dependencies = []
# [tool.uv]
# exclude-newer = "2026-04-30T00:00:00Z"
# ///

# pyright: reportMissingImports=false

"""
Usage:
    uv run scripts/download_maps.py [-o DIR] [--dry-run]

Args:
    -o, --output: Output directory for downloaded map PNGs.
                  Default: <repo>/maps
    --dry-run:    Print URLs without downloading.

Downloads all Super Mario Bros. labeled map PNGs from nesmaps.com
and saves them as maps/smb_{W}-{L}.png.
"""

import argparse
import sys
import urllib.request
from pathlib import Path

BASE_URL = "https://nesmaps.com/maps/SuperMarioBrothers"

# 8 worlds, 4 levels each
LEVELS: list[tuple[int, int]] = [(w, lv) for w in range(1, 9) for lv in range(1, 5)]


def png_url(world: int, level: int) -> str:
    return f"{BASE_URL}/SuperMarioBrosMap{world}-{level}.png"


def output_filename(world: int, level: int) -> str:
    return f"smb_{world}-{level}.png"


def download_maps(output_dir: Path, *, dry_run: bool = False) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)

    for world, level in LEVELS:
        url = png_url(world, level)
        dest = output_dir / output_filename(world, level)

        if dry_run:
            print(f"[dry-run] {url} -> {dest}")
            continue

        if dest.exists():
            print(f"[skip] {dest} already exists")
            continue

        print(f"[download] {url} -> {dest}")
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = resp.read()
        dest.write_bytes(data)
        print(f"  {len(data)} bytes")

    print("done")


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    default_output = repo_root / "maps"

    parser = argparse.ArgumentParser(
        description="Download Super Mario Bros. maps from nesmaps.com"
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=default_output,
        help=f"Output directory (default: {default_output})",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print URLs without downloading",
    )
    args = parser.parse_args()

    try:
        download_maps(args.output, dry_run=args.dry_run)
    except urllib.error.HTTPError as exc:
        print(f"HTTP error: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc


if __name__ == "__main__":
    main()
