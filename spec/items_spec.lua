describe('items', function()
  local sfx_calls

  before_each(function()
    load_game()
    _G.coins = 0
    _G.score = 0
    _G.lives = 3
    _G.bumped_blocks = {}
    _G.pop_coins = {}
    _G.score_pops = {}
    _G.hidden_blocks = {}
    _G.multi_coin_bricks = {}
    _G.items = {}
    _G.block_contents = {}
    -- wire flag masks matching generate_cart.py
    _pico8.set_flags(spr_qblock1, 0x21)   -- solid + question
    _pico8.set_flags(spr_brick, 0x11)     -- solid + breakable
    _pico8.set_flags(spr_hitblock, 0x01)  -- solid only
    _pico8.set_flags(spr_ground, 0x01)    -- solid only
    -- spy on sfx
    sfx_calls = {}
    _G.sfx = function(n) table.insert(sfx_calls, n) end
    _G.music = function(_) end
    -- place a minimal player for overlap tests (anchor off-screen)
    _G.player = make_player(-1000, -1000)
    _G.cam_x = -1100
  end)

  describe('block_contents registry', function()
    it('defaults to "coin" when unregistered', function()
      assert.are.equal('coin', contents_at(3, 5))
    end)

    it('returns the registered kind', function()
      register_contents(3, 5, 'mushroom')
      assert.are.equal('mushroom', contents_at(3, 5))
    end)

    it('supports multiple registrations', function()
      register_contents(3, 5, 'mushroom')
      register_contents(7, 5, 'star')
      assert.are.equal('mushroom', contents_at(3, 5))
      assert.are.equal('star', contents_at(7, 5))
      assert.are.equal('coin', contents_at(9, 9))
    end)
  end)

  describe('bump_block on ? block with mushroom content', function()
    it('spawns a mushroom item instead of a pop coin', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      assert.are.equal(1, #items)
      assert.are.equal('mushroom', items[1].kind)
      assert.are.equal(0, #pop_coins)
      assert.are.equal(0, coins)
    end)

    it('converts ? block to hit block after bump animation', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      for _ = 1, 8 do update_bumps() end
      assert.are.equal(spr_hitblock, mget(3, 5))
    end)

    it('plays power-up appear sfx when item emerges', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      -- sfx(4) is the power-up appear channel
      local found = false
      for _, n in ipairs(sfx_calls) do
        if n == 4 then found = true end
      end
      assert.is_true(found)
    end)

    it('does not double-spawn on re-bump', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      bump_block(3, 5)
      assert.are.equal(1, #items)
    end)
  end)

  describe('bump_block on ? block with default (coin) content', function()
    it('still dispenses a pop coin (no regression)', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      assert.are.equal(1, #pop_coins)
      assert.are.equal(1, coins)
      assert.are.equal(0, #items)
    end)
  end)

  describe('mushroom rise phase', function()
    it('starts at the block position in rise phase', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      local m = items[1]
      assert.are.equal(24, m.x)             -- 3 * 8
      assert.are.equal(40, m.y)             -- 5 * 8 (atop the block)
      assert.are.equal('rise', m.phase)
    end)

    it('rises one pixel per frame for 8 frames', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      local m = items[1]
      local start_y = m.y
      for _ = 1, 8 do update_items() end
      assert.are.equal(start_y - 8, m.y)
    end)

    it('transitions to walk phase after rising', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      for _ = 1, 8 do update_items() end
      assert.are.equal('walk', items[1].phase)
    end)

    it('does not move horizontally while rising', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      local start_x = items[1].x
      for _ = 1, 4 do update_items() end
      assert.are.equal(start_x, items[1].x)
    end)
  end)

  describe('mushroom walk phase', function()
    -- Fast-forwards past the 8-frame rise and clears the spawning ? block
    -- so the mushroom can fall/walk freely (the block stays solid after
    -- bump_block until update_bumps runs; tests don't run bump animation).
    local function make_walking_mushroom(mx, my)
      _pico8.set_tile(mx, my, spr_qblock1)
      register_contents(mx, my, 'mushroom')
      bump_block(mx, my)
      for _ = 1, 8 do update_items() end
      _pico8.set_tile(mx, my, 0)
      return items[1]
    end

    it('moves right under gravity', function()
      _pico8.set_tile(3, 6, spr_ground)
      _pico8.set_tile(4, 6, spr_ground)
      _pico8.set_tile(5, 6, spr_ground)
      local m = make_walking_mushroom(3, 5)
      local start_x = m.x
      update_items()
      assert.is_true(m.x > start_x)
    end)

    it('reverses direction on hitting a solid wall on the right', function()
      _pico8.set_tile(3, 6, spr_ground)  -- floor
      _pico8.set_tile(4, 6, spr_ground)
      _pico8.set_tile(4, 5, spr_ground)  -- wall at mushroom height
      local m = make_walking_mushroom(3, 5)
      assert.is_true(m.dx > 0)
      for _ = 1, 30 do update_items() end
      assert.is_true(m.dx < 0)
    end)

    it('falls into pits and is removed', function()
      make_walking_mushroom(3, 5)
      for _ = 1, 300 do update_items() end
      assert.are.equal(0, #items)
    end)

    it('lands on solid ground and stops falling', function()
      _pico8.set_tile(3, 7, spr_ground)
      _pico8.set_tile(4, 7, spr_ground)
      _pico8.set_tile(5, 7, spr_ground)
      local m = make_walking_mushroom(3, 5)
      for _ = 1, 20 do update_items() end
      -- mushroom (h=8) sits atop row 7 => y = 7*8 - 8 = 48
      assert.are.equal(48, m.y)
      assert.are.equal(0, m.dy)
    end)
  end)

  describe('player collects mushroom on overlap', function()
    it('removes the mushroom and plays collection sfx', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      for _ = 1, 8 do update_items() end
      _pico8.set_tile(3, 5, 0)
      local m = items[1]
      player.x = m.x
      player.y = m.y
      update_items()
      assert.are.equal(0, #items)
      assert.is_true(#sfx_calls >= 1)
    end)

    it('triggers grow_player: power becomes 1 and h becomes 16', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      for _ = 1, 8 do update_items() end
      _pico8.set_tile(3, 5, 0)
      local m = items[1]
      player.x = m.x
      player.y = m.y
      update_items()
      assert.are.equal(1, player.power)
      assert.are.equal(16, player.h)
    end)

    it('does not collect during rise phase (still inside block)', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'mushroom')
      bump_block(3, 5)
      local m = items[1]
      player.x = m.x
      player.y = m.y
      assert.are.equal('rise', m.phase)
      update_items()
      assert.are.equal(1, #items)
    end)
  end)

  describe('star walk phase', function()
    _pico8 = _pico8  -- luacheck: ignore
    local function make_walking_star(mx, my)
      _pico8.set_tile(mx, my, spr_qblock1)
      register_contents(mx, my, 'star')
      bump_block(mx, my)
      for _ = 1, 8 do update_items() end
      _pico8.set_tile(mx, my, 0)
      return items[1]
    end

    it('moves right at star_spd', function()
      _pico8.set_tile(3, 6, spr_ground)
      _pico8.set_tile(4, 6, spr_ground)
      _pico8.set_tile(5, 6, spr_ground)
      local s = make_walking_star(3, 5)
      assert.are.equal(star_spd, s.dx)
    end)

    it('sets dy to star_bounce on emerge (first bounce)', function()
      _pico8.set_tile(3, 6, spr_ground)
      local s = make_walking_star(3, 5)
      assert.are.equal(star_bounce, s.dy)
    end)

    it('bounces on ground landing (dy resets to star_bounce)', function()
      _pico8.set_tile(3, 7, spr_ground)
      _pico8.set_tile(4, 7, spr_ground)
      _pico8.set_tile(5, 7, spr_ground)
      _pico8.set_tile(6, 7, spr_ground)
      _pico8.set_tile(7, 7, spr_ground)
      local s = make_walking_star(3, 5)
      -- simulate until star lands at least once
      local bounced = false
      for _ = 1, 120 do
        local prev_dy = s.dy
        update_items()
        if prev_dy > 0 and s.dy == star_bounce then
          bounced = true
          break
        end
      end
      assert.is_true(bounced)
    end)
  end)

  describe('player collects star on overlap', function()
    it('triggers star_player: invince_t > 0 and power unchanged', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'star')
      bump_block(3, 5)
      for _ = 1, 8 do update_items() end
      _pico8.set_tile(3, 5, 0)
      local s = items[1]
      player.x = s.x
      player.y = s.y
      update_items()
      assert.are.equal(0, #items)
      assert.are.equal(invince_len, player.invince_t)
      assert.are.equal(0, player.power)
    end)

    it('does not trigger grow_player', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      register_contents(3, 5, 'star')
      bump_block(3, 5)
      for _ = 1, 8 do update_items() end
      _pico8.set_tile(3, 5, 0)
      local s = items[1]
      player.x = s.x
      player.y = s.y
      update_items()
      assert.are.equal(0, player.power)
      assert.are.equal(8, player.h)
    end)
  end)
end)
