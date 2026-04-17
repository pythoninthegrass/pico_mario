---
id: TASK-022
title: Complete E2E visual regression test harness
status: Done
assignee: []
created_date: '2026-04-16 05:03'
updated_date: '2026-04-16 06:36'
labels:
  - testing
  - e2e
dependencies: []
references:
  - scripts/e2e_test.py
  - spec/e2e_driver.lua
  - spec/e2e_driver_html.lua
  - spec/e2e_baselines/
documentation:
  - docs/testing.md
  - docs/architecture.md
priority: medium
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Expand the E2E smoke test spike into a full visual regression and functional assertion framework. The spike (scripts/e2e_smoke.py + spec/e2e_smoke.lua) proved that PICO-8's `extcmd("screen")` can capture deterministic screenshots, which are compared against baselines via Pillow pixel diffing. This task builds out the full harness with multiple test scenarios and a headless CI path via HTML export + Playwright.

**What exists (from spike):**
- `spec/e2e_smoke.lua` -- test driver that inits game, runs 5 frames, captures screenshot
- `scripts/e2e_smoke.py` -- runner that assembles test cart, launches PICO-8, moves screenshot from Desktop to `/tmp/pico8_e2e/`, compares against baseline
- `spec/e2e_baselines/smoke.png` -- single baseline image

**What's needed:**
- Multiple test scenarios with scripted button inputs (movement, jumping, coin collection, death, level clear)
- Deterministic input replay via frame-indexed button table in the test cart
- HTML export + Playwright layer for headless CI (no PICO-8 binary required)
- Functional state assertions alongside visual regression (not just pixel diffs)
- Update docs/testing.md with E2E tier documentation
- Integration into a single test command (e.g. `uv run scripts/e2e_test.py` runs all scenarios)

**Assertion channels (per PICO-8 manual):**
- **Native path -- `printh(str, filename)`**: Test drivers log game state (player position, state enum, coin count) to a file on disk. The Python runner parses the log and asserts on values. No pixel matching needed for functional checks.
- **HTML export path -- GPIO (`poke(0x5f80+i, val)` / JS `pico8_gpio[]`)**: 128 bytes of shared memory between the cart and the host page. Playwright reads GPIO for state assertions and writes to it for input injection. Bidirectional control channel for headless CI.
- **Visual regression (both paths)**: `extcmd("screen")` on native, Playwright screenshot on HTML. Pixel diff against baselines catches unintended rendering changes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Multiple test scenarios capture screenshots at key game states (idle, moving, jumping, coin pickup, death, level clear)
- [x] #2 Scripted input replay drives deterministic game behavior across all scenarios (native: btn() override with frame-indexed table; HTML: GPIO writes for input injection)
- [x] #3 HTML export + Playwright path runs all scenarios headlessly without PICO-8 binary, using GPIO for input injection and state readback
- [x] #4 Baseline update workflow: --update-baselines regenerates all baselines in one command
- [x] #5 Intentional visual breakage (e.g. wrong sprite ID) is detected and reported with diff details
- [x] #6 Test scenarios assert on game state values (player position, game state, coin count) via printh() log parsing (native) or GPIO readback (HTML), not just screenshots
- [x] #7 docs/testing.md updated with E2E tier usage and architecture
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## AC #3: HTML export + Playwright headless path

### PICO-8 config

- Config: `/Users/lance/Library/Mobile Documents/com~apple~CloudDocs/pico-8/config.txt`
- Symlinked to: `/Users/lance/Library/Application Support/pico-8`
- root_path: `/Users/lance/Library/Application Support/pico-8/carts/`
- printh files write to root_path (this is why the earlier printh-to-file approach failed -- we looked in the wrong directory)

### Steps

1. **Fix `export_html()` in e2e_test.py**
   - CLI syntax: `pico8 <cart>.p8 -export "<name>.html"` (single HTML file)
   - For folder export: `pico8 <cart>.p8 -export "-F <dir>.html"` (creates dir/index.html)
   - Use single-file export for simplicity
   - Export dir: `spec/e2e_html_export/`
   - Each scenario needs its own HTML (different driver code baked in)

2. **Fix `e2e_driver_html.lua` GPIO input handling**
   - Current: hybrid (tries _inp table first, falls back to GPIO)
   - Needed: inputs are baked into _inp table (same as native), GPIO is only for state readback
   - This simplifies Playwright -- no need for frame-by-frame GPIO input injection from JS
   - Playwright just waits for the scenario to complete and reads final state from GPIO

3. **Fix `run_playwright_scenario()` in e2e_test.py**
   - Remove frame-by-frame GPIO input injection loop (inputs are baked into Lua)
   - Wait for GPIO[127] ready flag, then wait for capture frame (poll GPIO[126] frame counter)
   - Read state from GPIO[64-69]
   - Screenshot the canvas element
   - Compare against separate HTML baselines (`<name>_html.png`) since rendering may differ slightly from native PICO-8

4. **Install Playwright browsers**
   - `playwright install chromium` (one-time setup)
   - Add note to docs/testing.md about this requirement

5. **Generate HTML baselines**
   - `uv run scripts/e2e_test.py --mode playwright --update-baselines`
   - Commit HTML baselines alongside native baselines

6. **Test visual breakage detection in Playwright mode**

### Verification

- `uv run scripts/e2e_test.py --mode playwright` passes all 6 scenarios
- `uv run scripts/e2e_test.py --mode playwright --scenario idle` works for single scenario
- GPIO state readback matches native printh values for all scenarios
<!-- SECTION:PLAN:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Expanded the E2E smoke test spike into a full 6-scenario visual regression and functional assertion framework. Native path runs real PICO-8, captures screenshots via extcmd, reads game state via printh to clipboard, and compares against baseline PNGs with Pillow pixel diffing. Playwright/HTML path runs headlessly via PICO-8 HTML export + Chromium, using GPIO for state readback and baked-in input tables for deterministic replay. Key discoveries: (1) PICO-8 btnp() cannot be overridden via global assignment -- solved by patching btnp( to _tbp( at assembly time. (2) HTML export requires __label__ section -- injected a dummy black label. (3) Headless Chromium AudioContext stays suspended, blocking PICO-8 autoplay -- solved by calling p8_run_cart() from JS. (4) GPIO[125] used as capture-done flag instead of frame counter (which wraps at 256, causing false-positive for level_clear at frame 265).
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 Cart loads in PICO-8 without errors
- [x] #2 Play-test affected functionality
- [x] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [x] #4 Token count verified under 8192 limit
<!-- DOD:END -->
