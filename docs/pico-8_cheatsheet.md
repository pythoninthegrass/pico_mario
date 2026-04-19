# PICO-8 Cheat Sheet

PICO-8 0.1.11c

Source: <http://www.lexaloffle.com/pico-8.php?page=manual>

More in-depth cheat sheet: <https://neko250.github.io/pico8-api/>

## Command Line

```
RUN             FOLDER
SAVE <FILENAME> LOAD <FILENAME>
SPLORE          EXPORT <FILENAME>.BIN
IMPORT <FILENAME>.P8L
INSTALL_GAMES
LS/DIR          CD <PATH>
REBOOT          SHUTDOWN
```

## Vars and Types

```
B=NIL           B=FALSE
A=1             B="HELLO"
TABLES, "INTS", "STRS"
```

## Operators

```
+ - * / %
^     -- power
< > <= >= ~= ==
AND   OR   NOT
```

## Functions

```
FUNCTION FUNCNAME(A,B)
  -- body
END
```

## If Statement

```
IF (CONDITION) THEN
  PRINT("HELLO")
  PRINT("WORLD")
ELSEIF (CONDITION) THEN
  PRINT("PLEASE ENTER A")
ELSE
  PRINT("?")
END
```

Short form:
```
IF (COND) STMT
```

## Tables

```
T={}            A={11,12,9,4}
T.X=2           T.Y=3         -- or T["X"]=2
PRINT(T.X)      -- 2
COUNT(T)         -- 4 (length)
ADD(T, VAL)
DEL(T, VAL)
FOREACH(T, FN)
ALL(T)           -- iterator
PAIRS(T)         -- key/val iterator
```

## Loops

```
FOR I=1,10 DO ... END
FOR I=1,10,STEP DO ... END

REPEAT ... UNTIL(COND)

FOR I IN ALL(V) DO ... END
FOR K,V IN PAIRS(T) DO ... END

WHILE (CONDITION) DO
  -- body
END
```

### Loop Control

```
BREAK           -- exit loop
RETURN <EXPR>   -- return from function
```

## Shortcuts

```
?               -- PRINT
A += B          -- A = A + B
A -= B          -- A = A - B
A *= B          -- A = A * B
A /= B         -- A = A / B
A %= B          -- A = A % B
IF (COND) STMT  -- single line if
```

## Shorthands / Shorthand Code

```
-- ->           -- SPLIT INTO MULTI LINES
--[[ ... ]]     -- BLOCK COMMENT
IF (TRUE) SHORT_STMT
FULLSCREEN=FILLP(0x5A5A.8)
CARTDATA("TITLE")
DSET(SLOT,VAL)  DGET(SLOT)
```

## Cartridge Data

```
RELOAD()
CSTORE()
CARTDATA("TITLE")
DSET(SLOT, VAL)
DGET(SLOT)
MEMCPY(DEST, SRC, LEN)
POKE(ADDR, VAL)      PEEK(ADDR)
```

## RAM Memory Layout

```
0x0000  GFX
0x1000  GFX2 / MAP2
0x2000  MAP
0x3000  GFX FLAGS
0x3100  SONG
0x3200  SFX
0x4300  USER DATA
0x5E00  PERSISTENT CART DATA
0x5F00  DRAW STATE
0x6000  SCREEN
```

## Memory Manipulation

```
CSTORE(DEST, SRC, LEN)
MEMCPY(DEST_ADDR, SRC_ADDR, LEN)
MEMSET(DEST_ADDR, VAL, LEN)
PEEK(ADDR)
POKE(ADDR, VAL)
RELOAD(DEST, SRC, LEN)
```

## Coroutines

```
COCREATE(FN)            -- create
COSTATUS(COR)           -- status
CORESUME(COR)           -- resume
YIELD()                 -- yield
```

## Special Callbacks

```
_INIT()         -- called once at start
_UPDATE()       -- called every frame (30fps)
_UPDATE60()     -- called every frame (60fps)
_DRAW()         -- called every frame for drawing
```

## Colors

```
 0  BLACK          1  DARK_BLUE
 2  DARK_PURPLE    3  DARK_GREEN
 4  BROWN          5  DARK_GREY
 6  LIGHT_GREY     7  WHITE
 8  RED            9  ORANGE
10  YELLOW        11  GREEN
12  BLUE          13  INDIGO
14  PINK          15  PEACH
```

## Math

```
MAX(X, Y)       MIN(X, Y)
MID(X, Y, Z)    -- clamp between
FLR(X)          CEIL(X)
COS(T)          SIN(T)
ATAN2(DX, DY)
SQRT(X)
ABS(X)
RND(X)          SRAND(X)
SGN(X)          BAND(X, Y)
BOR(X, Y)       BXOR(X, Y)
BNOT(X)         SHL(X, N)
SHR(X, N)       LSHR(X, N)
ROTL(X, N)      ROTR(X, N)
```

## Pixels

```
PGET(X, Y)
PSET(X, Y, C)
```

## Sprite Flags

```
FGET(N)             -- get all flags
FGET(N, F)          -- get flag F
FSET(N, V)          -- set all flags
FSET(N, F, V)       -- set flag F
```

## Shapes

```
LINE(X0, Y0, X1, Y1, [COL])
RECT(X0, Y0, X1, Y1, [COL])
RECTFILL(X0, Y0, X1, Y1, [COL])
CIRC(X, Y, R, [COL])
CIRCFILL(X, Y, R, [COL])
OVAL(X0, Y0, X1, Y1, [COL])
OVALFILL(X0, Y0, X1, Y1, [COL])
```

## Screen

```
CLIP(X, Y, W, H)       -- set clipping
CAMERA(X, Y)            -- set camera offset
CLS([COL])              -- clear screen
PAL(C0, C1, [P])        -- palette swap
PALT(C, T)              -- transparency
FILLP(P)                -- fill pattern
```

Size: 128x128 pixels

## Controls

```
BTN(B, [P])     -- button state
BTNP(B, [P])    -- button pressed (with repeat)
```

Buttons: 0=left 1=right 2=up 3=down 4=O 5=X

## String Manipulation

```
#S              -- string length
S..T            -- concatenate
SUB(S, FROM, [TO])
TOSTR(V)
TONUM(S)
```

## Types

```
TYPE(V)         -- returns type string
```

## Sprites

```
SPR(N, X, Y, [W, H], [FLIP_X], [FLIP_Y])
SSPR(SX, SY, SW, SH, DX, DY, [DW, DH], [FLIP_X], [FLIP_Y])
SGET(X, Y)             -- get spritesheet pixel
SSET(X, Y, C)          -- set spritesheet pixel
```

## Map

```
MAP(CELX, CELY, SX, SY, CELW, CELH, [LAYER])
MGET(X, Y)             -- get map tile
MSET(X, Y, V)          -- set map tile
```

## Print

```
PRINT(STR, [X, Y, [COL]])
CURSOR(X, Y)
COLOR(COL)
```

## Sound

```
SFX(N, [CHANNEL, [OFFSET, [LENGTH]]])
MUSIC(N, [FADEMS, [CHANNELMASK]])
```

## Tracker

```
N=108 notes (C0 to B8)
SFX editor: 32 notes per SFX, speed, loop
```
