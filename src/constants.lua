-- pico mario clone
-- a single-level platformer

----------------------------------------
-- constants
----------------------------------------
-- physics
grav = 0.4
max_fall = 3
jump_str = -5.0
move_spd = 1.2
run_spd = 2.0
run_jump_str = -6.0
coyote = 5 -- frames of jump grace after leaving edge

-- horizontal acceleration model
ground_accel = 0.14    -- px/frame^2 toward target on ground
air_accel = 0.07       -- px/frame^2 toward target in air
ground_friction = 0.21 -- px/frame^2 decel when no input (ground)
skid_decel = 0.29      -- px/frame^2 decel when reversing direction

-- enemy spawning: spawn enemies this many pixels ahead of camera
-- (screen is 128px; 160 gives 32px / 4 tiles of lead time)
spawn_ahead = 160

-- enemies
enemy_spd = 0.5
max_enemies = 6
squish_len = 30         -- frames a squished enemy stays visible
stomp_bounce = -3.5     -- player dy applied on a successful stomp
chain_scores = { 100, 200, 400, 800, 1000 }
shell_spd = 2.0         -- moving shell velocity magnitude
kick_grace_len = 4      -- frames after a kick where player-shell contact is ignored

-- power state timers (frames)
invuln_len = 120      -- ~2s post-shrink invulnerability
transform_len = 30    -- ~0.5s grow/shrink animation
invince_len = 600     -- ~10s star invincibility

-- star item physics
star_spd = 1          -- constant horizontal speed (1 px/frame)
star_bounce = -3      -- upward dy applied on each ground landing

-- enemy backflip (struck by invincible mario)
flip_rise = -3        -- upward dy launched when enemy is flipped

-- map dimensions (in tiles)
map_w = 128
map_h = 16

-- sprite flags
f_solid = 0
f_hazard = 1
f_goal = 2
f_coin = 3
f_breakable = 4
f_question = 5
f_pipe = 6
-- bit 7 reserved

-- sprite ids (new layout, row-aligned)
-- row 0: player
spr_idle = 1
spr_run1 = 2
spr_run2 = 3
spr_jump = 4
spr_dead = 5
spr_spawn = 6
spr_spike = 8
-- row 1: terrain
spr_ground = 16
spr_brick = 17
spr_qblock1 = 18
spr_qblock2 = 19
spr_hitblock = 20
spr_hardblock = 21
-- row 2: pipes
spr_pipe_tl = 32
spr_pipe_tr = 33
spr_pipe_bl = 34
spr_pipe_br = 35
-- row 3: enemies
spr_goomba1 = 48
spr_goomba2 = 49
spr_goomba_flat = 50
spr_koopa1 = 51
spr_koopa2 = 52
spr_koopa_shell = 53
-- row 4: items
spr_coin1 = 64
spr_coin2 = 65
spr_mushroom = 66
spr_star = 67
spr_fireflower = 68
-- row 5: flagpole / castle
spr_pole_top = 80
spr_pole_shaft = 81
spr_flag = 82
spr_castle = 83
spr_castle_top = 84
spr_castle_door = 85
-- row 6: decorations
spr_cloud_l = 96
spr_cloud_m = 97
spr_cloud_r = 98
spr_bush_l = 99
spr_bush_m = 100
spr_bush_r = 101
spr_hill = 102
spr_hill_top = 103
spr_hill_sm = 104
-- row 7: big mario (top halves; bottoms at id + 16)
spr_big_idle = 112
spr_big_run1 = 113
spr_big_run2 = 114
spr_big_jump = 115

-- game states
st_play = 0
st_dead = 1
st_clear = 2

