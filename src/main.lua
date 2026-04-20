----------------------------------------
-- game state machine
----------------------------------------
function _init()
  state = st_play
  coins = 0
  lives = lives or 3
  death_t = 0
  clear_t = 0

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
  update_multi_coin_bricks()
  update_items()
end

function _draw()
  cls(12)

  camera(cam_x, cam_y)

  -- draw map
  map(0, 0, 0, 0, map_w, map_h)

  draw_bumps()

  -- draw player
  if state == st_play
      or (state == st_dead and death_t < 10) then
    -- flash every 4 frames while invuln
    local blink = player.invuln_t > 0
        and (player.invuln_t % 8) < 4
    if not blink then
      local flip_x = (player.facing == -1)
      local sn = get_player_spr(player)
      local th = 1
      if player.power >= 1 then th = 2 end
      spr(sn, player.x, player.y, 1, th, flip_x)
    end
  end

  draw_enemies()
  draw_items()
  draw_pop_coins()
  draw_particles()

  -- hud (screen-fixed)
  camera(0, 0)
  -- coin icon + count
  spr(spr_coin1, 2, 2)
  print(coins, 12, 4, 7)

  if state == st_dead and death_t > 20 then
    rectfill(20, 54, 108, 68, 1)
    print("press \x97/\x8e to retry", 24, 58, 7)
  end

  if state == st_clear then
    rectfill(20, 44, 108, 72, 1)
    print("level clear!", 36, 48, 10)
    if clear_t > 30 then
      print("press \x97/\x8e to restart", 22, 62, 7)
    end
  end
end

