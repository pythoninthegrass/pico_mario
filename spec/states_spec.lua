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
