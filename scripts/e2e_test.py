#!/usr/bin/env -S uv run --script

# /// script
# requires-python = ">=3.13,<3.14"
# dependencies = [
#     "pillow>=11.0",
#     "playwright>=1.40",
# ]
# [tool.uv]
# exclude-newer = "2026-04-30T00:00:00Z"
# ///

"""
E2E visual regression and functional assertion test runner.

Usage:
    uv run scripts/e2e_test.py                           # all scenarios, native
    uv run scripts/e2e_test.py --scenario idle jump       # specific scenarios
    uv run scripts/e2e_test.py --mode playwright          # headless via HTML export
    uv run scripts/e2e_test.py --update-baselines         # regenerate baselines

Requires PICO-8 installed at /Applications/PICO-8.app for native mode.
Playwright mode also requires PICO-8 for the initial HTML export step.
"""

import argparse
import os
import subprocess
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

# ---------------------------------------------------------------------------
# Reuse cart assembly from generate_cart.py
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))
from generate_cart import LUA_SOURCES, emit_p8, parse_p8  # noqa: E402

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
PICO8_BIN = "/Applications/PICO-8.app/Contents/MacOS/pico8"
DESKTOP = Path.home() / "Desktop"
SCREENSHOT_DIR = Path("/tmp/pico8_e2e")
BASELINE_DIR = REPO_ROOT / "spec" / "e2e_baselines"
DRIVER_TEMPLATE = REPO_ROOT / "spec" / "e2e_driver.lua"
DRIVER_HTML_TEMPLATE = REPO_ROOT / "spec" / "e2e_driver_html.lua"
DIFF_THRESHOLD = 0.005  # 0.5% pixel difference allowed


# ---------------------------------------------------------------------------
# Scenario definition
# ---------------------------------------------------------------------------
@dataclass
class Scenario:
    name: str
    description: str
    # frame -> list of button indices held on that frame
    # frames not listed default to no buttons pressed
    inputs: dict[int, list[int]] = field(default_factory=dict)
    capture_frame: int = 10
    expected_state: int = 0  # st_play=0, st_dead=1, st_clear=2
    expected_coins: int | None = None  # None = don't assert


@dataclass
class GameState:
    state: int
    coins: int
    x: int
    y: int


@dataclass
class TestResult:
    scenario: str
    passed: bool
    visual_pass: bool | None = None
    visual_diff: float = 0.0
    state_pass: bool | None = None
    state_failures: list[str] = field(default_factory=list)
    error: str | None = None


# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------
# Button indices: 0=left, 1=right, 2=up, 3=down, 4=O(jump), 5=X(run)

SCENARIOS: dict[str, Scenario] = {}


