
section "Options RAM",wram0
Options_MenuPos:    db
Options_Music:      db
Options_SFX:        db

section "Options routines",rom0
GM_Options:
    call    LCDOff

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

    ld      a,bank(OptionsTiles)
    rst     _Bankswitch
    ld      a,1
    ldh     [rVBK],a
    ld      hl,OptionsTiles
    ld      de,_VRAM
    call    DecodeWLE

    xor     a
    ldh     [rVBK],a
    ld      hl,OptionsMap
    ld      de,_SCRN0 + (6 * SCRN_VX_B)
    lb      bc,SCRN_X_B,SCRN_Y_B-6
    call    LoadTilemapAttr

    ld      a,bank(LogoHeaderPalette)
    rst     _Bankswitch
    ; GBC palette
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

    xor     a
    ld      [Options_MenuPos],a

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a

OptionsLoop:
    call    Pal_DoFade

    ; menu controls
    ldh     a,[hPressedButtons]
    bit     BIT_B,a
    jp      nz,.exit
    bit     BIT_UP,a
    jr      nz,.up
    bit     BIT_DOWN,a
    jr      nz,.down
    bit     BIT_A,a
    jr      z,:+
    ld      a,[Options_MenuPos]
    and     a
    jr      z,.togglemusic
    dec     a
    jr      z,.togglesfx
    dec     a
    jr      z,.gotohighscores
    dec     a
    jp      z,.exit
    jr      :+
.togglemusic
    ld      a,[Options_Music]
    xor     1
    ld      [Options_Music],a
    jr      :+
.togglesfx
    ld      a,[Options_SFX]
    xor     1
    ld      [Options_SFX],a
    jr      :+
.gotohighscores
    call    PalFadeOutWhite
.fadeoutloop
    rst     _WaitVBlank
    call    Pal_DoFade
    ld      a,[sys_FadeState]
    bit     0,a
    jp      z,GM_HighScoreScreen
    jr      .fadeoutloop
.down
    ld      a,[Options_MenuPos]
    inc     a
    and     3
    ld      [Options_MenuPos],a
    jr      :+
.up
    ld      a,[Options_MenuPos]
    dec     a
    and     3
    ld      [Options_MenuPos],a
:
    ; redraw menu
    ld      a,bank(OptionsMenu_Music_Selected)
    rst     _Bankswitch
:   ; music
    ld      de,$9944
    ld      a,[Options_MenuPos]
    and     a
    jr      nz,.music_deselected
.music_selected
    ld      hl,OptionsMenu_Music_Selected
    call    Options_PrintString
    ld      de,$994d
    ld      a,[Options_Music]
    and     a
    call    nz,.on_selected
    call    z,.off_selected
    jr      :+
.music_deselected
    ld      hl,OptionsMenu_Music_Deselected
    call    Options_PrintString
    ld      de,$994d
    ld      a,[Options_Music]
    and     a
    call    nz,.on_deselected
    call    z,.off_deselected
:   ; sfx
    ld      de,$9984
    ld      a,[Options_MenuPos]
    dec     a
    jr      nz,.sfx_deselected
.sfx_selected
    ld      hl,OptionsMenu_SFX_Selected
    call    Options_PrintString
    ld      de,$998d
    ld      a,[Options_SFX]
    and     a
    call    nz,.on_selected
    call    z,.off_selected
    jr      :+
.sfx_deselected
    ld      hl,OptionsMenu_SFX_Deselected
    call    Options_PrintString
    ld      de,$998d
    ld      a,[Options_SFX]
    and     a
    call    nz,.on_deselected
    call    z,.off_deselected
:   ; high scores
    ld      de,$99c5
    ld      a,[Options_MenuPos]
    cp      2
    jr      nz,.highscores_deselected
.highscores_selected
    ld      hl,OptionsMenu_HighScores_Selected
    jr      :+
.highscores_deselected
    ld      hl,OptionsMenu_HighScores_Deselected
:   call    Options_PrintString
    ; exit
    ld      de,$9a08
    ld      a,[Options_MenuPos]
    cp      3
    jr      nz,.exit_deselected
.exit_selected
    ld      hl,OptionsMenu_Exit_Selected
    jr      :+
.exit_deselected
    ld      hl,OptionsMenu_Exit_Deselected
:   call    Options_PrintString
    ; end of menu redraw
    rst     _WaitVBlank
    jp      OptionsLoop
.exit
    call    PalFadeOutWhite
:   rst     _WaitVBlank
    call    Pal_DoFade
    ld      a,[sys_FadeState]
    bit     0,a
    jr      nz,:-
    jp      GM_Title

.on_selected
    push    af
    ld      hl,OptionsMenu_On_Selected
    call    Options_PrintString
    pop     af
    ret
.on_deselected
    push    af
    ld      hl,OptionsMenu_On_Deselected
    call    Options_PrintString
    pop     af
    ret
.off_selected:
    push    af
    ld      hl,OptionsMenu_Off_Selected
    call    Options_PrintString
    pop     af
    ret
.off_deselected:
    push    af
    ld      hl,OptionsMenu_Off_Deselected
    call    Options_PrintString
    pop     af
    ret

Options_PrintString:
:   ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,:-
    ld      a,[hl+]
    cp      -1
    ret     z
    ld      [de],a
    inc     e
    jr      :-

section "Options screen GFX",romx

OptionsTiles:   incbin  "GFX/optionsmenu.2bpp.wle"
OptionsMap:     incbin  "GFX/optionsmenu.map"

; $9944
OptionsMenu_Music_Selected:
    db  $07,$08,$09,$0a
    db  -1
OptionsMenu_Music_Deselected:
    db  $0d,$0e,$0f,$10
    db  -1

; $9984
OptionsMenu_SFX_Selected:
    db  $13,$14,$15
    db  -1
OptionsMenu_SFX_Deselected:
    db  $18,$19,$1a
    db  -1

; $99c5
OptionsMenu_HighScores_Selected:
    db  $1e,$1f,$20,$21,$22,$0a,$04,$23,$24,$25
    db  -1
OptionsMenu_HighScores_Deselected:
    db  $26,$27,$28,$29,$2a,$10,$2b,$2c,$2d,$2e
    db  -1

; $9a08
OptionsMenu_Exit_Selected:
    db  $2f,$30,$31,$32
    db  -1
OptionsMenu_Exit_Deselected:
    db  $33,$34,$35,$36
    db  -1

; $994D for music, $998D for SFX
OptionsMenu_On_Selected:
    db  $00,$0b,$0c
    db  -1
OptionsMenu_On_Deselected:
    db  $00,$11,$12
    db  -1

; same as OptionsMenu_On_Selected / OptionsMenu_On_Deselected
OptionsMenu_Off_Selected:
    db  $01,$16,$17
    db  -1
OptionsMenu_Off_Deselected:
    db  $1b,$1c,$1d
    db  -1
