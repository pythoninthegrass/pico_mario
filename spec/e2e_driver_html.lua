-- e2e test driver (html/playwright mode)
-- appended after game code by e2e_test.py
-- inputs baked into _inp table (same as native driver).
-- writes game state to GPIO for Playwright readback.

-- GPIO protocol (output only):
--  write: 64    = game state (0=play,1=dead,2=clear)
--  write: 65    = coin count
--  write: 66-67 = player.x (low, high byte)
--  write: 68-69 = player.y (low, high byte)
--  write: 125   = capture done (1=ready for screenshot)
--  write: 126   = frame counter (mod 256)
--  write: 127   = ready flag (1=running)

local _gi=_init
srand(42)
local _tf=0
local _td=false
local _pb={}

-- input table for scripted inputs (same as native mode)
local _inp={}
$INPUT_TABLE

_gi()
local _gu=_update60
local _gd=_draw

-- signal ready
poke(0x5f80+127,1)

function btn(i)
 local b=_inp[_tf] or {}
 if b[i] then return true end
 return false
end

-- _tbp replaces btnp calls (btnp cannot be overridden directly)
function _tbp(i)
 local b=_inp[_tf] or {}
 if not b[i] then return false end
 return not _pb[i]
end

function _update60()
 _gu()
 -- save button state for btnp
 _pb={}
 for i=0,5 do
  if btn(i) then _pb[i]=true end
 end
 -- write state to GPIO
 poke(0x5f80+64,state)
 poke(0x5f80+65,coins or 0)
 local px=flr(player.x)
 local py=flr(player.y)
 poke(0x5f80+66,px%256)
 poke(0x5f80+67,flr(px/256))
 poke(0x5f80+68,py%256)
 poke(0x5f80+69,flr(py/256))
 poke(0x5f80+126,_tf%256)
 _tf+=1
end

function _draw()
 _gd()
 if _tf>=$CAPTURE_FRAME and not _td then
  _td=true
  -- signal capture-ready to Playwright via GPIO[125]
  poke(0x5f80+125,1)
 end
end
