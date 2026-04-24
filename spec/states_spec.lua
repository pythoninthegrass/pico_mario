describe('game flow: title / lives / game over (TASK-018)', function()
  before_each(function()
    load_game()
    _init()
  end)

  describe('boot', function()
    it('enters st_title on cart boot', function()
      assert.are.equal(st_title, state)
    end)

    it('starts with 3 lives', function()
      assert.are.equal(3, lives)
    end)

    it('starts with score 0 and coins 0', function()
      assert.are.equal(0, score)
      assert.are.equal(0, coins)
    end)

    it('loads the level so scenery renders behind title', function()
      assert.is_not_nil(player)
    end)
  end)

  describe('update_title', function()
    it('advances to st_lives on O press after debounce', function()
      _G.title_t = 31
      _pico8.btns[4] = true
      update_title()
      assert.are.equal(st_lives, state)
      assert.are.equal(0, lives_t)
    end)

    it('ignores O press during startup debounce', function()
      _pico8.btns[4] = true
      update_title()
      assert.are.equal(st_title, state)
    end)
  end)

  describe('update_lives', function()
    it('advances to st_play after lives_hold frames', function()
      _G.state = st_lives
      _G.lives_t = 0
      for i = 1, lives_hold do
        update_lives()
      end
      assert.are.equal(st_play, state)
    end)

    it('does not advance before lives_hold', function()
      _G.state = st_lives
      _G.lives_t = 0
      for i = 1, lives_hold - 1 do
        update_lives()
      end
      assert.are.equal(st_lives, state)
    end)
  end)

  describe('enter_death', function()
    it('pops player upward and freezes horizontal motion', function()
      local p = player
      p.dx = 1.5
      p.dy = 2
      p.grounded = true
      _G.state = st_play
      enter_death(p)
      assert.are.equal(st_dead, state)
      assert.are.equal(0, death_t)
      assert.are.equal(-4, p.dy)
      assert.are.equal(0, p.dx)
      assert.is_false(p.grounded)
    end)
  end)

  describe('death animation physics', function()
    before_each(function()
      _G.state = st_dead
      _G.death_t = 0
      _G.lives = 3
      player.dx = 0
      player.dy = -4
      player.grounded = false
    end)

    it('moves player up initially (pop)', function()
      local start_y = player.y
      update_dead()
      assert.is_true(player.y < start_y)
    end)

    it('falls past starting y after gravity dominates', function()
      local start_y = player.y
      for i = 1, 60 do
        update_dead()
      end
      assert.is_true(player.y > start_y)
    end)

    it('clamps downward velocity to max_fall', function()
      for i = 1, 60 do
        update_dead()
      end
      assert.is_true(player.dy <= max_fall + 0.0001)
    end)

    it('ignores solid tiles under the player', function()
      local tile_x = flr((player.x + 3) / 8)
      local tile_y = flr((player.y + player.h + 2) / 8)
      _pico8.set_flags(spr_ground, 1)
      _pico8.set_tile(tile_x, tile_y, spr_ground)
      local start_y = player.y
      for i = 1, 30 do
        update_dead()
      end
      assert.is_true(player.y > start_y + 4)
    end)
  end)

  describe('death flow', function()
    it('death with lives > 0 transitions to st_lives', function()
      _G.lives = 3
      _G.state = st_dead
      _G.death_t = 0
      for i = 1, death_to_screen do
        update_dead()
      end
      assert.are.equal(2, lives)
      assert.are.equal(st_lives, state)
    end)

    it('death that drops lives to 0 transitions to st_gameover', function()
      _G.lives = 1
      _G.state = st_dead
      _G.death_t = 0
      for i = 1, death_to_screen do
        update_dead()
      end
      assert.are.equal(0, lives)
      assert.are.equal(st_gameover, state)
    end)

    it('resets level on transition to lives screen', function()
      _G.lives = 3
      _G.state = st_dead
      _G.death_t = 0
      _G.timer = 123
      for i = 1, death_to_screen do
        update_dead()
      end
      assert.are.equal(timer_start, timer)
    end)
  end)

  describe('update_gameover', function()
    it('returns to st_title with lives=3 after gameover_hold', function()
      _G.state = st_gameover
      _G.gameover_t = 0
      _G.lives = 0
      for i = 1, gameover_hold do
        update_gameover()
      end
      assert.are.equal(st_title, state)
      assert.are.equal(3, lives)
    end)

    it('advances to st_title on O press after debounce', function()
      _G.state = st_gameover
      _G.gameover_t = 31
      _G.lives = 0
      _pico8.btns[4] = true
      update_gameover()
      assert.are.equal(st_title, state)
      assert.are.equal(3, lives)
    end)
  end)
end)
