----------------------------------------
-- items: power-up entities that emerge
-- from ? blocks and move through the
-- world.  collection effects integrate
-- with the player power state (TASK-013).
----------------------------------------
items = {}
block_contents = {}

-- register a specific ? block position
-- as dispensing a power-up instead of
-- the default coin.  kind values:
-- "coin" (default), "mushroom", "star",
-- "fireflower".
function register_contents(mx, my, kind)
  add(block_contents, { mx = mx, my = my, kind = kind })
end

function contents_at(mx, my)
  for bc in all(block_contents) do
    if bc.mx == mx and bc.my == my then
      return bc.kind
    end
  end
  return "coin"
end

-- spawn an item above a ? block.  the
-- item starts in rise phase, creeping
-- up one pixel per frame for 8 frames
-- before entering normal walk physics.
function spawn_item(mx, my, kind)
  add(
    items, {
      kind = kind,
      x = mx * 8,
      y = my * 8,
      dx = 0, dy = 0,
      w = 6, h = 8,
      phase = "rise",
      rise_t = 0,
    }
  )
end
-- axis-aligned overlap check between
-- player (w, h) and an item (w, h).
function item_overlaps_player(it)
  return it.x < player.x + player.w
      and it.x + it.w > player.x
      and it.y < player.y + player.h
      and it.y + it.h > player.y
end

function update_items()
  for i = #items, 1, -1 do
    local it = items[i]
    if it.phase == "rise" then
      it.rise_t += 1
      it.y -= 1
      if it.rise_t >= 8 then
        it.phase = "walk"
        if it.kind == "star" then
          it.dx = star_spd
          it.dy = star_bounce   -- first bounce on emerge
        else
          it.dx = 0.5
        end
      end
    elseif it.phase == "walk" then
      -- horizontal movement + wall reverse
      it.x += it.dx
      if it.dx < 0 then
        if is_solid(it.x, it.y + 1)
            or is_solid(it.x, it.y + it.h - 1) then
          it.x = flr(it.x / 8) * 8 + 8
          it.dx = -it.dx
        end
      elseif it.dx > 0 then
        if is_solid(it.x + it.w - 1, it.y + 1)
            or is_solid(it.x + it.w - 1, it.y + it.h - 1) then
          it.x = flr((it.x + it.w - 1) / 8) * 8 - it.w
          it.dx = -it.dx
        end
      end
      -- gravity
      it.dy += grav
      if it.dy > max_fall then it.dy = max_fall end
      -- vertical + landing.  stars auto-
      -- bounce on every ground contact
      -- instead of coming to rest.
      it.y += it.dy
      if it.dy >= 0 then
        if is_solid(it.x + 1, it.y + it.h)
            or is_solid(it.x + it.w - 2, it.y + it.h) then
          it.y = flr((it.y + it.h) / 8) * 8 - it.h
          if it.kind == "star" then
            it.dy = star_bounce
          else
            it.dy = 0
          end
        end
      end
    end

    -- pit removal (below map)
    if it.y > map_h * 8 + 16 then
      del(items, it)
    elseif it.phase == "walk" and item_overlaps_player(it) then
      del(items, it)
      if it.kind == "mushroom" then
        grow_player(player)
        score += mushroom_pts
        spawn_score_pop(it.x, it.y - 4, mushroom_pts)
      elseif it.kind == "star" then
        star_player(player)
        score += star_pts
        spawn_score_pop(it.x, it.y - 4, star_pts)
      else
        -- fireflower remains placeholder
        -- (granted as score) until its
        -- own power state is implemented
        coins += 1
        sfx(4)
      end
    end
  end
end

function draw_items()
  for it in all(items) do
    local sn = spr_mushroom
    if it.kind == "star" then
      sn = spr_star
    elseif it.kind == "fireflower" then
      sn = spr_fireflower
    end
    spr(sn, it.x - 1, it.y)
  end
end
