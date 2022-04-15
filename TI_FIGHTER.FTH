\ TI FIGHTER  for CAMEL99 FORTH   by Brian Fox Jan 2022
\ Ported from code by B Blodget written for TurboForth

NEEDS DUMP      FROM DSK1.TOOLS \ debugging
NEEDS MARKER    FROM DSK1.MARKER

NEEDS VALUE     FROM DSK1.VALUES
NEEDS HCHAR     FROM DSK1.GRAFIX
NEEDS SPRITE    FROM DSK1.DIRSPRIT
NEEDS SMT.X     FROM DSK1.MOTION
NEEDS JOYST     FROM DSK1.JOYST

MARKER  /FIGHTER

DECIMAL
   0 VALUE Column               \ used by DrawIt
   0 VALUE Row                  \ used by DrawIt

   1 CONSTANT Fire?             \ comparison check for fire button
   2 CONSTANT Left?             \ comparison check for left
   4 CONSTANT Right?            \ comparison check for right
   8 CONSTANT Down?             \ comparison check for down
  16 CONSTANT Up?               \ comparison check for up
  13 CONSTANT ENTER             \ key code for ENTER key
 300 CONSTANT DelayTime         \ delay loop count

\ PlayerObj : Current PlayerObj
0 VALUE PlayerObj

\ Sprite number of the kicking sprite
0 VALUE Kicker

\ Sprite number of the kickie sprite
0 VALUE Kickie

\ Power bars need updating?
FALSE VALUE UpdateBars?

\ Calc constants, vars, and obj

 8   CONSTANT MAX_KICK_TIME
 8   CONSTANT MOD_MOVE_TIME
 1   CONSTANT FACE_LEFT
 2   CONSTANT FACE_RIGHT
20  CONSTANT COINC_TOLERANCE
161  CONSTANT BLANK_CHAR

\ Player1 : Holds data relating to sprite 0
CREATE (Player1) 22 allot

\ Player2 : Holds data relating to sprite 1
create (Player2) 22 allot

\ Constant Offsets into PlayerObj (Fields)
0   CONSTANT CALC_SPRITE
2   CONSTANT CALC_KICK?
4   CONSTANT CALC_KICK_TIME
6   CONSTANT CALC_DIR
8   CONSTANT CALC_ANIM_FRAME
10  CONSTANT CALC_MOVE_TIME
12  CONSTANT CALC_PREV_JOYST
14  CONSTANT CALC_OPP_SPR
16  CONSTANT CALC_POWER_CHAR
18  CONSTANT CALC_POWER
20  CONSTANT CALC_OPP_PLAYER


HEX
\ user defined graphics
: BrickUDG ( --) \ character data for brick wall
   S" 7FAA D5A8 D0A0 C080" 80 CALLCHAR
   S" 8080 8080 8080 807F" 81 CALLCHAR
   S" FEA9 4101 0101 0101" 82 CALLCHAR
   S" 0101 0101 0101 01FE" 83 CALLCHAR ;

: LLineUDG ( --) \ Vertical line on left side
   S" 8080 8080 8080 8080" 88 CALLCHAR ;

: RLineUDG ( --) \ Vertical line on right side
   S" 0101 0101 0101 0101" 89 CALLCHAR ;

: BLineUDG ( --) \ Horizontal line on bottom side
   S" 0000 0000 0000 00FF" 8A CALLCHAR ;

: TLineUDG ( --) \ Horizontal line on top side
   S" FF00 0000 0000 0000" 8B CALLCHAR ;

: LBLineUDG ( --) \ Lines on left and bottom
   S" 8080 8080 8080 80FF" 8C CALLCHAR ;

: RBLineUDG ( --) \ Lines on right and bottom
   S" 0101 0101 0101 01FF" 8D CALLCHAR ;

: LTLineUDG ( --) \ Lines on left and top
   S" FF80 8080 8080 8080" 8E CALLCHAR ;

