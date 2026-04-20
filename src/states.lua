----------------------------------------
-- state: playing
----------------------------------------
function update_play()
  local p = player

  -- decay power-state timers each frame
  if p.invuln_t > 0 then
    p.invuln_t -= 1
  end
  if p.transform_t > 0 then
    p.transform_t -= 1
  end

  -- run state (x button)
  p.running = btn(5)
  local spd = move_spd
  if p.running then spd = run_spd end

  -- horizontal input (suspended during
  -- the grow/shrink animation so the
  -- player briefly pauses as they
  -- transform)
  p.dx = 0
  if p.transform_t == 0 then
    if btn(0) then
      p.dx = -spd
      p.facing = -1
    end
    if btn(1) then
      p.dx = spd
      p.facing = 1
    end
  end

  -- coyote time: track grace frames
  -- after walking off an edge
  if p.grounded then
    p.coyote_t = coyote
  else
    p.coyote_t = max(p.coyote_t - 1, 0)
  end

  -- jump: o button only (btn 4)
  -- stronger jump when running
  local can_jump = p.grounded or p.coyote_t > 0
  if can_jump and btnp(4) and p.transform_t == 0 then
    if p.running then
      p.dy = run_jump_str
    else
      p.dy = jump_str
    end
    p.grounded = false
    p.coyote_t = 0
    sfx(0)
  end

  -- variable jump: cut upward velocity
  -- when o button released early
  if p.dy < 0 and not btn(4) then
    p.dy *= 0.4
  end

  -- gravity
  p.dy += grav
  if p.dy > max_fall then p.dy = max_fall end

  -- move with collision
  player_move(p)

  -- animation timer
  if p.dx != 0 and p.grounded then
    p.frame_t += 1
    if p.frame_t > 4 then
      p.frame_t = 0
      p.frame = (p.frame + 1) % 3
    end
  else
    p.frame = 0
    p.frame_t = 0
  end

  -- tile interactions: hazard contact
  -- routes through damage_player so big
  -- mario shrinks.  pit falls stay fatal
  -- regardless of power state.
  local result = player_check_tiles(p)
  if result == "hit" then
    result = damage_player(p)
  end
  if result == "dead" then
    state = st_dead
    death_t = 0
    spawn_particles(p.x + 3, p.y + 4, 8, 20)
    sfx(2)
  elseif result == "clear" then
    state = st_clear
    clear_t = 0
    spawn_particles(p.x + 3, p.y + 4, 10, 30)
    sfx(3)
  end

  update_cam(p)

  spawn_enemies()
  update_enemies()

  -- player-enemy collision.  stomp takes
  -- precedence over side-hits so adjacent
  -- enemies don't kill a falling player.
  if state == st_play then
    local hit = check_enemy_hits(p)
    if hit == "hit" then
      if damage_player(p) == "dead" then
        state = st_dead
        death_t = 0
        spawn_particles(p.x + 3, p.y + 4, 8, 20)
        sfx(2)
      end
    end
  end

  -- chain resets once the player lands
  if p.grounded then stomp_chain = 0 end
end

-- aabb overlap + stomp/side classifier.
-- returns "stomp" when a stomp happened
-- (one or more enemies), "hit" when the
-- player touched an alive enemy from the
-- side or below, and "ok" otherwise.
-- invuln skips both branches so shrink
-- i-frames behave as in SMB.
function check_enemy_hits(p)
  if p.invuln_t > 0 then return "ok" end

  local stomped = false
  for i = #enemies, 1, -1 do
    local e = enemies[i]
    local hittable = e.state == 'alive'
        or e.state == 'shell'
    if hittable
        and p.x + 1 < e.x + e.w
        and p.x + p.w - 1 > e.x
        and p.y < e.y + e.h
        and p.y + p.h > e.y then
      local stomp = p.dy > 0
          and p.y + p.h - e.y <= 6
      local shell_still = e.state == 'shell' and e.dx == 0
      local shell_moving = e.state == 'shell' and e.dx ~= 0
      if stomp then
        if shell_still then
          -- stomp on parked shell kicks it
          kick_shell(e, p.facing)
          p.dy = stomp_bounce
          p.grounded = false
          sfx(6)
        elseif shell_moving then
          -- stomp halts a moving shell
          e.dx = 0
          e.kick_t = 0
          p.dy = stomp_bounce
          p.grounded = false
          sfx(6)
        else
          -- alive goomba/koopa stomp
          stomp_enemy(e)
          p.dy = stomp_bounce
          p.grounded = false
          local idx = min(stomp_chain + 1, #chain_scores)
          stomp_chain += 1
          local pts = chain_scores[idx]
          score += pts
          spawn_score_pop(e.x, e.y - 4, pts)
          sfx(6)
          stomped = true
        end
      else
        if shell_still then
          -- side contact kicks the shell
          -- away from the player
          local dir = 1
          if p.x + p.w / 2 >= e.x + e.w / 2 then
            dir = -1
          end
          kick_shell(e, dir)
          sfx(6)
        elseif shell_moving and e.kick_t > 0 then
          -- freshly-kicked shell: ignore
        else
          return "hit"
        end
      end
    end
  end
  if stomped then return "stomp" end
  return "ok"
end

function get_player_spr(p)
  if p.power >= 1 then
    if not p.grounded then return spr_big_jump end
    if p.dx != 0 then return spr_big_run1 + p.frame % 2 end
    return spr_big_idle
  end
  if not p.grounded then return 3 end
  if p.dx != 0 then return 1 + p.frame % 2 end
  return 1
end

----------------------------------------
-- state: dead
----------------------------------------
function update_dead()
  death_t += 1
  if death_t > 20 and (btnp(4) or btnp(5)) then
    _init()
  end
end

----------------------------------------
-- state: level clear
----------------------------------------
function update_clear()
  clear_t += 1
  if clear_t > 30 and (btnp(4) or btnp(5)) then
    _init()
  end
end

