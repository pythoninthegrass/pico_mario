describe('star invincibility (TASK-014)', function()
  local sfx_calls

  local function ground_row(row)
    _pico8.set_flags(16, 0x01)
    for x = 0, 30 do
      _pico8.set_tile(x, row, 16)
    end
  end

  before_each(function()
    load_game()
    ground_row(13)
    sfx_calls = {}
    _G.sfx = function(n) table.insert(sfx_calls, n) end
    _G.music = function(_) end
    _G.particles = {}
    _G.score = 0
    _G.stomp_chain = 0
    _G.score_pops = {}
    _G.coins = 0
    _G.lives = 3
    init_enemies()
    _G.player = make_player(40, 96)
  end)

  describe('flip_enemy', function()
    it('sets state to flipped with upward velocity', function()
      local e = make_enemy(40, 96, 'goomba')
      flip_enemy(e)
      assert.are.equal('flipped', e.state)
      assert.are.equal(flip_rise, e.dy)
      assert.are.equal(0, e.dx)
    end)
  end)

  describe('flipped enemy physics', function()
    it('ignores solid collision and falls off the map', function()
      local e = make_enemy(40, 96, 'goomba')
      table.insert(enemies, e)
      flip_enemy(e)
      for _ = 1, 300 do update_enemies() end
      assert.are.equal(0, #enemies)
    end)

    it('rises then falls (gravity still applies)', function()
      local e = make_enemy(40, 96, 'goomba')
      table.insert(enemies, e)
      flip_enemy(e)
      local start_y = e.y
      update_enemies()
      -- first update: e.dy = flip_rise + grav, still upward
      assert.is_true(e.y < start_y)
    end)
  end)

  describe('check_enemy_hits while invincible', function()
    it('flips the enemy on contact and awards score', function()
      star_player(player)
      local e = make_enemy(player.x + 2, player.y + 2, 'goomba')
      table.insert(enemies, e)
      local before = score
      check_enemy_hits(player)
      assert.are.equal('flipped', e.state)
      assert.is_true(score > before)
    end)

    it('does not damage the player', function()
      star_player(player)
      local power_before = player.power
      local invince_before = player.invince_t
      local e = make_enemy(player.x + 2, player.y + 2, 'goomba')
      table.insert(enemies, e)
      check_enemy_hits(player)
      assert.are.equal(power_before, player.power)
      assert.are.equal(invince_before, player.invince_t)
    end)

    it('does not bounce the player (no stomp)', function()
      star_player(player)
      local e = make_enemy(player.x + 2, player.y + 2, 'goomba')
      table.insert(enemies, e)
      local dy_before = player.dy
      check_enemy_hits(player)
      assert.are.equal(dy_before, player.dy)
    end)

    it('flips a koopa too (not just goombas)', function()
      star_player(player)
      local e = make_enemy(player.x + 2, player.y + 2, 'koopa')
      table.insert(enemies, e)
      check_enemy_hits(player)
      assert.are.equal('flipped', e.state)
    end)
  end)

  describe('invuln_t takes precedence over star kills', function()
    it('invuln_t short-circuits check_enemy_hits', function()
      -- if player is in post-shrink i-frames AND invincible,
      -- the invuln early-return fires first (safe: no enemy touched)
      star_player(player)
      player.invuln_t = 30
      local e = make_enemy(player.x + 2, player.y + 2, 'goomba')
      table.insert(enemies, e)
      check_enemy_hits(player)
      assert.are.equal('alive', e.state)
    end)
  end)
end)
