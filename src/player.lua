----------------------------------------
-- player object
----------------------------------------
function make_player(sx, sy)
  local p = {
    x = sx, y = sy,
    dx = 0, dy = 0,
    w = 6, h = 8,
    grounded = false,
    facing = 1,
    frame = 0,
    frame_t = 0,
    spawn_x = sx,
    spawn_y = sy,
    coyote_t = 0,
    running = false,
    power = 0,        -- 0=small, 1=big, 2=fire (reserved)
    invuln_t = 0,     -- post-shrink invulnerability timer
    transform_t = 0,  -- grow/shrink animation timer
  }
  return p
end

-- grow small -> big.  shifts y up 8 px
-- so the feet stay planted on ground.
function grow_player(p)
  if p.power ~= 0 then return end
  p.power = 1
  p.y -= 8
  p.h = 16
  p.transform_t = transform_len
  sfx(4)
end

-- shrink big -> small.  shifts y down
-- 8 px so feet stay grounded, grants
-- post-hit invulnerability.
function shrink_player(p)
  if p.power < 1 then return end
  p.power = 0
  p.y += 8
  p.h = 8
  p.invuln_t = invuln_len
  p.transform_t = transform_len
  sfx(5)
end

-- route damage through the power state.
-- returns "dead" when small mario is
-- hit, "ok" when the hit was absorbed
-- (shrink or invulnerability).
function damage_player(p)
  if p.invuln_t > 0 then return "ok" end
  if p.power > 0 then
    shrink_player(p)
    return "ok"
  end
  return "dead"
end

-- move player with collision resolve
function player_move(p)
  -- horizontal movement + resolve
  p.x += p.dx
  if p.dx < 0 then
    -- left edge check
    if is_solid(p.x, p.y + 1)
        or is_solid(p.x, p.y + p.h - 1) then
      p.x = flr(p.x / 8) * 8 + 8
      p.dx = 0
    end
  elseif p.dx > 0 then
    -- right edge check
    if is_solid(p.x + p.w - 1, p.y + 1)
        or is_solid(p.x + p.w - 1, p.y + p.h - 1) then
      p.x = flr((p.x + p.w - 1) / 8) * 8 - p.w
      p.dx = 0
    end
  end

  -- lock to left edge of visible screen
  if p.x < cam_x then
    p.x = cam_x
    if p.dx < 0 then p.dx = 0 end
  end

  -- vertical movement + resolve
  p.y += p.dy
  p.grounded = false
  if p.dy < 0 then
    -- reveal hidden blocks in head row
    -- first so they act solid this frame
    local hmy = flr(p.y / 8)
    local hmx_l = flr((p.x + 1) / 8)
    local hmx_r = flr((p.x + p.w - 2) / 8)
    reveal_hidden(hmx_l, hmy)
    if hmx_r ~= hmx_l then
      reveal_hidden(hmx_r, hmy)
    end
    -- head bump
    local hit_l = is_solid(p.x + 1, p.y)
    local hit_r = is_solid(p.x + p.w - 2, p.y)
    if hit_l or hit_r then
      if hit_l then
        bump_block(flr((p.x + 1) / 8), flr(p.y / 8))
      end
      if hit_r then
        bump_block(flr((p.x + p.w - 2) / 8), flr(p.y / 8))
      end
      p.y = flr(p.y / 8) * 8 + 8
      p.dy = 0
    end
  elseif p.dy >= 0 then
    -- landing
    if is_solid(p.x + 1, p.y + p.h)
        or is_solid(p.x + p.w - 2, p.y + p.h) then
      p.y = flr((p.y + p.h) / 8) * 8 - p.h
      p.dy = 0
      p.grounded = true
    end
  end

  -- grounded check when stationary
  if not p.grounded and p.dy == 0 then
    if is_solid(p.x + 1, p.y + p.h + 1)
        or is_solid(p.x + p.w - 2, p.y + p.h + 1) then
      p.grounded = true
    end
  end
end

-- check hazard/goal/coin overlap
-- returns:
--   "hit"   hazard tile touched (damage routes
--           through damage_player)
--   "dead"  fell off bottom of map (always fatal)
--   "clear" goal reached
--   "ok"    nothing interesting
function player_check_tiles(p)
  for ox = 1, p.w - 2, p.w - 3 do
    for oy = 0, p.h - 1, flr(p.h / 2) do
      local px = p.x + ox
      local py = p.y + oy
      if is_hazard(px, py) then
        return "hit"
      end
      if is_goal(px, py) then
        return "clear"
      end
      if collect_coin(px, py) then
        coins += 1
        sfx(1)
      end
    end
  end
  -- fell off bottom of map (always fatal)
  if p.y > map_h * 8 + 16 then
    return "dead"
  end
  return "ok"
end