: RTLineUDG ( --) \ Lines on right and top
   S" FF01 0101 0101 0101" 8F CALLCHAR ;

: LBTLineUDG ( --) \ Lines on left, bottom and top
   S" FF80 8080 8080 80FF" 90 CALLCHAR ;

: RBTLineUDG ( --) \ Lines on right, bottom and top
   S" FF01 0101 0101 01FF" 91 CALLCHAR ;

: BTLineUDG ( --) \ Lines on bottom and top
   S" FF00 0000 0000 00FF" 92 CALLCHAR ;

: DiagUpUDG ( --) \ Diagonal from lower left to upper right
   S" FFFE FCF8 F0E0 C080" 98 CALLCHAR ;

: DiagDownUDG ( --) \ Diagonal from upper right to lower left
   S" FF7F 3F1F 0F07 0301" 99 CALLCHAR ;

: P1BoxUDG ( --) \ Player 1 square for strength indicator. Color set 20
   S" FFFF FFFF FFFF FFFF" A0 CALLCHAR
   S" 0000 0000 0000 0000" A1 CALLCHAR \ Blank char
   ;

: P2BoxUDG ( --) \ Player2 square for strength indicator. Color set 21
   S" FFFF FFFF FFFF FFFF" A8 CALLCHAR ;

0 CONSTANT SPR_FACE_RIGHT1

: PlayerRight1 ( --) \ man facing right, frame #1
   S" 0302 0201 0302 0607" 100 CALLCHAR
   S" 0603 0202 0202 0203" 101 CALLCHAR
   S" 0080 8000 C048 6850" 102 CALLCHAR
   S" 40C0 4040 4040 4070" 103 CALLCHAR ;

4 CONSTANT SPR_FACE_RIGHT2

: PlayerRight2 ( --) \ man facing right, frame #2
   S" 0101 0100 0306 0A07" 104 CALLCHAR
   S" 0203 0202 0204 0406" 105 CALLCHAR
   S" 8040 4080 C868 5040" 106 CALLCHAR
   S" 40C0 4020 1010 101C" 107 CALLCHAR ;

8 CONSTANT SPR_FACE_LEFT1

: PlayerLeft1 ( --) \ man facing left frame #1
   S" 0001 0100 0312 160A" 108 CALLCHAR
   S" 0203 0202 0202 020F" 109 CALLCHAR
   S" C040 4080 C040 60E0" 10A CALLCHAR
   S" 60C0 4040 4040 40C0" 10B CALLCHAR ;

C CONSTANT SPR_FACE_LEFT2

: PlayerLeft2 ( --) \ man facing left frame #2
   S" 0102 0201 1316 0A02" 10C CALLCHAR
   S" 0203 0204 0808 0838" 10D CALLCHAR
   S" 8080 8000 C060 50E0" 10E CALLCHAR
   S" 40C0 4040 4020 2060" 10F CALLCHAR ;

10 CONSTANT SPR_KICK_RIGHT

: PlayerRightKick ( --) \ man facing right kicks
   S" 0101 0100 0306 0A12" 110 CALLCHAR
   S" 1213 0202 0204 0406" 111 CALLCHAR
   S" 8048 4989 D162 4448" 112 CALLCHAR
   S" 50E0 0000 0000 0000" 113 CALLCHAR ;

14 CONSTANT SPR_KICK_LEFT

: PlayerLeftKick ( --) \ man facing left kicks
   S" 0112 9291 8B46 2212" 114 CALLCHAR
   S" 0A07 0000 0000 0000" 115 CALLCHAR
   S" 8080 8000 C060 5048" 116 CALLCHAR
   S" 48C8 4040 4020 2060" 117 CALLCHAR ;

DECIMAL
: NextColumn ( --)      \ advance to the next column
   2 +TO Column ;

