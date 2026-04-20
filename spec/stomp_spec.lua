describe('enemy stomp + collision (TASK-008)', function()
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
    _G.particles = {}
    _G.score = 0
    _G.stomp_chain = 0
    _G.score_pops = {}
    _G.coins = 0
    _G.lives = 3
    init_enemies()
    _G.player = make_player(40, 96)
  end)

  describe('make_enemy', function()
    it('initializes state to alive', function()
      local e = make_enemy(40, 96, 'goomba')
      assert.are.equal('alive', e.state)
      assert.are.equal(0, e.state_t)
    end)

    it('creates a koopa with koopa sprites', function()
      local e = make_enemy(40, 96, 'koopa')
      assert.are.equal('koopa', e.etype)
      assert.are.equal(spr_koopa1, e.spr1)
      assert.are.equal(spr_koopa2, e.spr2)
    end)
  end)

  describe('stomp_enemy', function()
    it('transitions goomba to squished', function()
      local e = make_enemy(40, 96, 'goomba')
      add(enemies, e)
      stomp_enemy(e)
      assert.are.equal('squished', e.state)
    end)

    it('transitions koopa to shell', function()
      local e = make_enemy(40, 96, 'koopa')
      add(enemies, e)
      stomp_enemy(e)
      assert.are.equal('shell', e.state)
    end)

    it('stops enemy horizontal movement', function()
      local e = make_enemy(40, 96, 'goomba')
      add(enemies, e)
      stomp_enemy(e)
      assert.are.equal(0, e.dx)
    end)
  end)

  describe('check_enemy_hits: stomp detection', function()
    it('stomp when falling onto enemy from above', function()
      player.x = 40
      player.y = 91
      player.dy = 2
      local e = make_enemy(40, 96, 'goomba')
      add(enemies, e)
      check_enemy_hits(player)
      assert.are.equal('squished', e.state)
    end)

    it('bounces player upward after stomp', function()
      player.x = 40
      player.y = 91
      player.dy = 2
      local e = make_enemy(40, 96, 'goomba')
      add(enemies, e)
      check_enemy_hits(player)
      assert.is_true(player.dy < 0)
    end)

    it('plays stomp sfx on successful stomp', function()
      player.x = 40
      player.y = 91
      player.dy = 2
      local e = make_enemy(40, 96, 'goomba')
      add(enemies, e)
      check_enemy_hits(player)
      local found = false
      for _, n in ipairs(sfx_calls) do if n == 6 then found = true end end
      assert.is_true(found)
    end)

    it('returns "hit" when touching enemy from side', function()
      player.x = 40
      player.y = 96
      player.dy = 0
      local e = make_enemy(44, 96, 'goomba')
      add(enemies, e)
      assert.are.equal('hit', check_enemy_hits(player))
    end)

    it('no collision when enemy is already squished', function()
      player.x = 40
      player.y = 96
      player.dy = 0
      local e = make_enemy(44, 96, 'goomba')
      e.state = 'squished'
      add(enemies, e)
      assert.are.equal('ok', check_enemy_hits(player))
    end)

    it('skips collision while invulnerable', function()
      player.invuln_t = 60
      player.x = 40
      player.y = 96
      player.dy = 0
      local e = make_enemy(44, 96, 'goomba')
      add(enemies, e)
      assert.are.equal('ok', check_enemy_hits(player))
    end)
  end)

  describe('score chain', function()
    local function stomp_once()
      player.x = 40
      player.y = 91
      player.dy = 2
      local e = make_enemy(40, 96, 'goomba')
      add(enemies, e)
      check_enemy_hits(player)
    end

    it('first stomp scores 100', function()
      stomp_once()
      assert.are.equal(100, score)
    end)

    it('second stomp without landing scores 200 more (300 total)', function()
      stomp_once()
      stomp_once()
      assert.are.equal(300, score)
    end)

    it('chain caps at 1000', function()
      for _ = 1, 8 do stomp_once() end
      -- 100 + 200 + 400 + 800 + 1000 + 1000 + 1000 + 1000
      assert.are.equal(100 + 200 + 400 + 800 + 1000 * 4, score)
    end)

    it('spawns a score popup for each stomp', function()
      stomp_once()
      assert.are.equal(1, #score_pops)
      assert.are.equal(100, score_pops[1].pts)
    end)
  end)

  describe('squished enemy lifecycle', function()
    it('removes squished enemy after timeout', function()
      local e = make_enemy(40, 96, 'goomba')
      e.state = 'squished'
      add(enemies, e)
      for _ = 1, 40 do update_enemies() end
      assert.are.equal(0, #enemies)
    end)

    it('does not move while squished', function()
      local e = make_enemy(40, 96, 'goomba')
      e.state = 'squished'
      e.dx = -enemy_spd
      add(enemies, e)
      update_enemies()
      assert.are.equal(40, e.x)
    end)

    it('shell enemy stays put (does not tick down)', function()
      local e = make_enemy(40, 96, 'koopa')
      add(enemies, e)
      stomp_enemy(e)
      for _ = 1, 120 do update_enemies() end
      assert.are.equal(1, #enemies)
      assert.are.equal('shell', e.state)
    end)
  end)
end)
