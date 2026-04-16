-- spec/helper.lua
-- Busted helper: loads the PICO-8 shim and game code before tests run.

-- Load PICO-8 API stubs into the global environment
require('spec.pico8_shim')

-- Transpile a single line of PICO-8 shorthand into standard Lua 5.x
local function transpile_line(line)
  -- strip single-line comments to avoid false matches inside them
  local code, comment = line:match('^(.-)(%-%-.*)$')
  if not code then
    code = line
    comment = ''
  end

  -- compound assignment: lhs op= rhs -> lhs = lhs op (rhs)
  -- pattern: identifier (with dots/brackets), then operator, then =, then value
  -- we match the operator+= as a unit to avoid confusing e.g. x=-5 with x-=5
  local ops = {
    { pat = '%+%=',  op = '+' },
    { pat = '%-%=',  op = '-' },
    { pat = '%*%=',  op = '*' },
    { pat = '/%=',   op = '/' },
    { pat = '%%%=',  op = '%%' },
    { pat = '\\%=',  op = '//' },  -- PICO-8 \= (integer div)
    { pat = '|%=',   op = '|' },
    { pat = '&%=',   op = '&' },
    { pat = '^^%=',  op = '^^' },
    { pat = '>>%=',  op = '>>' },
    { pat = '<<%=',  op = '<<' },
    { pat = '>>>%=', op = '>>>' },
  }

  for _, entry in ipairs(ops) do
    -- match: lhs (no = before op) op= rhs
    -- use frontier pattern: the char before the op must not be =
    local m_pat = '^(%s*[%w_.%[%]%(%)]+)%s*' .. entry.pat .. '(.+)$'
    local lhs, rhs = code:match(m_pat)
    if lhs then
      -- verify this isn't just a regular assignment like x=-5
      -- by checking the last char of lhs is a valid identifier char or ] or )
      local last = lhs:match('[%w_%]%)]%s*$')
      if last then
        code = lhs .. '=' .. lhs:match('^%s*(.+)$') .. entry.op .. '(' .. rhs .. ')'
        break
      end
    end
  end

  -- != -> ~=
  code = code:gsub('!=', '~=')

  return code .. comment
end

-- Transpile full PICO-8 source
local function transpile_p8(source)
  local out = {}
  for line in source:gmatch('[^\n]*') do
    out[#out + 1] = transpile_line(line)
  end
  return table.concat(out, '\n')
end

-- Extract and load the __lua__ section from the .p8 cartridge
local function load_cart(path) -- luacheck: ignore 211
  local f = io.open(path, 'r')
  if not f then error('cannot open cart: ' .. path) end

  local lines = {}
  local in_lua = false
  for line in f:lines() do
    if line:match('^__lua__') then
      in_lua = true
    elseif line:match('^__[a-z]+__$') then
      in_lua = false
    elseif in_lua then
      lines[#lines + 1] = line
    end
  end
  f:close()

  local code = table.concat(lines, '\n')
  code = transpile_p8(code)

  local chunk, err = load(code, '@' .. path)
  if not chunk then error('failed to parse cart lua: ' .. err) end
  return chunk
end

-- Ordered list of Lua source files (mirrors LUA_SOURCES in generate_cart.py)
local LUA_SOURCES = {
  'src/constants.lua',
  'src/helpers.lua',
  'src/player.lua',
  'src/camera.lua',
  'src/particles.lua',
  'src/main.lua',
  'src/states.lua',
}

-- Load and concatenate src/*.lua files, transpile, and load
local function load_cart_from_sources()
  local parts = {}
  for _, path in ipairs(LUA_SOURCES) do
    local f = io.open(path, 'r')
    if not f then error('cannot open source: ' .. path) end
    parts[#parts + 1] = f:read('*a')
    f:close()
  end

  local code = table.concat(parts)
  code = transpile_p8(code)

  local chunk, err = load(code, '@src/')
  if not chunk then error('failed to parse source lua: ' .. err) end
  return chunk
end

-- Store the loader so tests can call it after configuring mock state
function load_game()
  _pico8.reset()
  local chunk = load_cart_from_sources()
  chunk()
end
