section "Game RAM",wram0

; these values may need tweaking
def GAME_START_SPEED = 8
def GAME_PACE = 8
def GAME_MAX_SPEED = 99

Game_RAM:
Game_Score:         ds  4   ; 4 digits
Game_Health:        db  ; maximum of 3
Game_Blocks:        ds  2*5 ; y pos, color
Game_PlayerPos:     db  ; which column the player is in
Game_PlayerX:       db  ; actual X position
Game_CurrentColor:  db  ; selected color
Game_BulletPos:     db  ; which column the bullet is in
Game_BulletX:       db  ; which column the player's bullet is in (-1 = none present)
Game_BulletY:       db  ; Y position of bullet
Game_BulletColor:   db  ; color of bullet
Game_LastColorHit:  db  ; color of last block hit
Game_HitCount:      db  ; number of times in a row you've hit a block of a given color
Game_CurrentSpeed:  db  ; number of subpixels blocks move down per frame
Game_BlockSubpixel: db  ; current subpixel of blocks
Game_SpeedPacer:    db  ; how fast speed increases

Game_GemRAM:        ds  5*2

Game_RAMEnd:

section "Game routines",rom0

GM_Game:
    call    LCDOff
    xor     a
    ldh     [rVBK],a
    ld      hl,OAMBuffer
    ld      b,a
    call    MemFillSmall
    ld      a,bank(Game_BGPalette)
    rst     _Bankswitch
    ld      hl,Game_BGPalette
    xor     a
    call    LoadPal
    ld      a,1
    call    LoadPal
    ld      a,2
    call    LoadPal
    ld      a,3
    call    LoadPal
    ld      a,4
    call    LoadPal
    ld      a,5
    call    LoadPal
    ld      a,6
    call    LoadPal
    ld      a,7
    call    LoadPal

    ; load gem palette
    ; TODO: use VIC-20 gem palette if option is selected
    ld      hl,Game_GemPalette
    ld      a,8
    call    LoadPal
    ld      a,9
    call    LoadPal
    ld      a,10
    call    LoadPal
    ld      a,11
    call    LoadPal
    ld      a,12
    call    LoadPal
    ld      hl,Game_ShipPalette
    ld      a,13
    call    LoadPal
    ld      a,14
    call    LoadPal

    call    CopyPalettes

    call    PalFadeInWhite

    ld      hl,Game_BGTiles
    ld      de,_VRAM
    call    DecodeWLE
    ; hl = Game_BeamTiles
    call    DecodeWLE
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr

    ld      a,1
    ldh     [rVBK],a
    ; TODO: load VIC-20 gem graphics if option is selected
    ld      hl,Game_GemTiles
    ld      de,_VRAM
    call    DecodeWLE
    ; load ship graphics
    ld      hl,Game_SpriteTiles
    call    DecodeWLE

    xor     a
    ldh     [rVBK],a
    ld      hl,Game_RAM
    ld      b,Game_RAMEnd-Game_RAM
    call    MemFillSmall
    ld      a,-1
    ld      [Game_BulletX],a
    ld      [Game_LastColorHit],a
    ld      a,-16
    ld      [Game_BulletY],a
    ld      a,GAME_START_SPEED
    ld      [Game_CurrentSpeed],a
    ld      a,GAME_PACE
    ld      [Game_SpeedPacer],a

    ; init gems
    ld      hl,Game_GemRAM
    xor     a
    ld      [hl],0
    inc     l
    ld      [hl+],a
    inc     a
    ld      [hl],0
    inc     l
    ld      [hl+],a
    inc     a
    ld      [hl],0
    inc     l
    ld      [hl+],a
    inc     a
    ld      [hl],0
    inc     l
    ld      [hl+],a
    inc     a
    ld      [hl],0
    inc     l
    ld      [hl],a

    ld      a,bank(Mus_Ingame)
    call    GBMod_LoadModule

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_OBJ16
    ldh     [rLCDC],a

    ld      a,IEF_VBLANK | IEF_TIMER
    ldh     [rIE],a
    ei

GameLoop:
    call    Pal_DoFade  ; too slow to run during VBlank, so do it here
    rst     _WaitVBlank
    ; draw beam
    ; *MUST* be done during VBlank, so do it before everything else
    ld      b,Game_BeamMap.end-Game_BeamMap
    ld      de,$99e3
    ldh     a,[hGlobalTimer]
    bit     1,a
    jr      z,.off
.on
    ld      a,bank(Game_BeamMap)
    rst     _Bankswitch
    ld      hl,Game_BeamMap
