----------------------------------------
-- helpers
----------------------------------------

-- get map tile at pixel coords
function tile_at(px, py)
  return mget(flr(px / 8), flr(py / 8))
end

-- check if pixel position has a
-- tile with given flag set
function tile_flag_at(px, py, flag)
  local t = tile_at(px, py)
  return t > 0 and fget(t, flag)
end

-- check solid at pixel
function is_solid(px, py)
  return tile_flag_at(px, py, f_solid)
end

-- check hazard at pixel
function is_hazard(px, py)
  return tile_flag_at(px, py, f_hazard)
end

-- check goal at pixel
function is_goal(px, py)
  return tile_flag_at(px, py, f_goal)
end

-- collect coin at pixel (remove from map)
function collect_coin(px, py)
  local mx = flr(px / 8)
  local my = flr(py / 8)
  local t = mget(mx, my)
  if t > 0 and fget(t, f_coin) then
    mset(mx, my, 0)
    return true
  end
  return false
end

