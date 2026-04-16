#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13,<3.14"
# dependencies = [
#     "pillow>=11.0",
# ]
# [tool.uv]
# exclude-newer = "2026-04-30T00:00:00Z"
# ///

"""
E2E smoke test: assemble a test cart, run it in PICO-8, compare
the captured screenshot against a baseline image.

Usage:
    uv run scripts/e2e_smoke.py [--update-baselines]

Requires PICO-8 installed at /Applications/PICO-8.app.
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PICO8_BIN = "/Applications/PICO-8.app/Contents/MacOS/pico8"
DESKTOP = Path.home() / "Desktop"
SCREENSHOT_DIR = Path("/tmp/pico8_e2e")
BASELINE_DIR = REPO_ROOT / "spec" / "e2e_baselines"
BASELINE_IMG = BASELINE_DIR / "smoke.png"
TEST_CART = REPO_ROOT / "spec" / "e2e_smoke.p8"
DIFF_THRESHOLD = 0.005  # 0.5% pixel difference allowed

# Source files in include order (must match generate_cart.py LUA_SOURCES)
LUA_SOURCES = [
    "src/constants.lua",
    "src/helpers.lua",
    "src/player.lua",
    "src/camera.lua",
    "src/particles.lua",
    "src/main.lua",
    "src/states.lua",
]

TEST_DRIVER = "spec/e2e_smoke.lua"


def assemble_test_cart() -> None:
    """Build a test .p8 cart from game sources + test driver."""
    import re

    # read the base cart for non-lua sections
    base_text = (REPO_ROOT / "mario.p8").read_text()

    # parse sections
    section_re = re.compile(r"^(__\w+__)$")
    header: list[str] = []
    sections: dict[str, list[str]] = {}
    current: str | None = None

    for line in base_text.split("\n"):
        m = section_re.match(line)
        if m:
            current = m.group(1)
            sections[current] = []
        elif current is None:
            header.append(line)
        else:
            sections[current].append(line)

    # assemble lua: game code + test driver appended
    lua_parts: list[str] = []
    for src in LUA_SOURCES:
        lua_parts.append((REPO_ROOT / src).read_text())
    lua_parts.append((REPO_ROOT / TEST_DRIVER).read_text())
    combined = "".join(lua_parts).rstrip("\n")
    sections["__lua__"] = combined.split("\n")

    # emit .p8
    section_order = ["__lua__", "__gfx__", "__gff__", "__map__", "__sfx__", "__music__"]
    parts: list[str] = list(header)
    for sec in section_order:
        if sec in sections:
            parts.append(sec)
            parts.extend(sections[sec])
    for sec, lines in sections.items():
        if sec not in section_order:
            parts.append(sec)
            parts.extend(lines)

    TEST_CART.write_text("\n".join(parts))
    print(f"Assembled test cart: {TEST_CART}")


def find_screenshot_on_desktop() -> Path | None:
    """Find the screenshot on Desktop (where PICO-8 saves it)."""
    candidates = sorted(
        DESKTOP.glob("e2e_smoke*.png"), key=os.path.getmtime, reverse=True
    )
    if candidates:
        return candidates[0]
    return None


def find_screenshot() -> Path | None:
    """Find the screenshot in our temp dir."""
    candidates = sorted(
        SCREENSHOT_DIR.glob("e2e_smoke*.png"), key=os.path.getmtime, reverse=True
    )
    if candidates:
        return candidates[0]
    return None


def collect_screenshot() -> Path | None:
    """Move screenshot from Desktop to /tmp/pico8_e2e/."""
    src = find_screenshot_on_desktop()
    if not src:
        return None
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    dst = SCREENSHOT_DIR / src.name
    src.rename(dst)
    return dst


def clear_previous_screenshots() -> None:
    """Remove previous e2e screenshot files from Desktop and /tmp."""
    for f in DESKTOP.glob("e2e_smoke*.png"):
        f.unlink()
        print(f"Removed old screenshot: {f.name}")
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    for f in SCREENSHOT_DIR.glob("e2e_smoke*.png"):
        f.unlink()


def compare_images(actual: Path, baseline: Path) -> tuple[bool, float, int]:
    """Compare two PNG images pixel-by-pixel.

    Returns (passed, diff_ratio, diff_count).
    """
    from PIL import Image

    img_a = Image.open(actual).convert("RGB")
    img_b = Image.open(baseline).convert("RGB")

    if img_a.size != img_b.size:
        print(f"Size mismatch: actual={img_a.size} baseline={img_b.size}")
        return False, 1.0, img_a.size[0] * img_a.size[1]

    pixels_a = img_a.load()
    pixels_b = img_b.load()
    w, h = img_a.size
    diff_count = 0
    for y in range(h):
        for x in range(w):
            if pixels_a[x, y] != pixels_b[x, y]:
                diff_count += 1

    total = w * h
    diff_ratio = diff_count / total
    passed = diff_ratio <= DIFF_THRESHOLD
    return passed, diff_ratio, diff_count


def run_pico8() -> int:
    """Launch PICO-8 with the test cart, poll for screenshot, then kill."""
    if not Path(PICO8_BIN).exists():
        print(f"error: PICO-8 not found at {PICO8_BIN}", file=sys.stderr)
        return 1

    print(f"Launching: {PICO8_BIN} -run {TEST_CART}")
    proc = subprocess.Popen([PICO8_BIN, "-run", str(TEST_CART)])

    # poll for the screenshot file to appear on Desktop
    deadline = time.monotonic() + 30
    while time.monotonic() < deadline:
        if find_screenshot_on_desktop():
            # screenshot captured -- give a brief moment for flush
            time.sleep(0.5)
            break
        # check if PICO-8 exited on its own
        if proc.poll() is not None:
            break
        time.sleep(0.2)

    # terminate PICO-8 if still running
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

    return 0


def main() -> None:
    parser = argparse.ArgumentParser(description="E2E smoke test for PICO-8 cart")
    parser.add_argument(
        "--update-baselines",
        action="store_true",
        help="Capture new baseline instead of comparing",
    )
    args = parser.parse_args()

    # step 1: assemble test cart
    assemble_test_cart()

    # step 2: clean up previous outputs
    clear_previous_screenshots()

    # step 3: run PICO-8
    run_pico8()

    # step 4: move screenshot from Desktop to /tmp/pico8_e2e/
    screenshot = collect_screenshot()
    if not screenshot:
        print("FAIL: no screenshot captured by test cart")
        sys.exit(1)

    print(f"Screenshot captured: {screenshot}")

    # step 5: update baselines or compare
    if args.update_baselines:
        BASELINE_DIR.mkdir(parents=True, exist_ok=True)
        import shutil

        shutil.copy2(screenshot, BASELINE_IMG)
        print(f"Baseline updated: {BASELINE_IMG}")
        sys.exit(0)

    if not BASELINE_IMG.exists():
        print(f"No baseline found at {BASELINE_IMG}")
        print("Run with --update-baselines to generate the initial baseline")
        sys.exit(1)

    passed, diff_ratio, diff_count = compare_images(screenshot, BASELINE_IMG)
    pct = diff_ratio * 100
    if passed:
        print(
            f"PASS: {diff_count} pixels differ ({pct:.2f}%, threshold {DIFF_THRESHOLD * 100}%)"
        )
    else:
        print(
            f"FAIL: {diff_count} pixels differ ({pct:.2f}%, threshold {DIFF_THRESHOLD * 100}%)"
        )
        sys.exit(1)


if __name__ == "__main__":
    main()