:   ld      a,[hl+]
    ld      [de],a
    inc     e
    dec     b
    jr      nz,:-
    jr      .donebeam
.off
:   ld      a,$d
    ld      [de],a
    inc     e
    dec     b
    jr      nz,:-
.donebeam

    ; player controls
    ldh     a,[hPressedButtons]
    bit     BIT_A,a
    call    nz,.shoot
    bit     BIT_LEFT,a
    call    nz,.left
    bit     BIT_RIGHT,a
    call    nz,.right
    bit     BIT_UP,a
    call    nz,.nextgem
    bit     BIT_DOWN,a
    call    nz,.prevgem

    ; convert player column to player X position
    ld      a,[Game_PlayerPos]
    add     a   ; x2
    ld      b,a
    add     a   ; x4
    ld      c,a
    add     a   ; x8
    add     a   ; x16
    add     c   ; x20
    add     b   ; x22
    add     36 + 8
    ld      [Game_PlayerX],a

    call    Game_ProcessGems
    ; update bullet
    ld      a,[Game_BulletY]
    cp      -16
    jp      z,.skipbullet
    sub     8
    ld      [Game_BulletY],a
    ; check for collisions
    ld      b,a
    ld      hl,Game_GemRAM
    ld      a,[Game_BulletPos]
    add     a
    add     l
    ld      l,a
    jr      nc,:+
    inc     h
:   ; check Y position of block
    ld      a,[hl+]
    add     16  ; account for vertical offset
    cp      b
    jp      c,.skipbullet
    ld      a,[Game_SpeedPacer]
    dec     a
    ld      [Game_SpeedPacer],a
    jr      nz,:+
    ld      a,GAME_PACE
    ld      [Game_SpeedPacer],a
    ld      a,[Game_CurrentSpeed]
    cp      GAME_MAX_SPEED
    jr      z,:+
    inc     a
    ld      [Game_CurrentSpeed],a
:   ld      a,-16
    ld      [Game_BulletY],a
    ld      a,[Game_BulletColor]
    ld      b,a
    ld      a,[hl-]
    cp      b
    jr      nz,.mismatch
.match
    ; reset block's Y pos
    xor     a
    ld      [hl+],a
    ; randomize color
    push    hl
    ld      a,5
    push    bc
    call    Math_RandRange
    pop     bc
    pop     hl
    ld      [hl+],a
    ; update score
    ; if we've hit 5 or more blocks of the same color in a row, 10 points are awarded
    ; otherwise, 1 point is awarded
    ld      a,[Game_LastColorHit]
    cp      b
    ld      a,b
    ld      [Game_LastColorHit],a
    jr      z,.match_checkfor5hits
    xor     a
    ld      [Game_HitCount],a
    call    Game_Add1Point
    jr      .skipbullet
.match_checkfor5hits
    ld      a,[Game_HitCount]
    inc     a
    cp      4
    ld      [Game_HitCount],a
    jr      nc,:+
    call    Game_Add1Point
    jr      .skipbullet
:   call    Game_Add10Points
    jr      .skipbullet

.mismatch
    ; reset hit count
    xor     a
    ld      [Game_HitCount],a
    ; nudge all blocks down 8 pixels
    push    hl
    ld      hl,Game_GemRAM
    rept    5
    ld      a,[hl]
    add     8
    ld      [hl+],a
    inc     hl
    endr
    jr      .skipbullet
