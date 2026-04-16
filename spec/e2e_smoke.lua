-- spec/e2e_smoke.lua
-- E2E smoke test driver: init game, run frames,
-- capture screenshot, write result, exit.
-- Appended after game code when assembling test cart.

-- save original _init so we can wrap it
local _game_init=_init

-- deterministic seed
srand(42)

-- frame counter for the test driver
local _test_frame=0
local _test_done=false

-- run game init
_game_init()

-- override _update60 to count frames and
-- capture after the scene has stabilized
local _game_update=_update60
local _game_draw=_draw

function _update60()
 _game_update()
 _test_frame+=1
end

function _draw()
 _game_draw()
 -- capture after 5 frames (scene stable)
 if _test_frame>=5 and not _test_done then
  _test_done=true
  extcmd("set_filename","e2e_smoke")
  extcmd("screen")
  -- runner script detects the screenshot file
  -- and terminates pico-8 externally
 end
end
