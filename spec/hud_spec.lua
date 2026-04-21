describe('hud, scoring, and timer', function()
  before_each(function()
    load_game()
    _G.lives = nil
    _init()
  end)

  describe('timer', function()
    it('initializes at 400', function()
      assert.are.equal(400, timer)
    end)

    it('tick counter starts at 0', function()
      assert.are.equal(0, timer_tick)
    end)

    it('decrements by 1 after timer_rate frames', function()
      for i = 1, timer_rate do
        update_timer(player)
      end
      assert.are.equal(399, timer)
    end)

    it('does not decrement before timer_rate frames', function()
      for i = 1, timer_rate - 1 do
        update_timer(player)
      end
      assert.are.equal(400, timer)
    end)

    it('kills player when timer reaches 0', function()
      _G.timer = 1
      _G.timer_tick = timer_rate - 1
      update_timer(player)
      assert.are.equal(0, timer)
      assert.are.equal(st_dead, state)
    end)

    it('does not tick during dead state', function()
      _G.state = st_dead
      _G.death_t = 0
      local t = timer
      for i = 1, timer_rate * 2 do
        update_dead()
      end
      assert.are.equal(t, timer)
    end)

    it('converts remaining time to score on level clear', function()
      _G.timer = 50
      _G.state = st_clear
      _G.clear_phase = cp_tally
      _G.clear_t = 0
      local base_score = score
      local frames = math.ceil(50 / timer_drain_spd)
      for i = 1, frames do
        update_clear()
      end
      assert.are.equal(0, timer)
      assert.are.equal(base_score + 50 * timer_pts, score)
    end)
  end)

  describe('coin scoring', function()
    it('adds 200 to score when collecting a world coin', function()
      _pico8.set_tile(5, 5, spr_coin1)
      _pico8.set_flags(spr_coin1, 0x08)
      local base_score = score
      local p = player
      p.x = 5 * 8
      p.y = 5 * 8
      p.w = 6
      p.h = 8
      player_check_tiles(p)
      assert.are.equal(base_score + 200, score)
    end)

    it('increments coin counter on world coin', function()
      _pico8.set_tile(5, 5, spr_coin1)
      _pico8.set_flags(spr_coin1, 0x08)
      local base_coins = coins
      local p = player
      p.x = 5 * 8
      p.y = 5 * 8
      player_check_tiles(p)
      assert.are.equal(base_coins + 1, coins)
    end)

    it('adds 200 to score on ? block coin', function()
      _pico8.set_tile(3, 3, spr_qblock1)
      _pico8.set_flags(spr_qblock1, 0x20)
      local base_score = score
      bump_block(3, 3)
      assert.are.equal(base_score + 200, score)
    end)
  end)

  describe('item scoring', function()
    it('adds 1000 to score on mushroom pickup', function()
      spawn_item(5, 5, "mushroom")
      local it = items[1]
      for i = 1, 8 do
        update_items()
      end
      player.x = it.x
      player.y = it.y
      local base_score = score
      update_items()
      assert.are.equal(base_score + 1000, score)
    end)

    it('adds 1000 to score on star pickup', function()
      spawn_item(5, 5, "star")
      local it = items[1]
      for i = 1, 8 do
        update_items()
      end
      player.x = it.x
      player.y = it.y
      local base_score = score
      update_items()
      assert.are.equal(base_score + 1000, score)
    end)
  end)

  describe('lives', function()
    it('initializes at 3', function()
      assert.are.equal(3, lives)
    end)

    it('decrements on first frame of death', function()
      _G.state = st_dead
      _G.death_t = 0
      update_dead()
      assert.are.equal(2, lives)
    end)

    it('does not decrement on subsequent death frames', function()
      _G.state = st_dead
      _G.death_t = 1
      local l = lives
      update_dead()
      assert.are.equal(l, lives)
    end)

    it('resets to 3 after game over', function()
      _G.lives = 0
      _G.state = st_dead
      _G.death_t = 21
      _pico8.btns[4] = true
      update_dead()
      assert.are.equal(3, lives)
    end)
  end)

  describe('init state', function()
    it('score starts at 0', function()
      assert.are.equal(0, score)
    end)

    it('coins start at 0', function()
      assert.are.equal(0, coins)
    end)
  end)
end)
