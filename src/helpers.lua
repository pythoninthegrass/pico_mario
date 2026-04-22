----------------------------------------
-- helpers
----------------------------------------

-- zero-pad a number to w digits
function zpad(n, w)
  local s = ""..n
  while #s < w do s = "0"..s end
  return s
end

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

-- bump block at tile coords
-- ? block: release registered content
-- (coin by default, or an item), then
-- convert to hit block.  multi-coin
-- brick: one coin per bump for up to
-- 10 within a 4s window.  plain brick:
-- bump animation only (small mario).
function bump_block(mx, my)
  local t = mget(mx, my)
  if t == 0 then return end
  if fget(t, f_question) then
    if spawn_bump(mx, my, spr_hitblock) then
      local kind = contents_at(mx, my)
      if kind == "coin" then
        spawn_pop_coin(mx, my)
        coins += 1
        score += coin_pts
        sfx(1)
      else
        spawn_item(mx, my, kind)
        sfx(4)
      end
    end
  elseif fget(t, f_breakable) then
    local mc = find_multi_coin(mx, my)
    if mc and mc.bumps_left > 0
        and (not mc.active or mc.timer > 0) then
      if spawn_bump(mx, my, t) then
        spawn_pop_coin(mx, my)
        coins += 1
        score += coin_pts
        sfx(1)
        mc.bumps_left -= 1
        if not mc.active then
          mc.active = true
          mc.timer = 240
        end
      end
    elseif player and player.power > 0 then
      -- big mario shatters the brick
      mset(mx, my, 0)
      spawn_particles(mx * 8 + 4, my * 8 + 4, 4, 8)
      sfx(1)
    else
      spawn_bump(mx, my, t)
    end
  end
end
