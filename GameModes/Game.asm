section "Game RAM",wram0

Game_RAM:
Game_Score:         ds  5   ; 5 digits
Game_Health:        db  ; maximum of 3
Game_Blocks:        ds  2*5 ; y pos, color
Game_PlayerPos:     db  ; which column the player is in
Game_PlayerX:       db  ; actual X position
Game_CurrentColor:  db  ; selected color
Game_BulletX:       db  ; which column the player's bullet is in (-1 = none present)
Game_BulletY:       db  ; Y position of bullet
Game_BulletColor:   db  ; color of bullet
Game_LastColorHit:  db  ; color of last block hit
Game_HitCount:      db  ; number of times in a row you've hit a block of a given color
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
    xor     a
    ldh     [rVBK],a

    ld      hl,Game_RAM
    ld      b,Game_RAMEnd-Game_RAM
    call    MemFillSmall
    ld      a,-1
    ld      [Game_BulletX],a
    ld      [Game_LastColorHit],a

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_OBJ8
    ldh     [rLCDC],a

    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei

GameLoop:
    call    Pal_DoFade
    halt
    ; draw beam
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
    jr      GameLoop
.off
:   ld      a,$d
    ld      [de],a
    inc     e
    dec     b
    jr      nz,:-
    jr      GameLoop

section "Game GFX",romx

Game_BGPalette:     incbin  "GFX/game.pal"
Game_BeamPalette:   incbin  "GFX/beam.pal"

Game_BGTiles:       incbin  "GFX/game.2bpp.wle"
Game_BeamTiles:     incbin  "GFX/beam.2bpp.wle"

Game_BGMap:         incbin  "GFX/game.map"
Game_BeamMap:       incbin  "GFX/beam.map"
.end

Game_GemTiles:      incbin  "GFX/gems.2bpp.wle"
Game_VICGemTiles:   incbin  "GFX/gems_vic.2bpp.wle"

Game_GemPalette:    incbin  "GFX/gems.pal"
Game_VICGemPalette: incbin  "GFX/gems_vic.pal"

; TODO: rest of game graphics