: DrawIt ( a b c d --)
  \ emits the four ascii characters on the stack to the screen as follows:
  \ ac
  \ bd
   Column 1+ Row 1+ AT-XY EMIT \ d
   Column 1+ Row    AT-XY EMIT \ c
   Column Row 1+    AT-XY EMIT \ b
   Column Row       AT-XY EMIT \ a
   NextColumn ;

: DrawBrick ( --) \ draws a brick tile at Column & Row
   128 129 130 131 DrawIt ;

: P1Sprite ( --) \  Defines sprite 0
    0 128 24 SPR_FACE_RIGHT1 5 SPRITE

    \ Init the Player1
    0 (Player1) CALC_SPRITE + !
    False (Player1) CALC_KICK? + !
    0 (Player1) CALC_KICK_TIME + !
    FACE_RIGHT (Player1) CALC_DIR + !
    0 (Player1) CALC_ANIM_FRAME + !
    0 (Player1) CALC_MOVE_TIME + !
    0 (Player1) CALC_PREV_JOYST + !
    1 (Player1) CALC_OPP_SPR + !
    160 (Player1) CALC_POWER_CHAR + !
    10 (Player1) CALC_POWER + !
    (Player2) (Player1) CALC_OPP_PLAYER + !
    ;

: P2Sprite ( --) \  Defines sprite 1
    1 128 200 SPR_FACE_LEFT1 2 SPRITE

    \ Init the Player2
    1 (Player2) CALC_SPRITE + !
    False (Player2) CALC_KICK? + !
    0 (Player2) CALC_KICK_TIME + !
    FACE_LEFT (Player2) CALC_DIR + !
    0 (Player2) CALC_ANIM_FRAME + !
    0 (Player2) CALC_MOVE_TIME + !
    0 (Player2) CALC_PREV_JOYST + !
    0 (Player2) CALC_OPP_SPR + !
    168 (Player2) CALC_POWER_CHAR + !
    10 (Player2) CALC_POWER + !
    (Player1) (Player2) CALC_OPP_PLAYER + !
    ;

: DefineGraphics ( --)
  \ define the user defined graphics
  \ and set colours of character sets
   GRaAFIX
   32 0 DO  I 1 14 COLOR  LOOP
   16 1 15 COLOR        \ brick colour
   17 1 8  COLOR        \ shrine color
   18 1 8  COLOR        \ shrine color
   19 8 14 COLOR        \ shrine corner color
   20 5 14 COLOR        \ Player 1 strength box (Purple)
   21 2 14 COLOR        \ Player 2 strength box (Green)
   BrickUDG
   LLineUDG RLineUDG BLineUDG TLineUDG
   LBLineUDG RBLineUDG LTLineUDG RTLineUDG
   LBTLineUDG RBTLineUDG BTLineUDG
   DiagUpUDG DiagDownUDG
   P1BoxUDG P2BoxUDG
   PlayerRight1 PlayerRight2
   PlayerLeft1 PlayerLeft2
   PlayerRightKick PlayerLeftKick
   ;

: BrickRows ( --)
    \ draws rows of bricks at top and bottom of screen
    0 TO Column
    20 TO Row
    2 0 DO
    16 0 DO DrawBrick LOOP
       2 +TO Row 0 TO Column
    LOOP
    ;

: PowerLevel (  x y player_obj --)
    \ (x,y) upper left corner of power level display
    TO PlayerObj
    TO Row
    TO Column

    Column Row AT-XY
    10 0
    DO
        I PlayerObj CALC_POWER + @ <
        IF
            PlayerObj CALC_POWER_CHAR + @ EMIT
        ELSE
            BLANK_CHAR EMIT
        THEN
    LOOP
    False TO UpdateBars?
    ;

