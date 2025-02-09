section "Help screen routines",rom0
GM_Help:
    call    LCDOff
    ld      a,bank(HelpPalette)
    rst     _Bankswitch
    ld      hl,HelpPalette
    xor     a
    ld      [rVBK],a
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
    
    call    CopyPalettes
    
    call    PalFadeInWhite
    
    ld      hl,HelpTiles
    ld      de,_VRAM
    call    DecodeWLE
    assert  HelpTiles.end == HelpMap
;    ld      hl,HelpMap
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    xor     a
    ldh     [rVBK],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a
    
    ei

HelpLoop:
    call    Pal_DoFade
    rst     _WaitVBlank
    ldh     a,[hPressedButtons]
    and     BTN_A | BTN_B | BTN_START | BTN_SELECT
    jr      z,HelpLoop
.exit
    call    PalFadeOutWhite
:   rst     _WaitVBlank
    call    Pal_DoFade
    ld      a,[sys_FadeState]
    bit     0,a
    jr      nz,:-
    jp      GM_Title
    
section "Help screen GFX",romx

HelpTiles:      incbin  "GFX/help.2bpp.wle"
.end
HelpMap:        incbin  "GFX/help.map"
HelpPalette:    incbin  "GFX/help.pal"