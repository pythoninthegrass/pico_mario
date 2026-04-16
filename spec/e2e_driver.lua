-- e2e test driver (native mode)
-- appended after game code by e2e_test.py
-- overrides btn/btnp with frame-indexed input table,
-- logs state via printh, captures screenshot via extcmd.

-- save originals before pico-8 auto-calls _init
local _gu = _update60
local _gd = _draw
srand(42)
local _tf = 0
local _td = false
local _pb = {}

-- frame->button table, filled by python template
-- format: _inp[frame]={[btn_id]=true, ...}
local _inp = {}
$INPUT_TABLE

function btn(i)
  local b = _inp[_tf] or {}
  if b[i] then return true end
  return false
end

-- _tbp replaces btnp calls in game code
-- (pico-8 built-in btnp can't be reliably
-- overridden via global assignment)
function _tbp(i)
  local b = _inp[_tf] or {}
  if not b[i] then return false end
  return not _pb[i]
end

function _update60()
  _gu()
  -- save current buttons for btnp next frame
  _pb = {}
  local b = _inp[_tf] or {}
  for k, v in pairs(b) do _pb[k] = v end
  _tf += 1
end

function _draw()
  _gd()
  if _tf >= $CAPTURE_FRAME and not _td then
    _td = true
    -- log game state: state,coins,x,y,frame to clipboard
    local msg = state..","..coins..","..flr(player.x)..","..flr(player.y)..","..(_tf)
    printh(msg, "@clip")
    extcmd("set_filename", "$SCENARIO_NAME")
    extcmd("screen")
  end
end