: ShintoShrine ( x y --) \ (x,y) upper left corner of shrine
    \ draws the shrine
    TO Column
    TO Row

    \ Top line of big beam
    Column Row AT-XY 142 EMIT
    15 1 DO Column I + Row AT-XY 139 EMIT LOOP
    Column 15 + Row AT-XY 143 EMIT

    \ Bottom line of big beam
    1 +TO Row
    Column Row AT-XY 153 EMIT
    15 1 DO Column I + Row AT-XY 138 EMIT LOOP
    Column 15 + Row AT-XY 152 EMIT

    \ Left Beam
    1 +TO Row
    3 +TO Column
    9 0 DO Column Row I + AT-XY 136 EMIT 137 EMIT LOOP

    \ Right Beam
    8 +TO Column
    9 0 DO Column Row I + AT-XY 136 EMIT 137 EMIT LOOP

    \ Small beam
    -10 +TO Column
    1 +TO Row
    Column Row AT-XY 144 EMIT
    13 1 DO Column I + Row AT-XY 146 EMIT LOOP
    Column 13 + Row AT-XY 145 EMIT
    ;

: Delay ( delay--)
\ simple delay loop
   0 DO LOOP ;

: ClrKey ( -- ) \ Wait for no keypress
    BEGIN  KEY? 0= UNTIL ;

: IncMoveTime ( --)
    \ Increments the CALC_MOVE_TIME of current PlayerObj
    \ Called from Calc
    1 PlayerObj CALC_MOVE_TIME + +!
    PlayerObj CALC_MOVE_TIME + @ MOD_MOVE_TIME MOD 0=
    IF
        \ Change the animation frame
        PlayerObj CALC_ANIM_FRAME + @ 0=
        IF
            1 PlayerObj CALC_ANIM_FRAME + !
        ELSE
            0 PlayerObj CALC_ANIM_FRAME + !
        THEN
    THEN
    ;

: MoveLeft ( --)
    \ Handle joystick moving left
    \ Called from Calc
    PlayerObj CALC_KICK? + NOT
    IF
        \ If not kicking
        PlayerObj @ 0 -1 MOTION    \ Move left
        FACE_LEFT PlayerObj CALC_DIR + !
        IncMoveTime
    THEN
    ;

: MoveRight ( --)
    \ Handle joystick moving right
    \ Called from Calc
    PlayerObj CALC_KICK? + 0=
    IF
        \ If not kicking
        PlayerObj @ 0 1 SPRVEC    \ Move right
        FACE_RIGHT PlayerObj CALC_DIR + !
        IncMoveTime
    THEN
    ;

: Calc ( joy_stick_data player_obj --)
    \ Save addr of player_obj
    TO PlayerObj

    \ Get joy_stick_data, calc SPRVEC
    DUP Fire? AND Fire? =
    PlayerObj CALC_PREV_JOYST + @ Fire? AND Fire? <>
    AND
    IF
        \ Fire (Kick) button is pressed
        True PlayerObj CALC_KICK? + !
        0 PlayerObj CALC_KICK_TIME + !
        PlayerObj @ 0 0 SPRVEC    \ Stop movement
    ELSE DUP Left? AND Left? =
    IF
        MoveLeft
    ELSE DUP Right? AND Right? =
    IF
        MoveRight
    ELSE
        \ Default
        PlayerObj @ 0 0 SPRVEC  \ Stop moving
    THEN THEN THEN

    \ Save joyst value
    PlayerObj CALC_PREV_JOYST + !


    \ Check if Kick has timed out
    PlayerObj CALC_KICK? + @
    IF
        \ Kick in progress
        \ Inc the KICK_TIME
        1 PlayerObj CALC_KICK_TIME + +!
        PlayerObj CALC_KICK_TIME + @ MAX_KICK_TIME >=
        IF
            \ Kick has timed out
            False PlayerObj CALC_KICK? + !
        ELSE
            \ Stop while kicking
            PlayerObj @ 0 0 SPRVEC    \ Stop movement
        THEN
    THEN

    \ Set the correct Sprite
    PlayerObj CALC_KICK? + @
    IF
        \ Kicking
        PlayerObj CALC_DIR + @ FACE_LEFT =
        IF
            \ Kick Left
            PlayerObj @ SPR_KICK_LEFT SPRPAT
        ELSE
            \ Kick Right
            PlayerObj @ SPR_KICK_RIGHT SPRPAT
        THEN
    ELSE
        \ Not Kicking
        PlayerObj CALC_DIR + @ FACE_LEFT =
        IF
            \ Facing Left
            PlayerObj CALC_ANIM_FRAME + @ 0=
            IF
                PlayerObj @ SPR_FACE_LEFT1 SPRPAT
            ELSE
                PlayerObj @ SPR_FACE_LEFT2 SPRPAT
            THEN
        ELSE
            \ Facing Right
            PlayerObj CALC_ANIM_FRAME + @ 0=
            IF
                PlayerObj @ SPR_FACE_RIGHT1 SPRPAT
            ELSE
                PlayerObj @ SPR_FACE_RIGHT2 SPRPAT
            THEN
        THEN
    THEN

    ;


