describe('player power state', function()
  local sfx_calls

  before_each(function()
    load_game()
    _G.coins = 0
    _G.lives = 3
    _G.particles = {}
    sfx_calls = {}
    _G.sfx = function(n) table.insert(sfx_calls, n) end
    -- baseline player at arbitrary position
    _G.player = make_player(40, 40)
  end)

  describe('make_player defaults', function()
    it('starts with small state', function()
      assert.are.equal(0, player.power)
      assert.are.equal(8, player.h)
      assert.are.equal(6, player.w)
      assert.are.equal(0, player.invuln_t)
      assert.are.equal(0, player.transform_t)
    end)
  end)

  describe('grow_player', function()
    it('transitions small mario to big', function()
      grow_player(player)
      assert.are.equal(1, player.power)
      assert.are.equal(16, player.h)
    end)

    it('shifts y up by 8 so feet stay grounded', function()
      local feet_y = player.y + player.h
      grow_player(player)
      assert.are.equal(feet_y, player.y + player.h)
    end)

    it('starts the transform animation', function()
      grow_player(player)
      assert.are.equal(transform_len, player.transform_t)
    end)

    it('plays the power-up sfx', function()
      grow_player(player)
      local found = false
      for _, n in ipairs(sfx_calls) do if n == 4 then found = true end end
      assert.is_true(found)
    end)

    it('is a no-op when already big', function()
      grow_player(player)
      local y0 = player.y
      sfx_calls = {}
      grow_player(player)
      assert.are.equal(1, player.power)
      assert.are.equal(y0, player.y)
      assert.are.equal(0, #sfx_calls)
    end)
  end)

  describe('shrink_player', function()
    before_each(function()
      grow_player(player)
      sfx_calls = {}
    end)

    it('transitions big mario back to small', function()
      shrink_player(player)
      assert.are.equal(0, player.power)
      assert.are.equal(8, player.h)
    end)

    it('shifts y down by 8 so feet stay grounded', function()
      local feet_y = player.y + player.h
      shrink_player(player)
      assert.are.equal(feet_y, player.y + player.h)
    end)

    it('starts invulnerability + transform timers', function()
      shrink_player(player)
      assert.are.equal(invuln_len, player.invuln_t)
      assert.are.equal(transform_len, player.transform_t)
    end)

    it('plays the shrink sfx', function()
      shrink_player(player)
      assert.is_true(#sfx_calls >= 1)
    end)

    it('is a no-op when already small', function()
      shrink_player(player)
      sfx_calls = {}
      local y0 = player.y
      shrink_player(player)
      assert.are.equal(0, player.power)
      assert.are.equal(y0, player.y)
      assert.are.equal(0, #sfx_calls)
    end)
  end)

  describe('damage_player', function()
    it('returns "dead" when small mario takes a hit', function()
      assert.are.equal('dead', damage_player(player))
    end)

    it('shrinks big mario and returns "ok"', function()
      grow_player(player)
      local result = damage_player(player)
      assert.are.equal('ok', result)
      assert.are.equal(0, player.power)
      assert.is_true(player.invuln_t > 0)
    end)

    it('is a no-op while invulnerable', function()
      grow_player(player)
      damage_player(player)            -- shrink + set invuln
      local inv0 = player.invuln_t
      local result = damage_player(player)
      assert.are.equal('ok', result)
      assert.are.equal(0, player.power)  -- still small, not dead
      assert.are.equal(inv0, player.invuln_t)
    end)
  end)

  describe('get_player_spr', function()
    it('returns small sprite IDs when power == 0', function()
      player.grounded = true
      player.dx = 0
      assert.are.equal(spr_idle, get_player_spr(player))
    end)

    it('returns big sprite IDs when power >= 1', function()
      grow_player(player)
      player.grounded = true
      player.dx = 0
      assert.are.equal(spr_big_idle, get_player_spr(player))
    end)

    it('returns big run frames when walking big', function()
      grow_player(player)
      player.grounded = true
      player.dx = 1
      player.frame = 0
      local s = get_player_spr(player)
      assert.is_true(s == spr_big_run1 or s == spr_big_run2)
    end)

    it('returns big jump when airborne big', function()
      grow_player(player)
      player.grounded = false
      assert.are.equal(spr_big_jump, get_player_spr(player))
    end)
  end)
end)
