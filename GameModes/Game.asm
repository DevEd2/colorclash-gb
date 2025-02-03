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
    ld      hl,Game_ShipTiles
    call    DecodeWLE

    xor     a
    ldh     [rVBK],a
    ld      hl,Game_RAM
    ld      b,Game_RAMEnd-Game_RAM
    call    MemFillSmall
    ld      a,-1
    ld      [Game_BulletX],a
    ld      [Game_LastColorHit],a

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

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_OBJ16
    ldh     [rLCDC],a

    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei

GameLoop:
    call    Pal_DoFade
    halt
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

    ; now we can run game logic and draw the gems
    ; TODO: run game logic
    call    Game_ProcessGems
    call    Game_DrawGems
    call    Game_DrawShip

    ; input
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

    jr      GameLoop

.shoot
    ; TODO
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

Game_ProcessGems:
    ; TODO
    ret

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
Game_VICGemTiles:   incbin  "GFX/gems_vic.2bpp.wle"

Game_GemPalette:    incbin  "GFX/gems.pal"
Game_VICGemPalette: incbin  "GFX/gems_vic.pal"
Game_ShipPalette:
    rgb8    80,80,80
    rgb8    0,0,0
    rgb8    $48,$60,$70
    rgb8    $b0,$c0,$d0

Game_ShipTiles:     incbin  "GFX/shiptiles.2bpp.wle"

; TODO: rest of game graphics
