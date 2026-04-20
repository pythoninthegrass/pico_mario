describe('block bumps', function()
  before_each(function()
    load_game()
    _G.coins = 0
    _G.bumped_blocks = {}
    _G.pop_coins = {}
    -- wire flag masks matching generate_cart.py
    _pico8.set_flags(spr_qblock1, 0x21)   -- solid + question
    _pico8.set_flags(spr_brick, 0x11)     -- solid + breakable
    _pico8.set_flags(spr_hitblock, 0x01)  -- solid only
    _pico8.set_flags(spr_ground, 0x01)    -- solid only
  end)

  describe('bump_block on ? block', function()
    it('converts ? block to hit block after bump completes', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      -- tile stays as ? block during animation
      assert.are.equal(spr_qblock1, mget(3, 5))
      -- advance bump to completion
      for _ = 1, 8 do update_bumps() end
      assert.are.equal(spr_hitblock, mget(3, 5))
    end)

    it('spawns a pop coin on ? block bump', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      assert.are.equal(1, #pop_coins)
      assert.are.equal(24, pop_coins[1].x)   -- 3 * 8
      assert.are.equal(40, pop_coins[1].y)   -- 5 * 8
    end)

    it('increments coin count on ? block bump', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      assert.are.equal(1, coins)
    end)

    it('does not double-bump an already-bumped ? block', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      bump_block(3, 5)
      assert.are.equal(1, #bumped_blocks)
      assert.are.equal(1, #pop_coins)
      assert.are.equal(1, coins)
    end)
  end)

  describe('bump_block on brick', function()
    it('keeps brick tile after bump completes (small mario)', function()
      _pico8.set_tile(3, 5, spr_brick)
      bump_block(3, 5)
      for _ = 1, 8 do update_bumps() end
      assert.are.equal(spr_brick, mget(3, 5))
    end)

    it('does not release a coin from bricks', function()
      _pico8.set_tile(3, 5, spr_brick)
      bump_block(3, 5)
      assert.are.equal(0, #pop_coins)
      assert.are.equal(0, coins)
    end)

    it('spawns bump animation', function()
      _pico8.set_tile(3, 5, spr_brick)
      bump_block(3, 5)
      assert.are.equal(1, #bumped_blocks)
    end)
  end)

  describe('bump_block on non-interactive tiles', function()
    it('is a no-op on empty tile', function()
      bump_block(3, 5)
      assert.are.equal(0, #bumped_blocks)
    end)

    it('is a no-op on plain ground', function()
      _pico8.set_tile(3, 5, spr_ground)
      bump_block(3, 5)
      assert.are.equal(0, #bumped_blocks)
    end)

    it('is a no-op on already-hit block', function()
      _pico8.set_tile(3, 5, spr_hitblock)
      bump_block(3, 5)
      assert.are.equal(0, #bumped_blocks)
      assert.are.equal(0, coins)
    end)
  end)

  describe('pop coin animation', function()
    it('expires after 24 frames', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      for _ = 1, 25 do update_pop_coins() end
      assert.are.equal(0, #pop_coins)
    end)

    it('rises then falls under gravity', function()
      _pico8.set_tile(3, 5, spr_qblock1)
      bump_block(3, 5)
      local start_y = pop_coins[1].y
      update_pop_coins()
      assert.is_true(pop_coins[1].y < start_y)
    end)
  end)
end)
