
section "High score RAM",wram0
Game_HighScores:        ds  (5+4) * 5
.end
Game_ScoreTemp:         ds  (5+4)
ScoreEntryBuffer:       ds  5
ScoreEntryCursorPos:    db

section "High score screen routines",rom0
GM_HighScoreScreen:
    call    LCDOff
    ; clear background map
    xor     a
    ldh     [rVBK],a
    ld      hl,_SCRN0
    ld      bc,_SCRN1-_SCRN0
    ld      e," "
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
    ; load font
    ld      a,1
    ldh     [rVBK],a
    ld      hl,Font
    ld      de,_VRAM
    call    DecodeWLE
    xor     a
    ldh     [rVBK],a
    
    ; load palettes
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
    
    ld      hl,str_HighScores
    ld      de,$98c5
    call    Options_PrintString
    call    RedrawHighScores
    
    ld      a,[Game_OverMan]
    and     a
    call    nz,CheckForNewHighScore
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a
    ei
HighScoreLoop:
    call    Pal_DoFade
    
    ldh     a,[hPressedButtons]
    bit     BIT_B,a
    jr      nz,.exit
    
    rst     _WaitVBlank
    jr      HighScoreLoop
.exit
    call    PalFadeOutWhite
:   rst     _WaitVBlank
    call    Pal_DoFade
    ld      a,[sys_FadeState]
    bit     0,a
    jr      nz,:-
    ld      a,[Game_OverMan]
    and     a
    jp      z,GM_Options
    xor     a
    ld      [Game_OverMan],a
    jp      GM_Title
    
RedrawHighScores:
    ld      hl,Game_HighScores
    ld      de,$9901
    lb      bc,5,5
.loop
    push    de
:   ld      a,[hl+]
    ld      [de],a
    inc     e
    dec     b
    jr      nz,:-
    ld      a,e
    add     9
    ld      e,a
    rept    4
    ld      a,[hl+]
    add     $1e
    ld      [de],a
    inc     e
    endr
    pop     de
    ld      a,e
    add     $40
    ld      e,a
    jr      nc,:+
    inc     d
:   ld      b,5
    dec     c
    jr      nz,.loop
    ret

; Compare player's score with high score table
; If player score > any of these, return pointer of score table entry
CheckForNewHighScore:
    lb      bc,5,0
    xor     a
    ld      hl,Game_HighScores+5
.loop
    push    bc
    push    hl
    ld      a,[hl+]
    swap    a
    ld      d,a
    ld      a,[hl+]
    or      d
    ld      d,a
    ld      a,[hl+]
    swap    a
    ld      e,a
    ld      a,[hl+]
    or      e
    ld      e,a
    
    ld      hl,Game_Score
    ld      a,[hl+]
    swap    a
    ld      b,a
    ld      a,[hl+]
    or      b
    ld      b,a
    ld      a,[hl+]
    swap    a
    ld      c,a
    ld      a,[hl+]
    or      c
    pop     hl
    call    Math_Compare16
    jr      nc,.gotscore
    
    ld      a,l
    add     4+5
    ld      l,a
    jr      nc,:+
    inc     h
:   pop     bc
    inc     c
    dec     b
    jr      nz,.loop
    ret
.gotscore
    pop     bc
    ld      a,l
    sub     5
    ld      l,a
    jr      nc,:+
    dec     h
:   ld      de,$98c3
    push    hl
    ld      hl,str_NewHighScore
    call    Options_PrintString
    
    ; shift remaining entries down
    ; first, fill the scratch buffer
    pop     hl
    push    hl
    ld      de,Game_ScoreTemp
    ld      b,5+4
    call    MemCopySmall
    pop     hl
    ; get pointer to next entry
    push    hl
    ld      de,5+4
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    ld      b,5+4
    ld      a,c
    ldh     [hTemp],a
    ld      a,4
    sub     c
    ld      c,a
    jr      z,.noshift
.shiftloop
    push    de
    ld      hl,Game_ScoreTemp
:   ld      a,[hl]
    push    af
    ld      a,[de]
    ld      [hl+],a
    pop     af
    ld      [de],a
    inc     de
    dec     b
    jr      nz,:-
    pop     hl
    ld      b,5+4
    dec     c
    jr      nz,.shiftloop
.noshift
    ; add high score to list
    ldh     a,[hTemp]
    ld      l,a
    ld      c,l
    ld      h,0
    ld      b,h
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,bc   ; x9
    ld      bc,Game_HighScores
    add     hl,bc
    ld      [hl],"T"
    inc     hl
    ld      [hl],"E"
    inc     hl
    ld      [hl],"S"
    inc     hl
    ld      [hl],"T"
    inc     hl
    ld      [hl]," "
    inc     hl
    ld      a,[Game_Score]
    ld      [hl+],a
    ld      a,[Game_Score+1]
    ld      [hl+],a
    ld      a,[Game_Score+2]
    ld      [hl+],a
    ld      a,[Game_Score+3]
    ld      [hl],a
    
    call    RedrawHighScores
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_BG9800
    ldh     [rLCDC],a
    ei

HighScoreEntryLoop:
    call    Pal_DoFade
    rst     _WaitVBlank
    
    ; draw score buffer
    ld      hl,ScoreEntryBuffer
    
    ldh     a,[hPressedButtons]
    
    jr      HighScoreEntryLoop

HighScores_Default:
    db  "KARMA",0,5,0,0
    db  "KARMA",0,4,0,0
    db  "KARMA",0,3,0,0
    db  "KARMA",0,2,0,0
    db  "KARMA",0,1,0,0

str_HighScores:
    db  "HIGH SCORES",-1
str_NewHighScore:
    db  "NEW HIGH SCORE!",-1