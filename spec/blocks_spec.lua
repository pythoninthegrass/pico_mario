describe('block bumps', function()
  before_each(function()
    load_game()
    _G.coins = 0
    _G.lives = 3
    _G.bumped_blocks = {}
    _G.pop_coins = {}
    _G.hidden_blocks = {}
    _G.multi_coin_bricks = {}
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

  describe('hidden blocks', function()
    it('is invisible before being revealed', function()
      register_hidden(3, 5, 'coin')
      -- map tile stays 0 (empty/not solid) until hit
      assert.are.equal(0, mget(3, 5))
      assert.is_false(is_solid(24, 40))
    end)

    it('reveal converts to solid hit block and spawns bump', function()
      register_hidden(3, 5, 'coin')
      local revealed = reveal_hidden(3, 5)
      assert.is_true(revealed)
      assert.are.equal(spr_hitblock, mget(3, 5))
      assert.are.equal(1, #bumped_blocks)
    end)

    it('reveal removes entry from hidden_blocks table', function()
      register_hidden(3, 5, 'coin')
      reveal_hidden(3, 5)
      assert.are.equal(0, #hidden_blocks)
    end)

    it('reveal is a no-op on non-hidden tile', function()
      local revealed = reveal_hidden(3, 5)
      assert.is_false(revealed)
      assert.are.equal(0, #bumped_blocks)
    end)

    it('coin hidden block dispenses a pop coin and increments coins', function()
      register_hidden(3, 5, 'coin')
      reveal_hidden(3, 5)
      assert.are.equal(1, #pop_coins)
      assert.are.equal(1, coins)
    end)

    it('1up hidden block increments lives', function()
      register_hidden(3, 5, '1up')
      reveal_hidden(3, 5)
      assert.are.equal(4, lives)
    end)

    it('1up hidden block does not increment coins', function()
      register_hidden(3, 5, '1up')
      reveal_hidden(3, 5)
      assert.are.equal(0, coins)
    end)
  end)

  describe('multi-coin bricks', function()
    it('dispenses a coin on first bump', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      bump_block(3, 5)
      assert.are.equal(1, coins)
      assert.are.equal(1, #pop_coins)
    end)

    it('tile stays as brick while coins remain', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      bump_block(3, 5)
      for _ = 1, 8 do update_bumps() end
      assert.are.equal(spr_brick, mget(3, 5))
    end)

    it('dispenses up to 10 coins across successive bumps', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      for _ = 1, 10 do
        bump_block(3, 5)
        -- clear pending bump so next head-hit can spawn a new one
        for _ = 1, 8 do update_bumps() end
      end
      assert.are.equal(10, coins)
    end)

    it('converts to hit block after 10 coins dispensed', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      for _ = 1, 10 do
        bump_block(3, 5)
        for _ = 1, 8 do update_bumps() end
      end
      update_multi_coin_bricks()
      assert.are.equal(spr_hitblock, mget(3, 5))
    end)

    it('does not dispense more than 10 coins even if bumped again', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      for _ = 1, 12 do
        bump_block(3, 5)
        for _ = 1, 8 do update_bumps() end
      end
      assert.are.equal(10, coins)
    end)

    it('converts to hit block after timer expires', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      bump_block(3, 5)  -- starts the 240-frame timer
      for _ = 1, 8 do update_bumps() end
      for _ = 1, 240 do update_multi_coin_bricks() end
      assert.are.equal(spr_hitblock, mget(3, 5))
    end)

    it('does not tick the timer before the first bump', function()
      _pico8.set_tile(3, 5, spr_brick)
      register_multi_coin(3, 5)
      for _ = 1, 300 do update_multi_coin_bricks() end
      assert.are.equal(spr_brick, mget(3, 5))
      assert.are.equal(1, #multi_coin_bricks)
    end)
  end)
end)
