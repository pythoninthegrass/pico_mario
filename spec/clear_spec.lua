describe('flagpole level clear (TASK-017)', function()
  before_each(function()
    load_game()
    _G.lives = nil
    _init()
  end)

  describe('enter_clear', function()
    it('sets state to st_clear with cp_slide phase', function()
      local p = player
      p.y = pole_top_y
      enter_clear(p)
      assert.are.equal(st_clear, state)
      assert.are.equal(cp_slide, clear_phase)
    end)

    it('snaps mario to left of pole', function()
      local p = player
      p.x = 500
      p.y = pole_top_y
      enter_clear(p)
      assert.are.equal(pole_x - 5, p.x)
      assert.are.equal(-1, p.facing)
    end)

    it('awards 5000 points for top-tier grab', function()
      local p = player
      p.y = 48
      local base = score
      enter_clear(p)
      assert.are.equal(base + 5000, score)
      assert.are.equal(5000, grab_pts)
    end)

    it('awards 2000 points for upper-tier grab', function()
      local p = player
      p.y = 64
      local base = score
      enter_clear(p)
      assert.are.equal(base + 2000, score)
    end)

    it('awards 800 points for middle-tier grab', function()
      local p = player
      p.y = 80
      local base = score
      enter_clear(p)
      assert.are.equal(base + 800, score)
    end)

    it('awards 400 points for lower-tier grab', function()
      local p = player
      p.y = 92
      local base = score
      enter_clear(p)
      assert.are.equal(base + 400, score)
    end)

    it('awards 100 points for bottom-tier grab', function()
      local p = player
      p.y = 100
      local base = score
      enter_clear(p)
      assert.are.equal(base + 100, score)
    end)

    it('removes flag tile from map so it can animate', function()
      local p = player
      p.y = pole_top_y
      _pico8.set_tile(flag_map_x, flag_map_y, spr_flag)
      enter_clear(p)
      assert.are.equal(0, mget(flag_map_x, flag_map_y))
    end)
  end)

  describe('cp_slide phase', function()
    it('slides mario and flag down toward pole bottom', function()
      local p = player
      p.y = pole_top_y
      enter_clear(p)
      local start_py = p.y
      local start_fy = flag_y
      update_clear()
      assert.are.equal(start_py + slide_spd, p.y)
      assert.are.equal(start_fy + slide_spd, flag_y)
    end)

    it('transitions to cp_walk when both reach bottom', function()
      local p = player
      p.y = pole_bottom_y - 1
      enter_clear(p)
      _G.flag_y = pole_bottom_y - 1
      update_clear()
      assert.are.equal(cp_walk, clear_phase)
      assert.are.equal(pole_x + 8, p.x)
      assert.are.equal(1, p.facing)
    end)
  end)

  describe('cp_walk phase', function()
    it('advances mario rightward and animates legs', function()
      local p = player
      _G.state = st_clear
      _G.clear_phase = cp_walk
      p.x = pole_x + 8
      local start_x = p.x
      for i = 1, 10 do update_clear() end
      assert.is_true(p.x > start_x)
    end)

    it('transitions to cp_enter when reaching castle wall', function()
      local p = player
      _G.state = st_clear
      _G.clear_phase = cp_walk
      p.x = castle_wall_x - 2
      update_clear()
      update_clear()
      update_clear()
      assert.are.equal(cp_enter, clear_phase)
    end)
  end)

  describe('cp_enter phase', function()
    it('transitions to cp_tally after enter_hold frames', function()
      _G.state = st_clear
      _G.clear_phase = cp_enter
      _G.enter_t = 0
      for i = 1, enter_hold + 1 do update_clear() end
      assert.are.equal(cp_tally, clear_phase)
    end)
  end)

  describe('cp_tally phase', function()
    it('drains timer into score', function()
      _G.state = st_clear
      _G.clear_phase = cp_tally
      _G.clear_t = 0
      _G.timer = 20
      local base = score
      for i = 1, math.ceil(20 / timer_drain_spd) do
        update_clear()
      end
      assert.are.equal(0, timer)
      assert.are.equal(base + 20 * timer_pts, score)
    end)

    it('transitions to cp_done after tally_hold frames with empty timer', function()
      _G.state = st_clear
      _G.clear_phase = cp_tally
      _G.clear_t = 0
      _G.timer = 0
      for i = 1, tally_hold + 1 do update_clear() end
      assert.are.equal(cp_done, clear_phase)
    end)
  end)
end)
