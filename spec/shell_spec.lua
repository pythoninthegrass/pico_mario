describe('koopa shell physics (TASK-009)', function()
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

  describe('enemy_spawns koopa entry', function()
    it('includes 17 spawns (16 goombas + 1 koopa)', function()
      assert.are.equal(17, #enemy_spawns)
      local goombas, koopas = 0, 0
      for _, s in ipairs(enemy_spawns) do
        if s.type == 'goomba' then
          goombas = goombas + 1
        elseif s.type == 'koopa' then
          koopas = koopas + 1
        end
      end
      assert.are.equal(16, goombas)
      assert.are.equal(1, koopas)
    end)

    it('places the koopa at tile x=43 (before pipe 4)', function()
      local found = nil
      for _, s in ipairs(enemy_spawns) do
        if s.type == 'koopa' then
          found = s
        end
      end
      assert.is_not_nil(found)
      assert.are.equal(43 * 8, found.x)
      assert.are.equal(13 * 8, found.y)
    end)
  end)

  describe('stationary shell (dx == 0)', function()
    it('is created with dx = 0 after stomp on alive koopa', function()
      local e = make_enemy(40, 96, 'koopa')
      add(enemies, e)
      stomp_enemy(e)
      assert.are.equal('shell', e.state)
      assert.are.equal(0, e.dx)
    end)

    it('does not return "hit" on side contact; kicks the shell', function()
      local e = make_enemy(50, 96, 'koopa')
      e.state = 'shell'
      e.dx = 0
      add(enemies, e)
      player.x = 46
      player.y = 96
      player.dy = 0
      player.facing = 1
      assert.are.equal('ok', check_enemy_hits(player))
      assert.is_true(e.dx ~= 0)
    end)

    it('kick from the left sends shell right', function()
      local e = make_enemy(50, 96, 'koopa')
      e.state = 'shell'
      e.dx = 0
      add(enemies, e)
      player.x = 46
      player.y = 96
      player.dy = 0
      check_enemy_hits(player)
      assert.is_true(e.dx > 0)
    end)

    it('kick from the right sends shell left', function()
      local e = make_enemy(40, 96, 'koopa')
      e.state = 'shell'
      e.dx = 0
      add(enemies, e)
      player.x = 44
      player.y = 96
      player.dy = 0
      check_enemy_hits(player)
      assert.is_true(e.dx < 0)
    end)

    it('shell kick has speed shell_spd', function()
      local e = make_enemy(50, 96, 'koopa')
      e.state = 'shell'
      e.dx = 0
      add(enemies, e)
      player.x = 46
      player.y = 96
      player.dy = 0
      check_enemy_hits(player)
      assert.are.equal(shell_spd, math.abs(e.dx))
    end)
  end)

  describe('moving shell', function()
    it('kills an alive enemy on contact', function()
      local shell = make_enemy(40, 96, 'koopa')
      shell.state = 'shell'
      shell.dx = shell_spd
      shell.kick_t = 0
      add(enemies, shell)
      local target = make_enemy(44, 96, 'goomba')
      add(enemies, target)
      update_enemies()
      assert.are.equal('squished', target.state)
    end)

    it('reverses direction on wall collision', function()
      _pico8.set_flags(16, 0x01)
      _pico8.set_tile(7, 13, 16)
      _pico8.set_tile(6, 12, 16)
      local shell = make_enemy(56, 96, 'koopa')
      shell.state = 'shell'
      shell.dx = -shell_spd
      shell.kick_t = 0
      add(enemies, shell)
      update_enemies()
      assert.is_true(shell.dx > 0)
    end)

    it('returns "hit" when player touches from the side', function()
      local e = make_enemy(44, 96, 'koopa')
      e.state = 'shell'
      e.dx = shell_spd
      e.kick_t = 0
      add(enemies, e)
      player.x = 40
      player.y = 96
      player.dy = 0
      assert.are.equal('hit', check_enemy_hits(player))
    end)

    it('stomping a moving shell stops it', function()
      local e = make_enemy(40, 96, 'koopa')
      e.state = 'shell'
      e.dx = shell_spd
      e.kick_t = 0
      add(enemies, e)
      player.x = 40
      player.y = 91
      player.dy = 2
      check_enemy_hits(player)
      assert.are.equal('shell', e.state)
      assert.are.equal(0, e.dx)
    end)

    it('stomping bounces the player upward', function()
      local e = make_enemy(40, 96, 'koopa')
      e.state = 'shell'
      e.dx = shell_spd
      e.kick_t = 0
      add(enemies, e)
      player.x = 40
      player.y = 91
      player.dy = 2
      check_enemy_hits(player)
      assert.is_true(player.dy < 0)
    end)
  end)

  describe('kick grace period', function()
    it('ignores shell-player collision during grace frames', function()
      local e = make_enemy(40, 96, 'koopa')
      e.state = 'shell'
      e.dx = shell_spd
      e.kick_t = 4
      add(enemies, e)
      player.x = 40
      player.y = 96
      player.dy = 0
      assert.are.equal('ok', check_enemy_hits(player))
    end)
  end)
end)
