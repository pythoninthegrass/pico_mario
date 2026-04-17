----------------------------------------
-- game state machine
----------------------------------------
function _init()
  state = st_play
  coins = 0
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
end

function _draw()
  cls(12)

  camera(cam_x, cam_y)

  -- draw map
  map(0, 0, 0, 0, map_w, map_h)

  -- draw player
  if state == st_play
      or (state == st_dead and death_t < 10) then
    local flip_x = (player.facing == -1)
    local sn = get_player_spr(player)
    spr(sn, player.x, player.y, 1, 1, flip_x)
  end

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

