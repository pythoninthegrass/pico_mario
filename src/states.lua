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
  if p.invince_t > 0 then
    p.invince_t -= 1
    if p.invince_t == 0 then
      music(0)
    end
  end

  -- run state (x button)
  p.running = btn(5)

  -- horizontal input (suspended during
  -- the grow/shrink animation so the
  -- player briefly pauses as they
  -- transform)
  local input_dir = 0
  if p.transform_t == 0 then
    if btn(0) then input_dir = -1 end
    if btn(1) then input_dir = 1 end
  end
  apply_horiz_physics(p, input_dir, p.running)

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
    enter_death(p)
  elseif result == "clear" then
    enter_clear(p)
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
        enter_death(p)
      end
    end
  end

  -- chain resets once the player lands
  if p.grounded then stomp_chain = 0 end

  update_timer(p)
end

-- advance the level timer by one frame.
-- kills the player when it reaches zero.
function update_timer(p)
  timer_tick += 1
  if timer_tick >= timer_rate then
    timer_tick = 0
    timer -= 1
    if timer <= 0 then
      timer = 0
      enter_death(p)
    elseif timer == timer_warn and not timer_warned then
      timer_warned = true
      music(2)
    end
  end
end

-- aabb overlap + stomp/side classifier.
-- returns "stomp" when a stomp happened
-- (one or more enemies), "hit" when the
-- player touched an alive enemy from the
-- side or below, and "ok" otherwise.
-- invuln skips both branches so shrink
-- i-frames behave as in SMB.  star
-- invincibility instead backflips every
-- touched enemy and awards chain points.
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
      if p.invince_t > 0 then
        -- star: backflip + score, no damage
        flip_enemy(e)
        local idx = min(stomp_chain + 1, #chain_scores)
        stomp_chain += 1
        local pts = chain_scores[idx]
        score += pts
        spawn_score_pop(e.x, e.y - 4, pts)
        sfx(6)
      else
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
-- classic smb death: mario pops up, pauses
-- at apex, and falls off the bottom of the
-- screen.  collision is disabled so he
-- passes through the ground; everything
-- else in the world is frozen by _update60.
function enter_death(p)
  state = st_dead
  death_t = 0
  p.dx = 0
  p.dy = -4
  p.grounded = false
  sfx(2)
end

function update_dead()
  death_t += 1
  if death_t == 1 then
    lives -= 1
    if lives < 0 then lives = 0 end
  end
  local p = player
  p.dy += grav
  if p.dy > max_fall then p.dy = max_fall end
  p.y += p.dy
  if death_t >= death_to_screen then
    if lives > 0 then
      start_level()
      state = st_lives
      lives_t = 0
    else
      state = st_gameover
      gameover_t = 0
    end
  end
end

----------------------------------------
-- state: title / lives / game over
----------------------------------------
function update_title()
  title_t += 1
  if title_t > 30 and btnp(4) then
    state = st_lives
    lives_t = 0
  end
end

function update_lives()
  lives_t += 1
  if lives_t >= lives_hold then
    state = st_play
  end
end

function update_gameover()
  gameover_t += 1
  if gameover_t >= gameover_hold
      or (gameover_t > 30 and btnp(4)) then
    _init()
  end
end

----------------------------------------
-- state: level clear
----------------------------------------
-- grab-height score tiers: top=5000,
-- upper=2000, middle=800, lower=400,
-- else=100 based on mario.y at contact.
function enter_clear(p)
  state = st_clear
  clear_t = 0
  clear_phase = cp_slide
  enter_t = 0
  music(-1)
  sfx(3)

  local gy = p.y
  local pts = 100
  if gy < 56 then pts = 5000
  elseif gy < 72 then pts = 2000
  elseif gy < 88 then pts = 800
  elseif gy < 96 then pts = 400
  end
  score += pts
  grab_pts = pts
  grab_y = gy

  -- snap to left side of pole for slide
  p.x = pole_x - 5
  p.dx = 0
  p.dy = 0
  p.facing = -1
  p.grounded = false
  p.frame = 0
  p.frame_t = 0

  -- slide target: ground surface minus
  -- player height so feet land at y=112
  -- regardless of small/big mario
  slide_target_y = 112 - p.h

  -- firework count: 1, 3, or 6 based on
  -- timer's last digit at moment of grab
  local d = timer % 10
  if d == 1 or d == 3 or d == 6 then
    fw_count = d
  else
    fw_count = 0
  end
  fw_fired = 0
  fw_t = 0
  fw_x = 0
  fw_y = 0

  -- flag starts at top; replace map tile
  -- with shaft so pole stays continuous
  -- as the flag slides down.
  flag_y = pole_top_y + 8
  mset(flag_map_x, flag_map_y, spr_pole_shaft)
end

function update_clear()
  clear_t += 1
  local p = player

  if clear_phase == cp_slide then
    if p.y < slide_target_y then
      p.y += slide_spd
    end
    if flag_y < pole_bottom_y then
      flag_y += slide_spd
    end
    if p.y >= slide_target_y
        and flag_y >= pole_bottom_y then
      p.y = slide_target_y
      flag_y = pole_bottom_y
      clear_phase = cp_walk
      -- hop to right side of pole
      p.x = pole_x + 8
      p.facing = 1
    end
  elseif clear_phase == cp_walk then
    p.x += walk_cut_spd
    p.frame_t += 1
    if p.frame_t > 4 then
      p.frame_t = 0
      p.frame = (p.frame + 1) % 3
    end
    update_cam(p)
    if p.x >= castle_wall_x then
      clear_phase = cp_enter
      enter_t = 0
    end
  elseif clear_phase == cp_enter then
    enter_t += 1
    p.x += walk_cut_spd
    -- raise peace flag on castle
    if peace_y > peace_end_y then
      peace_y -= peace_spd
    end
    if enter_t > enter_hold then
      clear_phase = cp_tally
      clear_t = 0
    end
  elseif clear_phase == cp_tally then
    if timer > 0 then
      local drain = min(timer, timer_drain_spd)
      timer -= drain
      score += drain * timer_pts
    elseif clear_t > tally_hold then
      if fw_count > 0 then
        clear_phase = cp_fireworks
        fw_t = 0
        fw_fired = 0
        clear_t = 0
      else
        clear_phase = cp_done
      end
    end
  elseif clear_phase == cp_fireworks then
    fw_t += 1
    if fw_t == 1 then
      -- pick position for this firework
      -- cycle through 6 spots in the sky
      local idx = fw_fired % 6
      fw_x = cam_x + 20 + idx * 19
      fw_y = 28 + (idx % 3) * 10
    end
    if fw_t == fw_rise_len then
      -- explode: particles + score + sfx
      spawn_particles(fw_x, fw_y, 10, 10)
      spawn_particles(fw_x, fw_y, 8, 6)
      spawn_particles(fw_x, fw_y, 7, 4)
      score += fw_pts
      spawn_score_pop(fw_x, fw_y, fw_pts)
      sfx(4)
      fw_fired += 1
    end
    if fw_t >= fw_gap then
      if fw_fired >= fw_count then
        clear_phase = cp_done
        clear_t = 0
      else
        fw_t = 0
      end
    end
  elseif clear_phase == cp_done then
    if btnp(4) or btnp(5) then
      _init()
    end
  end
end