def _register_scenarios() -> None:
    """Define all test scenarios."""
    # 1. idle — no input, verify player at spawn
    SCENARIOS["idle"] = Scenario(
        name="idle",
        description="Player stands idle at spawn point",
        inputs={},
        capture_frame=10,
        expected_state=0,
        expected_coins=0,
    )

    # 2. move_right — hold right for 30 frames
    # First coin at col 5 (x=40). At 1.2 px/frame from x=16,
    # reach x=40 at ~20 frames. Coin is collected.
    SCENARIOS["move_right"] = Scenario(
        name="move_right",
        description="Player walks right across flat ground",
        inputs={f: [1] for f in range(0, 30)},
        capture_frame=35,
        expected_state=0,
        expected_coins=1,
    )

    # 3. jump — hold O from frame 5-15 for full jump arc
    # PICO-8 variable jump cuts velocity when O released while rising.
    # Hold ~10 frames for full jump height. Capture mid-air.
    jump_inputs: dict[int, list[int]] = {}
    for f in range(5, 16):
        jump_inputs[f] = [4]  # hold jump
    SCENARIOS["jump"] = Scenario(
        name="jump",
        description="Player jumps in place",
        inputs=jump_inputs,
        capture_frame=12,
        expected_state=0,
        expected_coins=0,
    )

    # 4. coin_pickup — walk right through coins at row 13 cols 5,7,9,11
    # At move_spd=1.2, from x=16: reach col 11 (x=88) at ~60 frames.
    SCENARIOS["coin_pickup"] = Scenario(
        name="coin_pickup",
        description="Player walks right and collects coins",
        inputs={f: [1] for f in range(0, 65)},
        capture_frame=70,
        expected_state=0,
        expected_coins=4,
    )

    # 5. death — walk right into first pit/spike gap
    # Gap at cols 18-19 (x=144-159). At 1.2 px/frame from x=16,
    # reach x=144 at ~107 frames. Fall into spikes below.
    SCENARIOS["death"] = Scenario(
        name="death",
        description="Player walks into first pit and dies on spikes",
        inputs={f: [1] for f in range(0, 115)},
        capture_frame=135,
        expected_state=1,  # st_dead
        expected_coins=4,  # collects 4 coins on the way
    )

    # 6. level_clear — run through entire level, jump over 3 gaps
    # Hold right+run (btns 1,5). Jump (btn 4) held for 12 frames.
    # Each gap has brick ceilings above it (row 12). Must jump
    # early enough that the player rises ABOVE the bricks before
    # reaching them horizontally, avoiding head-bump collision.
    # Gap 1: cols 18-19, bricks at col 17+ row 12 -> jump before x=132 (frame 55)
    # Gap 2: cols 32-33, bricks at col 31+ row 12 -> jump before x=244 (frame 110)
    # Gap 3: cols 48-49, bricks at col 46+ row 12 -> jump before x=364 (frame 170)
    base_inputs: dict[int, list[int]] = {}
    for f in range(0, 280):
        base_inputs[f] = [1, 5]  # hold right + run
    for jf in [53, 108, 168]:
        for f in range(jf, jf + 12):
            base_inputs[f] = [1, 4, 5]  # right + jump + run
    SCENARIOS["level_clear"] = Scenario(
        name="level_clear",
        description="Player runs through entire level and reaches goal",
        inputs=base_inputs,
        capture_frame=265,
        expected_state=2,  # st_clear
        expected_coins=None,
    )


_register_scenarios()


# ---------------------------------------------------------------------------
# Lua driver generation
# ---------------------------------------------------------------------------
def generate_input_table_lua(inputs: dict[int, list[int]]) -> str:
    """Generate Lua code that populates the _inp table efficiently.

    Uses range-based loops for contiguous identical button holds
    to minimize token usage.
    """
    if not inputs:
        return "-- no inputs"

    # Group contiguous frames with identical button sets into ranges
    lines: list[str] = []
    sorted_frames = sorted(inputs.keys())

    i = 0
    while i < len(sorted_frames):
        start = sorted_frames[i]
        btns = sorted(inputs[start])
        # find contiguous run with same buttons
        end = start
        while (
            i + 1 < len(sorted_frames)
            and sorted_frames[i + 1] == end + 1
            and sorted(inputs[sorted_frames[i + 1]]) == btns
        ):
            end = sorted_frames[i + 1]
            i += 1

        btn_str = ",".join(f"[{b}]=true" for b in btns)
        if start == end:
            lines.append(f"_inp[{start}]={{{btn_str}}}")
        else:
            lines.append(f"for f={start},{end} do _inp[f]={{{btn_str}}} end")
        i += 1

    return "\n".join(lines)


def generate_driver_lua(scenario: Scenario, mode: str = "native") -> str:
    """Generate scenario-specific Lua test driver code."""
    if mode == "html":
        template_text = DRIVER_HTML_TEMPLATE.read_text()
    else:
        template_text = DRIVER_TEMPLATE.read_text()

    input_lua = generate_input_table_lua(scenario.inputs)

    result = template_text.replace("$INPUT_TABLE", input_lua)
    result = result.replace("$CAPTURE_FRAME", str(scenario.capture_frame))
    result = result.replace("$SCENARIO_NAME", scenario.name)
    return result


