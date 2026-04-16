-- pico mario clone
-- a single-level platformer

----------------------------------------
-- constants
----------------------------------------
-- physics
grav=0.4
max_fall=3
jump_str=-4.16
move_spd=1.2
run_spd=2.0
run_jump_str=-5.2
coyote=5 -- frames of jump grace after leaving edge

-- map dimensions (in tiles)
map_w=64
map_h=16

-- sprite flags
f_solid=0
f_hazard=1
f_goal=2
f_coin=3

-- game states
st_play=0
st_dead=1
st_clear=2