.skipbullet
    ; draw stuff
    call    Game_DrawGems
    call    Game_DrawShip
    ; draw bullet
    ; HL should be a pointer to the last free slot in the OAM buffer
    ; bullet Y
    ld      a,[Game_BulletY]
    add     16
    ld      [hl+],a
    ld      a,[Game_BulletX]
    add     8
    ld      [hl+],a
    ; bullet tile
    ld      a,[Game_BulletColor]
    ld      c,a
    add     a
    add     a
    ld      b,a
    ldh     a,[hGlobalTimer]
    add     a
    and     2
    add     b
    add     $5c
    ld      [hl+],a
    ; bullet attribute
    ld      a,4
    sub     c
    set     3,a
    ld      [hl+],a
    ; draw score
    ; digit 1 y
    ld      [hl],8
    inc     l
    ; digit 1 x
    ld      [hl],35 + 8
    inc     l
    ; digit 1 tile
    ld      a,[Game_Score]
    and     $f
    add     a
    add     $70
    ld      [hl+],a
    ; digit 1 attribute
    ld      [hl],$e
    inc     l
    ; digit 2 y
    ld      [hl],8
    inc     l
    ; digit 2 x
    ld      [hl],(35 + 8) + 5
    inc     l
    ; digit 2 tile
    ld      a,[Game_Score+1]
    and     $f
    add     a
    add     $70
    ld      [hl+],a
    ; digit 2 attribute
    ld      [hl],$e
    inc     l


    ; digit 3 y
    ld      [hl],8
    inc     l
    ; digit 3 x
    ld      [hl],(35 + 8) + 10
    inc     l
    ; digit 3 tile
    ld      a,[Game_Score+2]
    and     $f
    add     a
    add     $70
    ld      [hl+],a
    ; digit 3 attribute
    ld      [hl],$e
    inc     l
    ; digit 4 y
    ld      [hl],8
    inc     l
    ; digit 4 x
    ld      [hl],(35 + 8) + 15
    inc     l
    ; digit 4 tile
    ld      a,[Game_Score+3]
    and     $f
    add     a
    add     $70
    ld      [hl+],a
    ; digit 4 attribute
    ld      [hl],$e
    inc     l

    jp      GameLoop

.shoot
    push    af
    ld      a,[Game_BulletY]
    cp      -16
    jr      nz,:+
    ld      a,[Game_PlayerPos]
    ld      [Game_BulletPos],a
    ld      a,[Game_CurrentColor]
    ld      [Game_BulletColor],a
    ld      a,136-10
    ld      [Game_BulletY],a
    ld      a,[Game_PlayerX]
    sub     12
    ld      [Game_BulletX],a
:   pop     af
    ret
.left
    push    af
    ld      a,[Game_PlayerPos]
    and     a
    jr      z,:+
    dec     a
    ld      [Game_PlayerPos],a
:   pop     af
    ret
.right
    push    af
    ld      a,[Game_PlayerPos]
    cp      4
    jr      z,:+
    inc     a
    ld      [Game_PlayerPos],a
:   pop     af
    ret
.nextgem
    push    af
    ld      a,[Game_CurrentColor]
    inc     a
    cp      5
    jr      nz,:+
    xor     a
:   ld      [Game_CurrentColor],a
    pop     af
    ret
.prevgem
    push    af
    ld      a,[Game_CurrentColor]
    dec     a
    cp      $ff
    jr      nz,:+
    ld      a,4
:   ld      [Game_CurrentColor],a
    pop     af
    ret

Game_Add1Point:
    ld      a,[Game_Score+3]
    inc     a
    cp      10
    ld      [Game_Score+3],a
    ret     nz
    xor     a
    ld      [Game_Score+3],a
Game_Add10Points:
    ld      a,[Game_Score+2]
    inc     a
    cp      10
    ld      [Game_Score+2],a
    ret     nz
    xor     a
    ld      [Game_Score+2],a
Game_Add100Points:
    ld      a,[Game_Score+1]
    inc     a
    cp      10
    ld      [Game_Score+1],a
    ret     nz
    xor     a
    ld      [Game_Score+1],a
Game_Add1000Points:
    ld      a,[Game_Score]
    inc     a
    cp      10
    ld      [Game_Score],a
    ret     nz
    ; cap score to 9999
    ld      a,9
    ld      [Game_Score],a
    ld      [Game_Score+1],a
    ld      [Game_Score+2],a
    ld      [Game_Score+3],a
    ret

Game_ProcessGems:
    ld      a,[Game_CurrentSpeed]
    ld      b,a
    ld      a,[Game_BlockSubpixel]
    add     b
    ld      [Game_BlockSubpixel],a
    ret     nc
    ld      hl,Game_GemRAM
    ld      bc,2
    rept    5
    inc     [hl]
    ld      a,[hl]
    cp      104
    jr      nc,.gameover
    add     hl,bc
    endr
    ret
.gameover
    call    PalFadeOutWhite
:   rst     _WaitVBlank
    call    Pal_DoFade
    ld      a,[sys_FadeState]
    bit     0,a
    jr      nz,:-
    call    LCDOff
    jr      @

Game_DrawGems:
    ld      hl,Game_GemRAM
    lb      bc,5,36
    ld      de,OAMBuffer
.loop
    ; left Y
    ld      a,[hl+]
    add     24
    ld      [de],a
    inc     e
    ; left X
    ld      a,c
    ld      [de],a
    inc     e
    ; left tile
    ld      a,[hl-]
    ldh     [hTemp],a
    add     a
    add     a
    push    bc
    ld      b,a
    ld      a,[hGlobalTimer]
    bit     0,a
    ld      a,b
    pop     bc
    jr      nz,:+
    add     5 * 4