# ---------------------------------------------------------------------------
# Cart assembly
# ---------------------------------------------------------------------------
def assemble_test_cart(scenario: Scenario, mode: str = "native") -> Path:
    """Build a test .p8 cart from game sources + scenario driver."""
    base_text = (REPO_ROOT / "mario.p8").read_text()
    header, sections = parse_p8(base_text)

    lua_parts: list[str] = []
    for src in LUA_SOURCES:
        lua_parts.append((REPO_ROOT / src).read_text())
    lua_parts.append(generate_driver_lua(scenario, mode))

    combined = "".join(lua_parts).rstrip("\n")
    # Patch btnp() calls in game code to use driver's _tbtnp()
    # PICO-8's built-in btnp can't be reliably overridden via
    # global assignment, so we rename calls at assembly time.
    combined = combined.replace("btnp(", "_tbp(")
    sections["__lua__"] = combined.split("\n")

    cart_path = REPO_ROOT / "spec" / f"e2e_{scenario.name}.p8"
    cart_path.write_text(emit_p8(header, sections))
    return cart_path


# ---------------------------------------------------------------------------
# Screenshot handling
# ---------------------------------------------------------------------------
def clear_screenshots(scenario_name: str) -> None:
    """Remove previous screenshots for this scenario from Desktop and tmp."""
    for f in DESKTOP.glob(f"{scenario_name}*.png"):
        f.unlink()
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    for f in SCREENSHOT_DIR.glob(f"{scenario_name}*.png"):
        f.unlink()


