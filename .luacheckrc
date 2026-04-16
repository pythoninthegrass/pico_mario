-- luacheck config for PICO-8
-- PICO-8 uses Lua 5.2-ish syntax plus extensions (+=, !=, etc.)
std = "lua52"

-- PICO-8 source files are concatenated; globals defined in one file
-- are used in another
allow_defined_top = true

-- allow compound assignment operators (+=, -=, *=, /=, %=, ^=, ..=)
operators = {"+=", "-=", "*=", "/=", "%=", "^=", "..="}

-- project globals defined across src/*.lua files (concatenated at build time)
globals = {
  -- constants.lua
  "grav", "max_fall", "jump_str", "move_spd", "run_spd", "run_jump_str", "coyote",
  "map_w", "map_h",
  "f_solid", "f_hazard", "f_coin", "f_goal",
  "st_play", "st_dead", "st_clear",

  -- helpers.lua
  "tile_at", "tile_flag_at", "is_solid", "is_hazard", "is_goal", "collect_coin",

  -- player.lua
  "make_player", "player_move", "player_check_tiles",

  -- camera.lua
  "update_cam",

  -- particles.lua
  "particles", "spawn_particles", "update_particles", "draw_particles",

  -- states.lua
  "update_play", "get_player_spr", "update_dead", "update_clear",

  -- main.lua shared state
  "player", "cam_x", "cam_y", "state", "coins", "death_t", "clear_t",
}

-- PICO-8 API globals (read-only)
read_globals = {
  -- system callbacks (set by user, called by runtime)
  "_init", "_update", "_update60", "_draw",

  -- input
  "btn", "btnp",

  -- graphics
  "spr", "sspr", "map", "mget", "mset", "fget", "fset",
  "palt", "pal", "cls", "camera",
  "circ", "circfill", "rect", "rectfill",
  "line", "pset", "print", "cursor", "color", "clip", "fillp",

  -- math
  "flr", "ceil", "abs", "sgn", "sqrt", "atan2", "sin", "cos",
  "band", "bor", "bxor", "bnot", "shl", "shr", "lshr", "rotl", "rotr",
  "min", "max", "mid", "rnd", "srand",

  -- tables
  "add", "del", "deli", "all", "foreach", "count",

  -- strings
  "sub", "chr", "ord", "tostr", "tonum", "split",

  -- memory / cart data
  "poke", "poke2", "poke4", "peek", "peek2", "peek4",
  "memcpy", "memset", "reload", "cstore",
  "cartdata", "dget", "dset",

  -- audio
  "sfx", "music",

  -- system
  "t", "time", "stat", "printh", "menuitem", "flip", "extcmd",

  -- coroutines
  "cocreate", "coresume", "costatus", "yield",
}

-- suppress "unused global" — src files are concatenated, so globals
-- defined in one file are consumed by another
ignore = {"131"}

-- no line length limit (PICO-8 has token limits, not line limits)
max_line_length = false

-- spec/ overrides
files["spec/"] = {
  std = "lua52+busted",
}

-- e2e driver templates contain $PLACEHOLDER tokens that aren't valid Lua
exclude_files = {
  "spec/e2e_driver.lua",
  "spec/e2e_driver_html.lua",
}
