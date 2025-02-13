
section "Logo RAM",wram0
LogoTime:   db

def LOGO_TIME = 4 * 60  ; 4 seconds

section "Logo routines",rom0
GM_Logo:
Logo_Copyright:
    call    LCDOff
    ld      a,bank(CopyrightPalette)
    rst     _Bankswitch
    ld      hl,CopyrightPalette
    xor     a
    call    LoadPal
    call    CopyPalettes
    call    PalFadeInWhite
    ld      hl,CopyrightTiles
    ld      de,_VRAM
    call    DecodeWLE
    ld      a,1
    ldh     [rVBK],a
    ld      de,_VRAM
    call    DecodeWLE
    assert  CopyrightTiles.end == CopyrightMap
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    xor     a
    ldh     [rVBK],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a
    
    ld      hl,LogoTime
    ld      [hl],LOGO_TIME

    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    call    LogoLoop
    ; fall through

Logo_Splash1:
    call    LCDOff
    ld      hl,LogoPalette
    xor     a
    call    LoadPal
    ld      a,1
    call    LoadPal
    ld      a,2
    call    LoadPal
    if      BUILD_LOGO == 1
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
    endc

    call    CopyPalettes
    
    call    PalFadeInWhite
    
    ld      hl,LogoTiles
    ld      de,_VRAM
    call    DecodeWLE
    assert  LogoTiles.end == LogoMap
;    ld      hl,LogoMap
    if      BUILD_LOGO == 0
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    else
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemap
    ld      a,1
    ldh     [rVBK],a
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemap
    xor     a
    ldh     [rVBK],a
    endc
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a
    
    ld      hl,LogoTime
    ld      [hl],LOGO_TIME

    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    call    LogoLoop
    ; fall through
    
Logo_Splash2:  
    call    LCDOff
    ld      a,bank(DevEdSplashPalette)
    rst     _Bankswitch
    ld      hl,DevEdSplashPalette
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
    call    CopyPalettes
    call    PalFadeInWhite
    ld      hl,DevEdSplashTiles
    ld      de,_VRAM
    call    DecodeWLE
    assert  DevEdSplashTiles.end == DevEdSplashMap
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,SCRN_Y_B
    call    LoadTilemapAttr
    xor     a
    ldh     [rVBK],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a
    
    ld      hl,LogoTime
    ld      [hl],LOGO_TIME

    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    call    LogoLoop
    ; fall through
    
    jp      GM_Title

LogoLoop:
    call    Pal_DoFade
    ld      hl,LogoTime
    dec     [hl]
    jr      z,.exit
    halt
    jr      LogoLoop
.exit
    call    PalFadeOutWhite
    :   halt
        call    Pal_DoFade
        ld      a,[sys_FadeState]
        bit     0,a
        jr      nz,:-
    ret

section "Logo screen GFX",romx

if BUILD_LOGO == 0
LogoTiles:          incbin  "GFX/KarmaLogoGBC.2bpp.wle"
.end
LogoMap:            incbin  "GFX/KarmaLogoGBC.map"
LogoPalette:        incbin  "GFX/KarmaLogoGBC.pal"
CopyrightTiles:     incbin  "GFX/copyright_karma.2bpp.wle"
                    incbin  "GFX/copyright_karma_b.2bpp.wle"
.end
CopyrightMap:       incbin  "GFX/copyright_karma.map"
CopyrightPalette:   incbin  "GFX/copyright_karma.pal"
else
LogoTiles:          incbin  "GFX/RevivalLogoGBC.2bpp.wle"
.end
LogoMap:            incbin  "GFX/RevivalLogoGBC.map"
LogoAttr:           incbin  "GFX/RevivalLogoGBC.atr"
LogoPalette:        incbin  "GFX/RevivalLogoGBC.pal"
CopyrightTiles:     incbin  "GFX/copyright_revival.2bpp.wle"
                    incbin  "GFX/copyright_revival_b.2bpp.wle"
.end
CopyrightMap:       incbin  "GFX/copyright_revival.map"
CopyrightPalette:   incbin  "GFX/copyright_revival.pal"
endc
DevEdSplashTiles:   incbin  "GFX/DevEdSplash.2bpp.wle"
.end
DevEdSplashMap:     incbin  "GFX/DevEdSplash.map"
DevEdSplashPalette: incbin  "GFX/DevEdSplash.pal"