:   push    af
    ld      [de],a
    inc     e
    ; left color
    push    bc
    ldh     a,[hTemp]
    ld      b,a
    ld      a,4
    sub     b
    pop     bc
    set     3,a
    ldh     [hTemp2],a
    ld      [de],a
    inc     e
    ; right Y
    ld      a,[hl+]
    inc     l
    add     24
    ld      [de],a
    inc     e
    ; right X
    ld      a,c
    add     8
    ld      [de],a
    inc     e
    ; right tile
    pop     af
    add     2
    ld      [de],a
    inc     e
    ; right color
    ldh     a,[hTemp2]
    ld      [de],a
    inc     e
    dec     b
    ret     z
    ld      a,c
    add     22
    ld      c,a
    jr      .loop

; DE should be left over from Game_DrawGems
Game_DrawShip:
    ld      h,d
    ld      l,e

    ; gem overlay top Y
    ld      a,119 + 16
    ld      [hl+],a
    ; gem overlay top X
    ld      a,[Game_PlayerX]
    sub     4
    ld      c,a
    ld      [hl+],a
    ; gem overlay top tile
    ld      a,[Game_CurrentColor]
    add     a
    add     a
    add     a
    ld      b,a
    ld      a,[hGlobalTimer]
    and     1
    add     a
    add     a
    add     b
    add     $34
    ld      e,a
    ld      [hl+],a
    ; gem overlay top attributes
    ld      a,[Game_CurrentColor]
    ld      b,a
    ld      a,4
    sub     b
    set     3,a
    ld      d,a
    ld      [hl+],a
    ; gem overlay top Y
    ld      a,135 + 16
    ld      [hl+],a
    ; gem overlay top X
    ld      a,c
    ld      [hl+],a
    ; gem overlay tile
    ld      a,e
    add     2
    ld      [hl+],a
    ; gem overlay attribute
    ld      a,d
    ld      [hl+],a

    ; left y
    ld      a,128 + 16
    ld      [hl+],a
    ; left x
    ld      a,[Game_PlayerX]
    sub     12
    ld      [hl+],a
    ; left tile
    ld      a,[hGlobalTimer]
    and     1
    add     a   ; x2
    ld      b,a
    ld      a,$28
    add     b
    ld      [hl+],a
    ld      e,a
    ; left attribute
    ld      a,5 | %1000
    ld      [hl+],a

    ; center y
    ld      a,128 + 16
    ld      [hl+],a
    ; center x
    ld      a,[Game_PlayerX]
    sub     4
    ld      [hl+],a
    ; center tile
    ld      a,e
    add     4
    ld      e,a
    ld      [hl+],a
    ld      c,a
    ; center attribute
    ld      a,5 | %1000
    ld      [hl+],a

    ; right y
    ld      a,128 + 16
    ld      [hl+],a
    ; right x
    ld      a,[Game_PlayerX]
    add     4
    ld      [hl+],a
    ; right tile
    ld      a,e
    add     4
    ld      [hl+],a
    ld      c,a
    ; right attribute
    ld      a,5 | %1000
    ld      [hl+],a

    ret

section "Game GFX",romx

Game_BGPalette:     incbin  "GFX/game.pal"
Game_BeamPalette:   incbin  "GFX/beam.pal"

Game_BGTiles:       incbin  "GFX/game.2bpp.wle"
Game_BeamTiles:     incbin  "GFX/beam.2bpp.wle"

Game_BGMap:         incbin  "GFX/game.map"
Game_BeamMap:       incbin  "GFX/beam.map"
.end

Game_GemTiles:      incbin  "GFX/gems.2bpp.wle"
;Game_VICGemTiles:   incbin  "GFX/gems_vic.2bpp.wle"

Game_GemPalette:    incbin  "GFX/gems.pal"
;Game_VICGemPalette: incbin  "GFX/gems_vic.pal"
Game_ShipPalette:
    rgb8    $80,$80,$80
    rgb8    $00,$00,$00
    rgb8    $48,$60,$70
    rgb8    $b0,$c0,$d0
Game_HUDPalette:
    rgb8    $80,$80,$80
    rgb8    $00,$00,$00
    rgb8    $78,$90,$a0
    rgb8    $ff,$ff,$ff

Game_SpriteTiles:     incbin  "GFX/gamesprites.2bpp.wle"

; TODO: rest of game graphics
