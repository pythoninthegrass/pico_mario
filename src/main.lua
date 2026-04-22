----------------------------------------
-- game state machine
----------------------------------------
function _init()
  lives = 3
  score = 0
  coins = 0
  stomp_chain = 0
  state = st_title
  title_t = 0
  lives_t = 0
  gameover_t = 0
  start_level()
end

-- reset level state for a fresh play.
-- preserves score/coins/lives so the
-- lives screen can display them before
-- play resumes.
function start_level()
  score_pops = {}
  death_t = 0
  clear_t = 0
  clear_phase = cp_slide
  enter_t = 0
  grab_pts = 0
  grab_y = 0
  flag_y = pole_top_y + 8
  fw_count = 0
  fw_fired = 0
  fw_t = 0
  fw_x = 0
  fw_y = 0
  peace_y = peace_start_y
  timer = timer_start
  timer_tick = 0
  timer_warned = false

  -- reload map from rom so coins
  -- and spawn marker are restored
  reload(0x2000, 0x2000, 0x1000)

  -- find spawn marker (sprite 6)
  local sx, sy = 16, 104
  for my = 0, map_h - 1 do
    for mx = 0, map_w - 1 do
      if mget(mx, my) == 6 then
        sx = mx * 8
        sy = my * 8
        mset(mx, my, 0)
      end
    end
  end

  player = make_player(sx, sy)
  cam_x = player.x - 60
  cam_y = 0
  particles = {}
  bumped_blocks = {}
  pop_coins = {}
  hidden_blocks = {}
  multi_coin_bricks = {}
  items = {}
  block_contents = {}
  register_specials()
  init_enemies()
end

-- SMB 1-1 hidden / multi-coin tiles.
-- Positions chosen from the current
-- map layout; retune here only.
function register_specials()
  -- hidden 1-up: empty air above the
  -- row 10 brick group (reachable by
  -- jumping from the bricks at 55-59)
  register_hidden(60, 7, "1up")
  -- multi-coin brick: first brick of
  -- the row 10 brick group at col 55
  register_multi_coin(55, 10)
  -- ? block contents (1-1): first ?
  -- in the brick row gives a mushroom,
  -- the later ? gives a star.
  register_contents(17, 10, "mushroom")
  register_contents(19, 10, "star")
end

function _update60()
  if state == st_title then
    update_title()
  elseif state == st_lives then
    update_lives()
  elseif state == st_gameover then
    update_gameover()
  elseif state == st_play then
    update_play()
  elseif state == st_dead then
    update_dead()
  elseif state == st_clear then
    update_clear()
  end
  update_particles()
  update_bumps()
  update_pop_coins()
  update_score_pops()
  update_multi_coin_bricks()
  update_items()
end

function draw_hud()
  camera(0, 0)
  rectfill(0, 0, 127, 15, 0)
  -- row 1: labels
  print("mario", 2, 2, 7)
  spr(spr_coin1, 42, 1)
  print("x"..zpad(coins, 2), 50, 2, 7)
  print("world", 72, 2, 7)
  print("time", 104, 2, 7)
  -- row 2: values
  print(zpad(score, 6), 2, 9, 7)
  print("x"..lives, 30, 9, 7)
  print("1-1", 78, 9, 7)
  print(zpad(timer, 3), 108, 9, 7)
end

function draw_title()
  cls(12)
  camera(0, 0)
  draw_hud()
  -- ground strip
  for x = 0, 120, 8 do
    spr(spr_ground, x, 112)
    spr(spr_ground, x, 120)
  end
  -- small hill on the left
  spr(spr_hill_top, 16, 96)
  spr(spr_hill, 8, 104)
  spr(spr_hill, 16, 104)
  spr(spr_hill, 24, 104)
  -- bush on the right
  spr(spr_bush_l, 80, 104)
  spr(spr_bush_m, 88, 104)
  spr(spr_bush_r, 96, 104)
  -- title + prompt
  print("pico mario", 44, 44, 8)
  print("press \x97 to start", 28, 72, 7)
end

function draw_lives()
  cls(0)
  camera(0, 0)
  draw_hud()
  print("world 1-1", 46, 56, 7)
  spr(spr_idle, 54, 68)
  print("x "..lives, 66, 72, 7)
end

function draw_gameover()
  cls(0)
  camera(0, 0)
  draw_hud()
  print("game over", 46, 60, 7)
end

function _draw()
  if state == st_title then
    draw_title()
    return
  end
  if state == st_lives then
    draw_lives()
    return
  end
  if state == st_gameover then
    draw_gameover()
    return
  end

  cls(12)

  camera(cam_x, cam_y)

  -- draw map
  map(0, 0, 0, 0, map_w, map_h)

  draw_bumps()

  -- draw animated flag + grab score during clear
  if state == st_clear then
    spr(spr_flag, pole_x, flag_y)
    if clear_phase <= cp_walk then
      print(grab_pts, pole_x + 10, grab_y, 7)
    end
    -- peace flag rising on the castle turret
    if clear_phase >= cp_enter then
      spr(spr_peace_flag, peace_x, peace_y)
    end
    -- firework rocket trail rising
    if clear_phase == cp_fireworks
        and fw_t < fw_rise_len then
      local start_y = 112
      local t = fw_t / fw_rise_len
      local ry = start_y + (fw_y - start_y) * t
      pset(fw_x, ry, 10)
      pset(fw_x, ry + 1, 9)
    end
  end

  -- draw player
  if state == st_play
      or (state == st_dead and death_t < 10)
      or (state == st_clear and clear_phase < cp_enter)
      or (state == st_clear and clear_phase == cp_enter
          and enter_t < 8) then
    -- flash every 4 frames while invuln
    local blink = player.invuln_t > 0
        and (player.invuln_t % 8) < 4
    if not blink then
      local flip_x = (player.facing == -1)
      local sn = get_player_spr(player)
      local th = 1
      if player.power >= 1 then th = 2 end
      -- star invincibility: rotate key
      -- player palette entries every frame
      -- so mario cycles through 4 hues
      if player.invince_t > 0 then
        local rot = player.invince_t % 4
        local cycle = { 8, 9, 10, 14 }
        pal(8, cycle[(rot) % 4 + 1])
        pal(4, cycle[(rot + 1) % 4 + 1])
        pal(12, cycle[(rot + 2) % 4 + 1])
      end
      spr(sn, player.x, player.y, 1, th, flip_x)
      if player.invince_t > 0 then pal() end
    end
  end

  draw_enemies()
  draw_items()
  draw_pop_coins()
  draw_score_pops()
  draw_particles()

  -- hud (screen-fixed)
  draw_hud()

  if state == st_clear and clear_phase == cp_done then
    rectfill(20, 44, 108, 72, 1)
    print("level clear!", 36, 48, 10)
    print("press \x97/\x8e to restart", 22, 62, 7)
  end
end

