----------------------------------------
-- enemies
----------------------------------------
-- spawn positions sourced from
-- docs/smb_1-1_enemies.md (16 goombas +
-- 1 koopa). y = 13 * 8 = 104 (one tile
-- above the ground row at y = 14).
enemy_spawns = {
  { x = 16 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 31 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 40 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 41 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 43 * 8,  y = 13 * 8, type = 'koopa'  },
  { x = 59 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 60 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 63 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 64 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 71 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 72 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 75 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 76 * 8,  y = 13 * 8, type = 'goomba' },
  { x = 100 * 8, y = 13 * 8, type = 'goomba' },
  { x = 101 * 8, y = 13 * 8, type = 'goomba' },
  { x = 103 * 8, y = 13 * 8, type = 'goomba' },
  { x = 104 * 8, y = 13 * 8, type = 'goomba' },
}

enemies = {}
next_spawn = 1

function make_enemy(x, y, etype)
  local s1, s2 = spr_goomba1, spr_goomba2
  if etype == 'koopa' then
    s1, s2 = spr_koopa1, spr_koopa2
  end
  local e = {
    x = x, y = y,
    dx = -enemy_spd, dy = 0,
    w = 6, h = 8,
    etype = etype,
    frame = 0, frame_t = 0,
    spr1 = s1,
    spr2 = s2,
    state = 'alive',    -- alive | squished | shell
    state_t = 0,
    kick_t = 0,         -- post-kick grace so player isn't instantly hit
  }
  return e
end

-- transition an enemy into its post-stomp
-- state.  goombas flatten and tick down
-- to removal; an alive koopa retreats
-- into a stationary shell; a moving
-- shell stomp stops the shell.
function stomp_enemy(e)
  if e.etype == 'koopa' then
    if e.state == 'shell' and e.dx ~= 0 then
      -- stomping a moving shell halts it
      e.dx = 0
      e.kick_t = 0
    elseif e.state == 'alive' then
      e.dx = 0
      e.state = 'shell'
      e.state_t = 0
    end
  else
    e.dx = 0
    e.state = 'squished'
    e.state_t = 0
  end
end

-- launch a stationary shell at shell_spd
-- in the given direction (-1 or 1), with
-- a short grace window so the kicker is
-- not immediately hit by the shell.
function kick_shell(e, dir)
  e.dx = dir * shell_spd
  e.kick_t = kick_grace_len
end

-- backflip an enemy struck by invincible
-- mario: sprite inverts, enemy is
-- launched upward, and solid collision
-- is dropped so it falls off-screen.
function flip_enemy(e)
  e.state = 'flipped'
  e.dx = 0
  e.dy = flip_rise
  e.state_t = 0
end

function init_enemies()
  enemies = {}
  next_spawn = 1
end

-- spawn queued enemies whose x has come
-- within the off-screen-right margin
function spawn_enemies()
  while next_spawn <= #enemy_spawns
      and #enemies < max_enemies
      and enemy_spawns[next_spawn].x < cam_x + 144 do
    local s = enemy_spawns[next_spawn]
    add(enemies, make_enemy(s.x, s.y, s.type))
    next_spawn += 1
  end
end

function update_enemies()
  for i = #enemies, 1, -1 do
    local e = enemies[i]

    if e.state == 'squished' then
      -- flat goomba pauses, then vanishes
      e.state_t += 1
      if e.state_t >= squish_len then
        del(enemies, e)
      end
    elseif e.state == 'flipped' then
      -- backflipping enemy: gravity only,
      -- no collision (falls through floor),
      -- removed once off the bottom of map.
      e.dy += grav
      if e.dy > max_fall then e.dy = max_fall end
      e.y += e.dy
      if e.y > map_h * 8 + 16 then
        del(enemies, e)
      end
    else
      -- alive + shell share walking physics;
      -- a shell's dx was zeroed in stomp_enemy
      -- so it just sits (kick is deferred).
      -- horizontal: walk + reverse on wall
      e.x += e.dx
      if e.dx < 0 then
        if is_solid(e.x, e.y + 1)
            or is_solid(e.x, e.y + e.h - 1) then
          e.x = flr(e.x / 8) * 8 + 8
          e.dx = -e.dx
        end
      elseif e.dx > 0 then
        if is_solid(e.x + e.w - 1, e.y + 1)
            or is_solid(e.x + e.w - 1, e.y + e.h - 1) then
          e.x = flr((e.x + e.w - 1) / 8) * 8 - e.w
          e.dx = -e.dx
        end
      end

      -- gravity
      e.dy += grav
      if e.dy > max_fall then e.dy = max_fall end

      -- vertical: fall + land
      e.y += e.dy
      if e.dy >= 0 then
        if is_solid(e.x + 1, e.y + e.h)
            or is_solid(e.x + e.w - 2, e.y + e.h) then
          e.y = flr((e.y + e.h) / 8) * 8 - e.h
          e.dy = 0
        end
      end

      -- pit removal
      if e.y > map_h * 8 + 16 then
        del(enemies, e)
      else
        if e.state == 'alive' then
          -- walk-cycle animation
          e.frame_t += 1
          if e.frame_t > 8 then
            e.frame_t = 0
            e.frame = (e.frame + 1) % 2
          end
        end
        -- moving shell: kill alive enemies on
        -- contact, decay kick grace timer
        if e.state == 'shell' and e.dx ~= 0 then
          if e.kick_t > 0 then
            e.kick_t -= 1
          end
          for j = #enemies, 1, -1 do
            local e2 = enemies[j]
            if e2 ~= e and e2.state == 'alive'
                and e.x < e2.x + e2.w
                and e.x + e.w > e2.x
                and e.y < e2.y + e2.h
                and e.y + e.h > e2.y then
              e2.state = 'squished'
              e2.dx = 0
              e2.state_t = 0
              local idx = min(stomp_chain + 1, #chain_scores)
              stomp_chain += 1
              local pts = chain_scores[idx]
              score += pts
              spawn_score_pop(e2.x, e2.y - 4, pts)
              sfx(6)
            end
          end
        end
      end
    end
  end
end

function draw_enemies()
  for e in all(enemies) do
    local sn = e.spr1
    if e.state == 'squished' then
      sn = spr_goomba_flat
    elseif e.state == 'shell' or e.state == 'flipped' then
      if e.etype == 'koopa' then
        sn = spr_koopa_shell
      end
      if e.state == 'flipped' and e.etype ~= 'koopa' then
        sn = spr_goomba_flat
      end
    elseif e.frame == 1 then
      sn = e.spr2
    end
    spr(sn, e.x, e.y, 1, 1, e.dx > 0, e.state == 'flipped')
  end
end
