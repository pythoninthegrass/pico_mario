----------------------------------------
-- game state machine
----------------------------------------
function _init()
  state = st_play
  coins = 0
  score = 0
  stomp_chain = 0
  score_pops = {}
  lives = lives or 3
  death_t = 0
  clear_t = 0
  clear_phase = cp_slide
  enter_t = 0
  grab_pts = 0
  grab_y = 0
  flag_y = pole_top_y + 8
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
  if state == st_play then
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

function _draw()
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

  if state == st_dead and death_t > 20 then
    if lives <= 0 then
      rectfill(20, 50, 108, 72, 1)
      print("game over", 42, 54, 8)
      print("press \x97/\x8e", 42, 64, 7)
    else
      rectfill(20, 54, 108, 68, 1)
      print("press \x97/\x8e to retry", 24, 58, 7)
    end
  end

  if state == st_clear and clear_phase == cp_done then
    rectfill(20, 44, 108, 72, 1)
    print("level clear!", 36, 48, 10)
    print("press \x97/\x8e to restart", 22, 62, 7)
  end
end

