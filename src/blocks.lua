----------------------------------------
-- block bumps + pop coins
----------------------------------------
bumped_blocks = {}
pop_coins = {}

-- add a bump entry; target is the
-- tile id to leave behind when the
-- bump completes (same id = no change)
function spawn_bump(mx, my, target)
  -- guard against re-bumping an active
  -- block (head check hits 2 pixels)
  for b in all(bumped_blocks) do
    if b.mx == mx and b.my == my then
      return false
    end
  end
  add(
    bumped_blocks, {
      mx = mx, my = my,
      t = 0,
      draw = mget(mx, my),
      target = target
    }
  )
  return true
end

function update_bumps()
  for i = #bumped_blocks, 1, -1 do
    local b = bumped_blocks[i]
    b.t += 1
    if b.t >= 8 then
      mset(b.mx, b.my, b.target)
      del(bumped_blocks, b)
    end
  end
end

function draw_bumps()
  for b in all(bumped_blocks) do
    local off = min(b.t, 8 - b.t)
    local x = b.mx * 8
    local y = b.my * 8
    -- wipe original tile with sky
    -- then draw the bumped sprite
    -- offset upward
    rectfill(x, y, x + 7, y + 7, 12)
    spr(b.draw, x, y - off)
  end
end

function spawn_pop_coin(mx, my)
  add(
    pop_coins, {
      x = mx * 8,
      y = my * 8,
      dy = -2.5,
      t = 0
    }
  )
end

function update_pop_coins()
  for i = #pop_coins, 1, -1 do
    local c = pop_coins[i]
    c.y += c.dy
    c.dy += 0.2
    c.t += 1
    if c.t > 24 then
      del(pop_coins, c)
    end
  end
end

function draw_pop_coins()
  for c in all(pop_coins) do
    local sn = spr_coin1
    if flr(c.t / 3) % 2 == 1 then
      sn = spr_coin2
    end
    spr(sn, c.x, c.y)
  end
end

