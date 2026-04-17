-- pico mario clone
-- a single-level platformer

----------------------------------------
-- constants
----------------------------------------
-- physics
grav = 0.4
max_fall = 3
jump_str = -4.16
move_spd = 1.2
run_spd = 2.0
run_jump_str = -5.2
coyote = 5 -- frames of jump grace after leaving edge

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

-- game states
st_play = 0
st_dead = 1
st_clear = 2

