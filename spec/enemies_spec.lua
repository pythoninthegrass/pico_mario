describe('enemies', function()
  before_each(function()
    load_game()
  end)

  describe('enemy_spawns table', function()
    it('contains 16 goomba spawns', function()
      assert.are.equal(16, #enemy_spawns)
      for _, s in ipairs(enemy_spawns) do
        assert.are.equal('goomba', s.type)
      end
    end)

    it('places all spawns on row 13 (above ground)', function()
      for _, s in ipairs(enemy_spawns) do
        assert.are.equal(13 * 8, s.y)
      end
    end)

    it('is sorted by x ascending', function()
      for i = 2, #enemy_spawns do
        assert.is_true(enemy_spawns[i].x >= enemy_spawns[i - 1].x)
      end
    end)
  end)

  describe('init_enemies', function()
    it('clears active enemies and resets cursor', function()
      add(enemies, { x = 0, y = 0 })
      _G.next_spawn = 5
      init_enemies()
      assert.are.equal(0, #enemies)
      assert.are.equal(1, next_spawn)
    end)
  end)

  describe('make_enemy', function()
    it('creates a goomba with leftward velocity', function()
      local e = make_enemy(40, 80, 'goomba')
      assert.are.equal(40, e.x)
      assert.are.equal(80, e.y)
      assert.are.equal(-enemy_spd, e.dx)
      assert.are.equal(0, e.dy)
      assert.are.equal(6, e.w)
      assert.are.equal(8, e.h)
      assert.are.equal('goomba', e.etype)
      assert.are.equal(spr_goomba1, e.spr1)
      assert.are.equal(spr_goomba2, e.spr2)
    end)
  end)

  describe('spawn_enemies', function()
    it('spawns nothing when no spawns are within camera reach', function()
      init_enemies()
      _G.cam_x = -300
      spawn_enemies()
      assert.are.equal(0, #enemies)
    end)

    it('spawns the first enemy once camera approaches', function()
      init_enemies()
      _G.cam_x = 0
      spawn_enemies()
      -- enemy_spawns[1].x = 16*8 = 128, threshold 0+144 = 144, so spawns
      assert.are.equal(1, #enemies)
      assert.are.equal(2, next_spawn)
    end)

    it('spawns enemies whose x is below cam_x + 144', function()
      init_enemies()
      _G.cam_x = 240
      spawn_enemies()
      local expected = 0
      for _, s in ipairs(enemy_spawns) do
        if s.x < 240 + 144 then
          expected = expected + 1
        end
      end
      assert.are.equal(math.min(expected, max_enemies), #enemies)
    end)

    it('caps active enemies at max_enemies', function()
      init_enemies()
      _G.cam_x = 10000
      spawn_enemies()
      assert.are.equal(max_enemies, #enemies)
    end)

    it('does not advance cursor when capped', function()
      init_enemies()
      _G.cam_x = 10000
      spawn_enemies()
      assert.are.equal(max_enemies + 1, next_spawn)
      -- now remove one and call again; cursor should advance
      del(enemies, enemies[1])
      spawn_enemies()
      assert.are.equal(max_enemies, #enemies)
      assert.are.equal(max_enemies + 2, next_spawn)
    end)
  end)

  describe('update_enemies', function()
    local function ground_row(row)
      _pico8.set_flags(16, 0x01)
      for x = 0, 20 do
        _pico8.set_tile(x, row, 16)
      end
    end

    it('moves enemies left at enemy_spd per frame', function()
      init_enemies()
      ground_row(13)
      local e = make_enemy(50, 96, 'goomba')
      add(enemies, e)
      update_enemies()
      assert.are.equal(50 - enemy_spd, e.x)
    end)

    it('reverses direction on wall collision', function()
      init_enemies()
      _pico8.set_flags(16, 0x01)
      _pico8.set_tile(7, 13, 16) -- ground under enemy
      _pico8.set_tile(6, 12, 16) -- wall directly to the left
      local e = make_enemy(56, 96, 'goomba')
      add(enemies, e)
      update_enemies()
      assert.is_true(e.dx > 0)
    end)

    it('falls under gravity', function()
      init_enemies()
      local e = make_enemy(50, 60, 'goomba')
      add(enemies, e)
      update_enemies()
      assert.is_true(e.y > 60)
    end)

    it('removes enemies that fall off the bottom of the map', function()
      init_enemies()
      local e = make_enemy(50, map_h * 8 + 20, 'goomba')
      add(enemies, e)
      update_enemies()
      assert.are.equal(0, #enemies)
    end)

    it('animates between walk frames over time', function()
      init_enemies()
      ground_row(13)
      local e = make_enemy(50, 96, 'goomba')
      add(enemies, e)
      local f0 = e.frame
      for _ = 1, 12 do update_enemies() end
      assert.are_not.equal(f0, e.frame)
    end)

    it('lands on solid tiles below', function()
      init_enemies()
      ground_row(13)
      local e = make_enemy(50, 60, 'goomba')
      add(enemies, e)
      for _ = 1, 60 do update_enemies() end
      -- enemy bottom (y+h) should be at top of ground row (104)
      assert.are.equal(104 - e.h, e.y)
      assert.are.equal(0, e.dy)
    end)
  end)
end)
