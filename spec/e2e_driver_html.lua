-- e2e test driver (html/playwright mode)
-- appended after game code by e2e_test.py
-- reads button input from GPIO (bytes 0-5),
-- writes game state to GPIO for Playwright readback.

-- GPIO protocol:
--  read:  0-5   = button state (0=off, nonzero=on)
--  write: 64    = game state (0=play,1=dead,2=clear)
--  write: 65    = coin count
--  write: 66-67 = player.x (low, high byte)
--  write: 68-69 = player.y (low, high byte)
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
 -- try scripted input table first, fall back to GPIO
 local b=_inp[_tf]
 if b then
  return b[i] or false
 end
 return peek(0x5f80+i)!=0
end

function btnp(i)
 if not btn(i) then return false end
 return not (_pb[i] or false)
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
  -- no extcmd in html mode; playwright takes the screenshot
 end
end
