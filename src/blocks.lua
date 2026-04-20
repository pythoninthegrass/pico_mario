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

----------------------------------------
-- hidden blocks: invisible until hit
-- from below, then revealed as solid
-- hit block.  content is "coin" or
-- "1up"; 1-up grants +1 life directly
-- (mushroom pickup is TASK-011).
----------------------------------------
hidden_blocks = {}

function register_hidden(mx, my, content)
  add(
    hidden_blocks, {
      mx = mx, my = my,
      content = content
    }
  )
end

function find_hidden(mx, my)
  for hb in all(hidden_blocks) do
    if hb.mx == mx and hb.my == my then
      return hb
    end
  end
  return nil
end

function reveal_hidden(mx, my)
  local hb = find_hidden(mx, my)
  if not hb then return false end
  del(hidden_blocks, hb)
  mset(mx, my, spr_hitblock)
  spawn_bump(mx, my, spr_hitblock)
  if hb.content == "1up" then
    lives += 1
    spawn_pop_coin(mx, my)
    sfx(1)
  else
    spawn_pop_coin(mx, my)
    coins += 1
    sfx(1)
  end
  return true
end

----------------------------------------
-- multi-coin bricks: registered brick
-- tiles that dispense one coin per
-- bump up to 10, within a 240-frame
-- window after the first bump.  on
-- exhaustion or expiry, tile becomes
-- an empty hit block.
----------------------------------------
multi_coin_bricks = {}

function register_multi_coin(mx, my)
  add(
    multi_coin_bricks, {
      mx = mx, my = my,
      bumps_left = 10,
      timer = 0,
      active = false
    }
  )
end

function find_multi_coin(mx, my)
  for mc in all(multi_coin_bricks) do
    if mc.mx == mx and mc.my == my then
      return mc
    end
  end
  return nil
end

function update_multi_coin_bricks()
  for i = #multi_coin_bricks, 1, -1 do
    local mc = multi_coin_bricks[i]
    if mc.active then
      mc.timer -= 1
      if mc.timer <= 0 or mc.bumps_left <= 0 then
        -- wait for any active bump to finish
        -- before rewriting the tile
        local bumping = false
        for b in all(bumped_blocks) do
          if b.mx == mc.mx and b.my == mc.my then
            bumping = true
          end
        end
        if not bumping then
          mset(mc.mx, mc.my, spr_hitblock)
          del(multi_coin_bricks, mc)
        end
      end
    end
  end
end

