----------------------------------------
-- state: playing
----------------------------------------
function update_play()
  local p = player

  -- run state (x button)
  p.running = btn(5)
  local spd = move_spd
  if p.running then spd = run_spd end

  -- horizontal input
  p.dx = 0
  if btn(0) then
    p.dx = -spd
    p.facing = -1
  end
  if btn(1) then
    p.dx = spd
    p.facing = 1
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
  if can_jump and btnp(4) then
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

  -- tile interactions
  local result = player_check_tiles(p)
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
end

function get_player_spr(p)
  if not p.grounded then
    return 3
  end
  if p.dx != 0 then
    return 1 + p.frame % 2
  end
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

