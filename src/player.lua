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
    running = false
  }
  return p
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

  -- clamp to left map edge
  if p.x < 0 then p.x = 0 end

  -- vertical movement + resolve
  p.y += p.dy
  p.grounded = false
  if p.dy < 0 then
    -- head bump
    if is_solid(p.x + 1, p.y)
        or is_solid(p.x + p.w - 2, p.y) then
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
function player_check_tiles(p)
  for ox = 1, p.w - 2, p.w - 3 do
    for oy = 0, p.h - 1, flr(p.h / 2) do
      local px = p.x + ox
      local py = p.y + oy
      if is_hazard(px, py) then
        return "dead"
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
  -- fell off bottom of map
  if p.y > map_h * 8 + 16 then
    return "dead"
  end
  return "ok"
end

