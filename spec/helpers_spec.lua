describe('game helpers', function()
  before_each(function()
    load_game()
  end)

  describe('tile_at', function()
    it('returns 0 for empty map', function()
      assert.are.equal(0, tile_at(0, 0))
    end)

    it('returns sprite number at pixel coords', function()
      -- tile (2,1) = sprite 5; pixel (16..23, 8..15)
      _pico8.set_tile(2, 1, 5)
      assert.are.equal(5, tile_at(16, 8))
      assert.are.equal(5, tile_at(23, 15))
    end)
  end)

  describe('tile_flag_at', function()
    it('returns false when tile is empty', function()
      assert.is_falsy(tile_flag_at(0, 0, 0))
    end)

    it('returns true when flag is set on tile', function()
      _pico8.set_tile(1, 1, 3)
      _pico8.set_flags(3, 0x01) -- bit 0 = f_solid
      assert.is_truthy(tile_flag_at(8, 8, 0))
    end)

    it('returns false when flag is not set', function()
      _pico8.set_tile(1, 1, 3)
      _pico8.set_flags(3, 0x01) -- only bit 0
      assert.is_falsy(tile_flag_at(8, 8, 1)) -- bit 1 not set
    end)
  end)

  describe('is_solid / is_hazard / is_goal', function()
    before_each(function()
      -- place sprite 10 at tile (3,2)
      _pico8.set_tile(3, 2, 10)
    end)

    it('is_solid checks flag 0', function()
      _pico8.set_flags(10, 0x01) -- bit 0
      assert.is_truthy(is_solid(24, 16))
      assert.is_falsy(is_hazard(24, 16))
    end)

    it('is_hazard checks flag 1', function()
      _pico8.set_flags(10, 0x02) -- bit 1
      assert.is_truthy(is_hazard(24, 16))
      assert.is_falsy(is_solid(24, 16))
    end)

    it('is_goal checks flag 2', function()
      _pico8.set_flags(10, 0x04) -- bit 2
      assert.is_truthy(is_goal(24, 16))
    end)
  end)

  describe('collect_coin', function()
    it('removes coin tile and returns true', function()
      _pico8.set_tile(5, 3, 20)
      _pico8.set_flags(20, 0x08) -- bit 3 = f_coin
      assert.is_true(collect_coin(40, 24))
      -- tile should be cleared
      assert.are.equal(0, mget(5, 3))
    end)

    it('returns false when no coin present', function()
      assert.is_false(collect_coin(40, 24))
    end)
  end)

  describe('make_player', function()
    it('creates player at given position', function()
      local p = make_player(32, 64)
      assert.are.equal(32, p.x)
      assert.are.equal(64, p.y)
      assert.are.equal(0, p.dx)
      assert.are.equal(0, p.dy)
      assert.are.equal(6, p.w)
      assert.are.equal(8, p.h)
      assert.is_false(p.grounded)
    end)

    it('stores spawn position', function()
      local p = make_player(10, 20)
      assert.are.equal(10, p.spawn_x)
      assert.are.equal(20, p.spawn_y)
    end)
  end)

  describe('update_cam', function()
    it('clamps camera to map bounds', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(0, 0)
      update_cam(p)
      assert.is_true(cam_x >= 0)
      assert.is_true(cam_y >= 0)
    end)

    it('does not scroll left when player is left of camera', function()
      _G.cam_x = 200
      _G.cam_y = 0
      local p = make_player(50, 64)
      update_cam(p)
      assert.are.equal(200, cam_x)
    end)

    it('never decreases cam_x across updates', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(300, 64)
      update_cam(p)
      local cx = cam_x
      assert.is_true(cx > 0)
      p.x = 80
      update_cam(p)
      assert.are.equal(cx, cam_x)
    end)

    it('scrolls right when player advances past dead zone', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(300, 64)
      update_cam(p)
      assert.is_true(cam_x > 0)
    end)

    it('keeps cam_x at 0 while player is inside the left dead zone', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(30, 64)
      update_cam(p)
      assert.are.equal(0, cam_x)
    end)

    it('clamps cam_x to the right map edge', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(map_w * 8, 64)
      update_cam(p)
      assert.are.equal(map_w * 8 - 128, cam_x)
    end)

    it('keeps cam_y fixed at 0', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(100, 200)
      update_cam(p)
      assert.are.equal(0, cam_y)
    end)
  end)

  describe('player_move left-edge lock', function()
    it('prevents player from walking past cam_x', function()
      _G.cam_x = 100
      _G.cam_y = 0
      local p = make_player(110, 64)
      p.dx = -20
      player_move(p)
      assert.is_true(p.x >= cam_x)
    end)

    it('still clamps to map left when cam_x is 0', function()
      _G.cam_x = 0
      _G.cam_y = 0
      local p = make_player(2, 64)
      p.dx = -4
      player_move(p)
      assert.is_true(p.x >= 0)
    end)
  end)
end)