def find_screenshot_on_desktop(scenario_name: str) -> Path | None:
    """Find the scenario screenshot on Desktop."""
    candidates = sorted(
        DESKTOP.glob(f"{scenario_name}*.png"),
        key=os.path.getmtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def collect_screenshot(scenario_name: str) -> Path | None:
    """Move screenshot from Desktop to /tmp/pico8_e2e/."""
    src = find_screenshot_on_desktop(scenario_name)
    if not src:
        return None
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    dst = SCREENSHOT_DIR / src.name
    src.rename(dst)
    return dst


# ---------------------------------------------------------------------------
# Image comparison
# ---------------------------------------------------------------------------
def compare_images(actual: Path, baseline: Path) -> tuple[bool, float, int]:
    """Compare two PNG images pixel-by-pixel.

    Returns (passed, diff_ratio, diff_count).
    """
    from PIL import Image

    img_a = Image.open(actual).convert("RGB")
    img_b = Image.open(baseline).convert("RGB")

    if img_a.size != img_b.size:
        total = img_a.size[0] * img_a.size[1]
        return False, 1.0, total

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


def generate_diff_image(actual: Path, baseline: Path, output: Path) -> None:
    """Generate a visual diff image highlighting changed pixels in red."""
    from PIL import Image

    img_a = Image.open(actual).convert("RGB")
    img_b = Image.open(baseline).convert("RGB")

    if img_a.size != img_b.size:
        return

    w, h = img_a.size
    diff_img = Image.new("RGB", (w, h))
    pixels_a = img_a.load()
    pixels_b = img_b.load()
    pixels_d = diff_img.load()

    for y in range(h):
        for x in range(w):
            if pixels_a[x, y] != pixels_b[x, y]:
                pixels_d[x, y] = (255, 0, 0)
            else:
                # dim the matching pixels
                r, g, b = pixels_a[x, y]
                pixels_d[x, y] = (r // 3, g // 3, b // 3)

    diff_img.save(output)


# ---------------------------------------------------------------------------
# State log parsing
# ---------------------------------------------------------------------------
def parse_state_log() -> GameState | None:
    """Parse the game state from clipboard (written by printh @clip)."""
    try:
        result = subprocess.run(["pbpaste"], capture_output=True, text=True, timeout=5)
        text = result.stdout.strip()
        if text:
            parts = text.split(",")
            if len(parts) >= 4:
                return GameState(
                    state=int(parts[0]),
                    coins=int(parts[1]),
                    x=int(parts[2]),
                    y=int(parts[3]),
                )
    except (subprocess.TimeoutExpired, ValueError):
        pass
    return None


def clear_state_log() -> None:
    """Clear clipboard to avoid stale state data."""
    subprocess.run(["pbcopy"], input="", text=True, timeout=5)


# ---------------------------------------------------------------------------
# State assertions
# ---------------------------------------------------------------------------
def check_assertions(scenario: Scenario, actual: GameState) -> list[str]:
    """Check functional assertions, return list of failure messages."""
    failures: list[str] = []
    if actual.state != scenario.expected_state:
        state_names = {0: "st_play", 1: "st_dead", 2: "st_clear"}
        exp = state_names.get(scenario.expected_state, str(scenario.expected_state))
        got = state_names.get(actual.state, str(actual.state))
        failures.append(f"state: expected {exp}, got {got}")
    if scenario.expected_coins is not None and actual.coins != scenario.expected_coins:
        failures.append(
            f"coins: expected {scenario.expected_coins}, got {actual.coins}"
        )
    return failures


# ---------------------------------------------------------------------------
# Native runner
# ---------------------------------------------------------------------------
def run_pico8(cart_path: Path, scenario_name: str, timeout: int = 30) -> bool:
    """Launch PICO-8 with the test cart, poll for screenshot, then kill.

    Returns True if screenshot was captured.
    """
    if not Path(PICO8_BIN).exists():
        print(f"error: PICO-8 not found at {PICO8_BIN}", file=sys.stderr)
        return False

    proc = subprocess.Popen(
        [PICO8_BIN, "-run", str(cart_path)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if find_screenshot_on_desktop(scenario_name):
            time.sleep(0.5)  # flush
            break
        if proc.poll() is not None:
            break
        time.sleep(0.2)

    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

    return find_screenshot_on_desktop(scenario_name) is not None


def run_native(scenario: Scenario, update_baselines: bool = False) -> TestResult:
    """Run a single scenario via native PICO-8."""
    result = TestResult(scenario=scenario.name, passed=False)
    baseline = BASELINE_DIR / f"{scenario.name}.png"

    # assemble cart
    cart_path = assemble_test_cart(scenario, mode="native")
    print(f"  Assembled: {cart_path.name}")

    # clear previous artifacts
    clear_screenshots(scenario.name)
    clear_state_log()

    # run PICO-8
    print(f"  Running PICO-8 (capture at frame {scenario.capture_frame})...")
    if not run_pico8(cart_path, scenario.name):
        result.error = "no screenshot captured (PICO-8 timeout or crash)"
        print(f"  ERROR: {result.error}")
        return result

    # collect screenshot
    screenshot = collect_screenshot(scenario.name)
    if not screenshot:
        result.error = "screenshot not found after PICO-8 run"
        print(f"  ERROR: {result.error}")
        return result
    print(f"  Screenshot: {screenshot.name}")

    # parse state log
    game_state = parse_state_log()
    if game_state:
        print(
            f"  State: state={game_state.state}, coins={game_state.coins}, "
            f"pos=({game_state.x},{game_state.y})"
        )

    # update baselines mode
    if update_baselines:
        import shutil

        BASELINE_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copy2(screenshot, baseline)
        print(f"  Baseline updated: {baseline}")
        result.passed = True
        result.visual_pass = True
        result.state_pass = True
        return result

    # visual comparison
    if not baseline.exists():
        result.error = (
            f"no baseline at {baseline}. Run with --update-baselines to generate."
        )
        print(f"  ERROR: {result.error}")
        return result

    vis_pass, diff_ratio, diff_count = compare_images(screenshot, baseline)
    pct = diff_ratio * 100
    result.visual_pass = vis_pass
    result.visual_diff = diff_ratio

    if vis_pass:
        print(f"  Visual: PASS ({diff_count} pixels differ, {pct:.2f}%)")
    else:
        print(f"  Visual: FAIL ({diff_count} pixels differ, {pct:.2f}%)")
        diff_path = SCREENSHOT_DIR / f"{scenario.name}_diff.png"
        generate_diff_image(screenshot, baseline, diff_path)
        print(f"  Diff image: {diff_path}")

    # functional assertions
    if game_state:
        failures = check_assertions(scenario, game_state)
        result.state_pass = len(failures) == 0
        result.state_failures = failures
        if failures:
            for f in failures:
                print(f"  Assert FAIL: {f}")
        else:
            print("  Assertions: PASS")
    else:
        print("  Assertions: SKIP (no state log)")
        result.state_pass = None

    result.passed = (result.visual_pass or result.visual_pass is None) and (
        result.state_pass is not False
    )
    return result


# ---------------------------------------------------------------------------
# Playwright runner
# ---------------------------------------------------------------------------
def export_html(cart_path: Path) -> Path:
    """Export a .p8 cart to HTML via PICO-8 export command."""
    export_dir = REPO_ROOT / "spec" / "e2e_html_export"
    export_dir.mkdir(parents=True, exist_ok=True)
    html_path = export_dir / "index.html"

    subprocess.run(
        [PICO8_BIN, "-export", str(html_path), str(cart_path)],
        check=True,
        capture_output=True,
    )
    return html_path


async def run_playwright_scenario(
    scenario: Scenario,
    html_path: Path,
    update_baselines: bool = False,
) -> TestResult:
    """Run a single scenario via Playwright against an HTML export."""
    from playwright.async_api import async_playwright

    result = TestResult(scenario=scenario.name, passed=False)
    baseline = BASELINE_DIR / f"{scenario.name}_html.png"
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    screenshot_path = SCREENSHOT_DIR / f"{scenario.name}_html.png"

    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        await page.goto(f"file://{html_path}")

        # wait for PICO-8 runtime to initialize
        await page.wait_for_function(
            "typeof pico8_gpio !== 'undefined'",
            timeout=15000,
        )
        # wait for ready flag from Lua driver
        await page.wait_for_function(
            "pico8_gpio[127] === 1",
            timeout=15000,
        )

        # inject inputs frame-by-frame, synchronized via GPIO frame counter
        for frame in range(scenario.capture_frame + 5):
            # wait for Lua to advance to this frame
            await page.wait_for_function(
                f"pico8_gpio[126] >= {frame % 256}",
                timeout=5000,
            )

            # set button state
            buttons = scenario.inputs.get(frame, [])
            js_parts = []
            for b in range(6):
                val = 1 if b in buttons else 0
                js_parts.append(f"pico8_gpio[{b}]={val}")
            await page.evaluate(";".join(js_parts))

        # read state from GPIO
        state_data = await page.evaluate(
            """() => ({
                state: pico8_gpio[64],
                coins: pico8_gpio[65],
                x: pico8_gpio[66] + pico8_gpio[67] * 256,
                y: pico8_gpio[68] + pico8_gpio[69] * 256
            })"""
        )

        game_state = GameState(
            state=state_data["state"],
            coins=state_data["coins"],
            x=state_data["x"],
            y=state_data["y"],
        )
        print(
            f"  State (GPIO): state={game_state.state}, "
            f"coins={game_state.coins}, pos=({game_state.x},{game_state.y})"
        )

        # screenshot the canvas
        canvas = page.locator("canvas")
        await canvas.screenshot(path=str(screenshot_path))
        print(f"  Screenshot: {screenshot_path.name}")

        await browser.close()

    # update baselines mode
    if update_baselines:
        import shutil

        BASELINE_DIR.mkdir(parents=True, exist_ok=True)
        shutil.copy2(screenshot_path, baseline)
        print(f"  Baseline updated: {baseline}")
        result.passed = True
        result.visual_pass = True
        result.state_pass = True
        return result

    # visual comparison
    if not baseline.exists():
        result.error = (
            f"no baseline at {baseline}. "
            "Run with --update-baselines --mode playwright to generate."
        )
        print(f"  ERROR: {result.error}")
        return result

    vis_pass, diff_ratio, diff_count = compare_images(screenshot_path, baseline)
    pct = diff_ratio * 100
    result.visual_pass = vis_pass
    result.visual_diff = diff_ratio

    if vis_pass:
        print(f"  Visual: PASS ({diff_count} pixels differ, {pct:.2f}%)")
    else:
        print(f"  Visual: FAIL ({diff_count} pixels differ, {pct:.2f}%)")
        diff_path = SCREENSHOT_DIR / f"{scenario.name}_html_diff.png"
        generate_diff_image(screenshot_path, baseline, diff_path)
        print(f"  Diff image: {diff_path}")

    # functional assertions
    failures = check_assertions(scenario, game_state)
    result.state_pass = len(failures) == 0
    result.state_failures = failures
    if failures:
        for f in failures:
            print(f"  Assert FAIL: {f}")
    else:
        print("  Assertions: PASS")

    result.passed = (result.visual_pass or result.visual_pass is None) and (
        result.state_pass is not False
    )
    return result


def run_playwright(scenario: Scenario, update_baselines: bool = False) -> TestResult:
    """Synchronous wrapper for Playwright scenario execution."""
    import asyncio

    # assemble HTML-mode cart and export
    cart_path = assemble_test_cart(scenario, mode="html")
    print(f"  Assembled: {cart_path.name}")

    html_path = export_html(cart_path)
    print(f"  Exported HTML: {html_path}")

    return asyncio.run(run_playwright_scenario(scenario, html_path, update_baselines))


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main() -> None:
    parser = argparse.ArgumentParser(
        description="E2E visual regression and functional assertion tests"
    )
    parser.add_argument(
        "--mode",
        choices=["native", "playwright"],
        default="native",
        help="Execution mode (default: native)",
    )
    parser.add_argument(
        "--scenario",
        nargs="*",
        help="Run specific scenarios (default: all)",
    )
    parser.add_argument(
        "--update-baselines",
        action="store_true",
        help="Capture new baselines instead of comparing",
    )
    args = parser.parse_args()

    if not Path(PICO8_BIN).exists():
        print(f"error: PICO-8 not found at {PICO8_BIN}", file=sys.stderr)
        sys.exit(1)

    # select scenarios
    if args.scenario:
        selected = {}
        for name in args.scenario:
            if name not in SCENARIOS:
                print(f"error: unknown scenario '{name}'", file=sys.stderr)
                print(f"available: {', '.join(SCENARIOS.keys())}", file=sys.stderr)
                sys.exit(1)
            selected[name] = SCENARIOS[name]
    else:
        selected = SCENARIOS

    # run
    results: list[TestResult] = []
    for name, scenario in selected.items():
        print(f"\n--- {name}: {scenario.description} ---")
        if args.mode == "playwright":
            r = run_playwright(scenario, args.update_baselines)
        else:
            r = run_native(scenario, args.update_baselines)
        results.append(r)

    # summary
    print("\n" + "=" * 50)
    passed = sum(1 for r in results if r.passed)
    total = len(results)
    for r in results:
        status = "PASS" if r.passed else "FAIL"
        detail = ""
        if r.error:
            detail = f" ({r.error})"
        elif not r.passed:
            parts = []
            if r.visual_pass is False:
                parts.append(f"visual diff {r.visual_diff * 100:.2f}%")
            if r.state_failures:
                parts.append("; ".join(r.state_failures))
            detail = f" ({', '.join(parts)})" if parts else ""
        print(f"  {status}: {r.scenario}{detail}")
    print(f"\n{passed}/{total} scenarios passed")
    sys.exit(0 if passed == total else 1)


if __name__ == "__main__":
    main()
