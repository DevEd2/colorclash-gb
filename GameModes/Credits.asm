section "Credits RAM",wram0

def CREDITS_SLIDE_TIME = 60 * 2

Credits_CurrentSlide:   db
Credits_Timer:          db
Credits_State:          db  ; 0 = slide in, 1 = wait for delay, 2 = slide out

section "Credits routines",rom0

GM_Credits:
    call    LCDOff
    ; clear background map2
    xor     a
    ldh     [rVBK],a
    ld      hl,_SCRN0
    ld      bc,_SCRN1-_SCRN0
    push    hl
    push    bc
    ld      e,0
    call    MemFill
    ld      a,1
    ldh     [rVBK],a
    pop     bc
    pop     hl
    ld      e,$f
    call    MemFill
    
    ; clear background map
    xor     a
    ldh     [rVBK],a
    ld      hl,_SCRN1
    ld      bc,_SCRN1-_SCRN0
    push    hl
    push    bc
    ld      e,-1
    call    MemFill
    ld      a,1
    ldh     [rVBK],a
    pop     bc
    pop     hl
    ld      e,$f
    call    MemFill
    
    ; load header GFX
    xor     a
    ldh     [rVBK],a
    ld      a,bank(LogoHeaderTiles)
    rst     _Bankswitch
    ld      hl,LogoHeaderTiles
    ld      de,_VRAM
    call    DecodeWLE
    ld      hl,LogoHeaderMap
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,6
    call    LoadTilemapAttr
    
    ; load credits text
    ld      a,1
    ldh     [rVBK],a
    ld      a,bank(Credits_Header)
    rst     _Bankswitch
    ld      hl,Credits_Header
    ld      de,_VRAM
    call    DecodeWLE
    assert  Credits_Header.end == Credits_OriginalGame
    call    DecodeWLE
    assert  Credits_OriginalGame.end == Credits_GBCVersion
    call    DecodeWLE
    assert  Credits_GBCVersion.end == Credits_Music
    call    DecodeWLE
    assert  Credits_Music.end == Credits_Graphics
    call    DecodeWLE
    assert  Credits_Graphics.end == Credits_SpecialThanks
    call    DecodeWLE
    assert  Credits_SpecialThanks.end == Credits_Copyright
    call    DecodeWLE
    xor     a
    ldh     [rVBK],a
    
    ; load palettes
    ld      a,bank(LogoHeaderPalette)
    rst     _Bankswitch
    ld      hl,LogoHeaderPalette
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
    ld      hl,FontPalette
    ld      a,7
    call    LoadPal
    call    CopyPalettes
    call    PalFadeInWhite
    
    ; init stuff
    xor     a
    ld      [Credits_CurrentSlide],a
    ld      [Credits_Timer],a
    ld      [Credits_State],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BLK01 | LCDCF_BG9800 | LCDCF_WINON | LCDCF_WIN9C00
    ldh     [rLCDC],a
    
    ld      a,144
    ldh     [rWY],a
    ld      a,35
    ldh     [rWX],a
    ei
    
    ld      hl,0
    call    Credits_DrawSlide

CreditsLoop:
    call    Pal_DoFade
    
    ld      a,[Credits_State]
    and     a
    jr      z,Credits_SlideIn
    dec     a
    jr      z,Credits_Wait
Credits_SlideOut:
    ld      a,[Credits_Timer]
    dec     a
    ld      [Credits_Timer],a
    jr      z,Credits_NextSlide
    ld      c,a
    ld      b,0
    ld      hl,CreditsScrollTable
    add     hl,bc
    ld      a,[hl]
    ldh     [rWY],a
    rst     _WaitVBlank
    jr      CreditsLoop
Credits_NextSlide:
    ld      a,[Credits_CurrentSlide]
    inc     a
    cp      CREDITS_NUM_SLIDES
    jr      nz,:+
    xor     a
:   ld      [Credits_CurrentSlide],a
    ld      l,a
    ld      h,0
    call    Credits_DrawSlide
    xor     a
    ld      [Credits_State],a
    ld      [Credits_Timer],a
    rst     _WaitVBlank
    jr      CreditsLoop
Credits_SlideIn:
    ld      a,[Credits_Timer]
    inc     a
    ld      [Credits_Timer],a
    cp      CreditsScrollTable.end-CreditsScrollTable
    jr      z,Credits_ToWait
    ld      c,a
    ld      b,0
    ld      hl,CreditsScrollTable
    add     hl,bc
    ld      a,[hl]
    ldh     [rWY],a
    rst     _WaitVBlank
    jr      CreditsLoop
Credits_ToWait:
    ld      a,CREDITS_SLIDE_TIME
    ld      [Credits_Timer],a
    ld      a,1
    ld      [Credits_State],a
    rst     _WaitVBlank
    jr      CreditsLoop
Credits_Wait:
    ld      hl,Credits_Timer
    dec     [hl]
    jr      z,Credits_ToSlideOut
    rst     _WaitVBlank
    jr      CreditsLoop
Credits_ToSlideOut:
    ld      a,CreditsScrollTable.end-CreditsScrollTable
    ld      [Credits_Timer],a
    ld      a,2
    ld      [Credits_State],a
    rst     _WaitVBlank
    jr      CreditsLoop

; INPUT: hl = slide number
Credits_DrawSlide:
    ld      a,bank(Credits_HeaderMap)
    rst     _Bankswitch
    add     hl,hl
    ld      bc,CreditsSlides
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      de,_SCRN1
    lb      bc,13,4
    jp      LoadTilemapAttrSafe
 
CreditsScrollTable:
    db      144
    db      144,141,138,135,132,129,126,124
    db      121,118,116,113,110,108,105,103
    db      100, 98, 96, 93, 91, 89, 87, 85
    db       83, 81, 79, 78, 76, 74, 73, 71
    db       70, 68, 67, 66, 65, 63, 62, 62
    db       61, 60, 59, 58, 58, 57, 57, 57
    db       56
    db       56
.end

CreditsSlides:
    dw      Credits_HeaderMap
    dw      Credits_OriginalGameMap
    dw      Credits_GBCVersionMap
    dw      Credits_MusicMap
    dw      Credits_GraphicsMap
    dw      Credits_SpecialThanksMap
    dw      Credits_CopyrightMap
def CREDITS_NUM_SLIDES = (@-CreditsSlides)/2
 
section "Credits GFX",romx

Credits_Header:             incbin  "GFX/Credits/credits.2bpp.wle"
.end
Credits_OriginalGame:       incbin  "GFX/Credits/originalgame.2bpp.wle"
.end
Credits_GBCVersion:         incbin  "GFX/Credits/gbcversion.2bpp.wle"
.end
Credits_Music:              incbin  "GFX/Credits/musicby.2bpp.wle"
.end
Credits_Graphics:           incbin  "GFX/Credits/graphicsby.2bpp.wle"
.end
Credits_SpecialThanks:      incbin  "GFX/Credits/specialthanks.2bpp.wle"
.end
Credits_Copyright:          incbin  "GFX/Credits/copyright.2bpp.wle"
.end

Credits_HeaderMap:          incbin  "GFX/Credits/credits.map"
Credits_OriginalGameMap:    incbin  "GFX/Credits/originalgame.map"
Credits_GBCVersionMap:      incbin  "GFX/Credits/gbcversion.map"
Credits_MusicMap:           incbin  "GFX/Credits/musicby.map"
Credits_GraphicsMap:        incbin  "GFX/Credits/graphicsby.map"
Credits_SpecialThanksMap:   incbin  "GFX/Credits/specialthanks.map"
Credits_CopyrightMap:       incbin  "GFX/Credits/copyright.map"