: ProcessKick ( player_obj --)
    \ player_obj is doing the kicking

    \ Save addr of player_obj
    TO PlayerObj
    PlayerObj @ TO Kicker
    PlayerObj CALC_OPP_SPR + @ TO Kickie

    PlayerObj CALC_DIR + @ FACE_LEFT = \ kicker is facing left
    Kickie SPRLOC? SWAP DROP
    Kicker SPRLOC? SWAP DROP
    < \ kickie is to the left of kicker
    AND \ and the kicker is facing left
    IF
        \ send Kickie flying to the left
        Kickie 0 -25 SPRVEC \ Move left

        \ Subtract Power from opponent
        -1 PlayerObj CALC_OPP_PLAYER + @ CALC_POWER + +!

        \ Flag that PowerBars need to be updated
        True TO UpdateBars?
    ELSE
         PlayerObj CALC_DIR + @ FACE_RIGHT = \ kicker is facing right
         Kickie SPRLOC? SWAP DROP
         Kicker SPRLOC? SWAP DROP
          > \ kickie is to the right of kicker
         AND \ and kicker is facing right
         IF
             \ send Kickie flying to the right
             Kickie 0 25 SPRVEC \ Move right

             \ Subtract Power from opponent
             -1 PlayerObj CALC_OPP_PLAYER + @ CALC_POWER + +!

             \ Flag that PowerBars need to be updated
              True TO UpdateBars?
          THEN
    THEN
    ;

: CheckCollision ( --)
    COINC_TOLERANCE 0 1 COINC
    IF
        \ Collision.
        0 0 0 SPRVEC \ Stop moving
        1 0 0 SPRVEC \ Stop moving

        \ Check if sprite one is kicking
        (Player2) CALC_KICK? + @
        IF
            (Player2) ProcessKick
            \ Update the Power bars
            UpdateBars?
            IF
                3 3 (Player1) PowerLevel
            THEN
        THEN

        \ Check if sprite zero is kicking
        (Player1) CALC_KICK? + @
        IF
            (Player1) ProcessKick
            \ Update the Power bars
            UpdateBars?
            IF
                19 3 (Player2) PowerLevel
            THEN
        THEN
    THEN
;

: MainLoop ( --)
    \ Main game loop. Continue until key is pressed
    BEGIN -1 KEY? = WHILE
        \ Get joystick data
        1 JOYST
        0 JOYST

        \ Calc new sprites and positions
        (Player1) Calc
        (Player2) Calc

        \ Check collision
        CheckCollision

        \  Move the sprites
        0 2 SPRMOV

        \ Sleep for a bit
        DelayTime Delay
    REPEAT
    ;

: Fighter ( --)
    \ entry point of game
    DefineGraphics BrickRows
    9 8 ShintoShrine
    3 MAGNIFY
    P1Sprite
    P2Sprite
    3 3 (Player1) PowerLevel
    19 3 (Player2) PowerLevel
    30 23 AT-XY
    ClrKey
    MainLoop
    ;
