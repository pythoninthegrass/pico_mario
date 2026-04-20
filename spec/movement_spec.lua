describe('acceleration-based movement physics', function()
  before_each(function()
    load_game()
    _G.particles = {}
    _G.coins = 0
    _G.sfx = function() end
    _G.music = function() end
    _G.player = make_player(40, 40)
  end)

  describe('apply_horiz_physics on ground', function()
    it('accelerates toward walk speed from rest', function()
      player.grounded = true
      player.dx = 0
      apply_horiz_physics(player, 1, false)
      assert.is_true(player.dx > 0)
      assert.is_true(player.dx < move_spd)
      assert.are.equal(ground_accel, player.dx)
    end)

    it('clamps to walk speed at the cap', function()
      player.grounded = true
      player.dx = move_spd
      apply_horiz_physics(player, 1, false)
      assert.are.equal(move_spd, player.dx)
    end)

    it('decelerates a running player down to walk speed when run released', function()
      player.grounded = true
      player.dx = run_spd
      apply_horiz_physics(player, 1, false)
      assert.is_true(player.dx < run_spd)
      assert.is_true(player.dx >= move_spd)
    end)

    it('accelerates toward run speed when running', function()
      player.grounded = true
      player.dx = move_spd
      apply_horiz_physics(player, 1, true)
      assert.is_true(player.dx > move_spd)
      assert.is_true(player.dx <= run_spd)
    end)

    it('applies friction when no input and slides to stop', function()
      player.grounded = true
      player.dx = 1.0
      apply_horiz_physics(player, 0, false)
      assert.is_true(player.dx < 1.0)
      assert.is_true(player.dx > 0)
    end)

    it('friction stops cleanly at zero without overshoot', function()
      player.grounded = true
      player.dx = 0.05
      apply_horiz_physics(player, 0, false)
      assert.are.equal(0, player.dx)
    end)

    it('friction on negative velocity clamps at zero', function()
      player.grounded = true
      player.dx = -0.05
      apply_horiz_physics(player, 0, false)
      assert.are.equal(0, player.dx)
    end)

    it('skid decel applies when reversing direction at speed', function()
      player.grounded = true
      player.dx = run_spd
      apply_horiz_physics(player, -1, false)
      -- should decelerate faster than friction
      assert.is_true(player.dx < run_spd - ground_friction)
    end)

    it('sets skidding flag when reversing while running', function()
      player.grounded = true
      player.dx = run_spd
      apply_horiz_physics(player, -1, false)
      assert.is_true(player.skidding)
    end)

    it('skidding flag clears once velocity reverses', function()
      player.grounded = true
      player.dx = 0
      apply_horiz_physics(player, -1, false)
      assert.is_false(player.skidding)
    end)
  end)

  describe('apply_horiz_physics in air', function()
    it('uses reduced acceleration', function()
      player.grounded = false
      player.dx = 0
      apply_horiz_physics(player, 1, false)
      assert.are.equal(air_accel, player.dx)
      assert.is_true(air_accel < ground_accel)
    end)

    it('maintains horizontal speed with no input (no air friction)', function()
      player.grounded = false
      player.dx = 1.0
      apply_horiz_physics(player, 0, false)
      assert.are.equal(1.0, player.dx)
    end)

    it('does not clamp above cap when airborne carrying run speed', function()
      -- carrying run_spd into a walking jump shouldn't snap down instantly
      player.grounded = false
      player.dx = run_spd
      apply_horiz_physics(player, 1, false)
      -- no acceleration beyond cap, but also no sudden drop
      assert.is_true(player.dx >= move_spd)
      assert.is_true(player.dx <= run_spd)
    end)
  end)

  describe('facing', function()
    it('updates facing when input direction provided', function()
      player.facing = 1
      apply_horiz_physics(player, -1, false)
      assert.are.equal(-1, player.facing)
    end)

    it('preserves facing when no input', function()
      player.facing = -1
      apply_horiz_physics(player, 0, false)
      assert.are.equal(-1, player.facing)
    end)
  end)
end)
