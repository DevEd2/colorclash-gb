
section "Title screen RAM",wram0
Title_MenuPos:  db

section "Title screen routines",rom0
GM_Title:
    call    LCDOff
    ld      a,bank(Title_BGPalette)
    rst     _Bankswitch
    ld      hl,Title_BGPalette
    xor     a
    ld      [Title_MenuPos],a
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
    ld      a,bank(Title_BGOverlayPalette)
    rst     _Bankswitch
    ld      hl,Title_BGOverlayPalette
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
    ld      a,13
    call    LoadPal
    ld      a,14
    call    LoadPal
    ld      a,15
    call    LoadPal

    call    CopyPalettes


    call    PalFadeInWhite

    ld      a,bank(Title_BGTiles1)
    rst     _Bankswitch
    ld      hl,Title_BGTiles1
    ld      de,_VRAM
    call    DecodeWLE
    ; hl = Title_BGMap
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemap
    ; hl = Title_BGAttr
    ld      a,1
    ldh     [rVBK],a
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemap

    ld      a,[GBM_SongID]
    ld      b,a
    ld      a,bank(Mus_Title)
    cp      b
    call    nz,GBMod_LoadModule

    ; draw overlay + arrow sprites
    xor     a
    ld      [Metasprite_OAMPos],a
    ld      hl,Sprite_titlespr
    ld      a,bank(Sprite_titlespr)
    lb      de,11,18
    call    DrawMetasprite
    ld      a,bank(Sprite_titlespr_GFX)
    rst     _Bankswitch
    ld      hl,Sprite_titlespr_GFX
    ld      de,_VRAM
    ld      a,1
    ldh     [rVBK],a
    call    DecodeWLE
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG9800 | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_OBJ8
    ldh     [rLCDC],a

    ld      a,IEF_VBLANK | IEF_TIMER
    ldh     [rIE],a
    ei


TitleLoop:
    ; do fading
    call    Pal_DoFade
    ldh     a,[hPressedButtons]
    bit     BIT_UP,a
    call    nz,.menuup
    bit     BIT_DOWN,a
    call    nz,.menudown
    bit     BIT_A,a
    jr      nz,.menuselect
    bit     BIT_START,a
    jr      nz,.menuselect

    ; update cursor pos
    ld      hl,OAMBuffer + (36 * 4)
    ld      bc,4
    ld      a,[Title_MenuPos]
    ld      d,a
    add     a   ; x2
    ld      e,a
    add     a   ; x4
    add     a   ; x8
    add     e   ; x10
    add     d   ; x11
    add     94
    ld      [hl],a
    add     hl,bc
    ld      [hl],a
    add     hl,bc
    add     8
    ld      [hl],a
    add     hl,bc
    ld      [hl],a
    ; done
    rst     _WaitVBlank
    jr      TitleLoop

.menuup
    push    af
    ld      a,[Title_MenuPos]
    dec     a
    and     3
    ld      [Title_MenuPos],a
    play_sound_effect SFX_MenuCursor
    pop     af
    ret

.menudown
    push    af
    ld      a,[Title_MenuPos]
    inc     a
    and     3
    ld      [Title_MenuPos],a
    play_sound_effect SFX_MenuCursor
    pop     af
    ret

.menuselect
    play_sound_effect SFX_MenuSelect
    call    .exit
    ld      hl,.menuptrs
    ld      a,[Title_MenuPos]
    add     a
    ld      c,a
    ld      b,0
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    jp      hl

.menuptrs
    dw      GM_Game
    dw      GM_Help
    dw      GM_Options
    dw      GM_Credits

.exit
    ; init RNG seed
    ldh     a,[rDIV]
    ldh     [Math_RNGSeed],a
    ld      b,a
    ldh     a,[hGlobalTimer]
    xor     b
    ld      [Math_RNGSeed+1],a
    call    PalFadeOutWhite
:   rst     _WaitVBlank
    call    Pal_DoFade
    ld      a,[sys_FadeState]
    bit     0,a
    jr      nz,:-
    jp      LCDOff

section "Title screen GFX",romx

Title_BGTiles1:     incbin  "GFX/TitleBG.2bpp.wle"
Title_BGMap:        incbin  "GFX/TitleBG.map"
Title_BGAttr:       incbin  "GFX/TitleBG.atr"
Title_BGPalette:    incbin  "GFX/TitleBG.pal"

    incspr  titlespr

Title_BGOverlayPalette:
    rgb8    $80,$80,$80
    rgb8    $83,$2c,$00
    rgb8    $c2,$67,$0d
    rgb8    $e0,$b5,$58

    rgb8    $80,$80,$80
    rgb8    $10,$58,$27
    rgb8    $37,$88,$51
    rgb8    $5b,$b9,$92

    rgb8    $80,$80,$80
    rgb8    $03,$26,$5b
    rgb8    $1a,$50,$89
    rgb8    $68,$a8,$d1

    rgb8    $80,$80,$80
    rgb8    $71,$21,$42
    rgb8    $bd,$56,$8d
    rgb8    $fa,$98,$ce

Title_MenuArrowPalette:
    rgb8    $80,$80,$80
    rgb8    $00,$00,$00
    rgb8    $17,$23,$2f
    rgb8    $2f,$47,$5f

    rgb8    $80,$80,$80
    rgb8    $4b,$6f,$93
    rgb8    $77,$99,$bb
    rgb8    $cb,$eb,$ff

    rgb8    $80,$80,$80
    rgb8    $00,$00,$00
    rgb8    $2f,$47,$5f
    rgb8    $3b,$5b,$77

    rgb8    $80,$80,$80
    rgb8    $ab,$cf,$e7
    rgb8    $cb,$eb,$ff
    rgb8    $ff,$ff,$ff
