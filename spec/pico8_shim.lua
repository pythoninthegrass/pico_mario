-- pico8_shim.lua
-- Stubs for PICO-8 built-in functions so game code can run under standard Lua.
-- Tests configure the mock map/flag data via _pico8 table.

_pico8 = {
  map = {},   -- [y][x] = sprite number
  flags = {}, -- [sprite_number] = bitfield
  btns = {},  -- [button] = true/false
}

-- reset all mock state
function _pico8.reset()
  _pico8.map = {}
  _pico8.flags = {}
  _pico8.btns = {}
end

-- convenience: set a map tile
function _pico8.set_tile(mx, my, spr_num)
  _pico8.map[my] = _pico8.map[my] or {}
  _pico8.map[my][mx] = spr_num
end

-- convenience: set sprite flags
function _pico8.set_flags(spr_num, bitfield)
  _pico8.flags[spr_num] = bitfield
end

----------------------------------------
-- PICO-8 math
----------------------------------------
function flr(x)
  return math.floor(x)
end

function ceil(x)
  return math.ceil(x)
end

function mid(a, b, c)
  if a > b then a, b = b, a end
  if b > c then b = c end
  if a > b then b = a end
  return b
end

function min(a, b)
  return math.min(a, b)
end

function max(a, b)
  return math.max(a, b)
end

function abs(x)
  return math.abs(x)
end

function sgn(x)
  if x < 0 then return -1 end
  return 1
end

function sin(x)
  return -math.sin(x * math.pi * 2)
end

function cos(x)
  return math.cos(x * math.pi * 2)
end

function sqrt(x)
  return math.sqrt(x)
end

function rnd(x)
  x = x or 1
  return math.random() * x
end

function srand(seed)
  math.randomseed(seed)
end

----------------------------------------
-- PICO-8 table helpers
----------------------------------------
function add(t, v)
  table.insert(t, v)
  return v
end

function del(t, v)
  for i = 1, #t do
    if t[i] == v then
      table.remove(t, i)
      return v
    end
  end
end

function count(t)
  return #t
end

function foreach(t, fn)
  for i = 1, #t do
    fn(t[i])
  end
end

function all(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

----------------------------------------
-- PICO-8 map / sprite
----------------------------------------
function mget(mx, my)
  local row = _pico8.map[my]
  if row then return row[mx] or 0 end
  return 0
end

function mset(mx, my, v)
  _pico8.map[my] = _pico8.map[my] or {}
  _pico8.map[my][mx] = v
end

function fget(spr_num, flag)
  local bits = _pico8.flags[spr_num] or 0
  if flag == nil then return bits end
  -- check if bit `flag` is set
  local mask = 2 ^ flag
  return math.floor(bits / mask) % 2 == 1
end

function fset(spr_num, flag, val)
  local bits = _pico8.flags[spr_num] or 0
  local mask = 2 ^ flag
  if val then
    bits = bits | mask
  else
    bits = bits & ~mask
  end
  _pico8.flags[spr_num] = bits
end

function spr() end
function sspr() end
function palt() end
function pal() end

----------------------------------------
-- PICO-8 input
----------------------------------------
function btn(b)
  return _pico8.btns[b] or false
end

function btnp(b)
  return _pico8.btns[b] or false
end

----------------------------------------
-- PICO-8 graphics (no-ops for testing)
----------------------------------------
function cls() end
function print() end
function rectfill() end
function rect() end
function circfill() end
function circ() end
function line() end
function pset() end
function pget() return 0 end
function camera() end
function clip() end
function map() end
function fillp() end
function color() end

----------------------------------------
-- PICO-8 audio (no-ops for testing)
----------------------------------------
function sfx() end
function music() end

----------------------------------------
-- PICO-8 memory / system
----------------------------------------
function reload() end
function cstore() end
function memcpy() end
function memset() end
function peek() return 0 end
function poke() end
function peek2() return 0 end
function poke2() end
function peek4() return 0 end
function poke4() end
function stat() return 0 end
function time() return 0 end
function t() return 0 end
function sub(s, i, j)
  return string.sub(s, i, j)
end
function tostr(v)
  return tostring(v)
end
function tonum(v)
  return tonumber(v)
end
