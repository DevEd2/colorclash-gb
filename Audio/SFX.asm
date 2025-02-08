def SFX_BIT_CH1 equ 0
def SFX_BIT_CH2 equ 1
def SFX_BIT_CH3 equ 2
def SFX_BIT_CH4 equ 3
def SFX_CH1 equ 1
def SFX_CH2 equ 2
def SFX_CH3 equ 4
def SFX_CH4 equ 8

section "SFX RAM",wram0

SFX_Playing:    db  ; P.....CH   CH = channel   P = playing
SFX_Bank:       db
SFX_Pointer:    dw
SFX_Priority:   db  ; any request to play a SFX with a higher priority value than this will be ignored
SFX_Timer:      db

section "SFX routines",rom0

PlaySFX:
    push    af
    ld      a,[Options_SFX]
    and     a
    jr      z,.skip
    push    bc
    push    de
    push    hl
    rst     _Bankswitch
    ld      [SFX_Bank],a
    ld      a,[hl+]
    ld      b,a
    ld      a,[SFX_Priority]
    cp      b
    jr      c,.skip2
    ld      a,[hl+]
    or      %10000000
    ld      [SFX_Playing],a
    ld      a,l
    ld      [SFX_Pointer],a
    ld      a,h
    ld      [SFX_Pointer+1],a
    ld      a,1
    ld      [SFX_Timer],a
.skip2
    pop     hl
    pop     de
    pop     bc
.skip
    pop     af
    ret

UpdateSFX:
:   ld      a,[SFX_Playing]
    bit     7,a
    ret     z
    ld      hl,SFX_Timer
    dec     [hl]
    ret     nz

    ld      a,[SFX_Bank]
    rst     _Bankswitch
    ld      hl,SFX_Pointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      a,[hl+]
    ld      e,a
    bit     7,e
    jr      z,:+
    xor     a
    ld      [SFX_Playing],a
    dec     a
    ld      [SFX_Priority],a
    ld      [GBM_ForceWaveReload],a
    ret

:   ld      a,[SFX_Playing]
    and     7
    cp      SFX_CH1
    jr      z,.ch1
    cp      SFX_CH2
    jr      z,.ch2
    cp      SFX_CH3
    jr      z,.ch3
.ch4
    ld      c,$1f
    jr      :+
.ch3
    ld      c,$1a
    jr      :+
.ch2
    ld      c,$15
    jr      :+
.ch1
    ld      c,$10

:   ld      a,1
    ld      [SFX_Timer],a
    bit     6,e
    jr      z,:+
    ld      a,[hl+]
    ld      [SFX_Timer],a
:   bit     5,e
    jr      z,:+
    call    SFX_LoadWave
:   rr      e
    call    c,.nrx0
    rr      e
    call    c,.nrx1
    rr      e
    call    c,.nrx2
    rr      e
    call    c,.nrx3
    rr      e
    call    c,.nrx4
    ld      a,l
    ld      [SFX_Pointer],a
    ld      a,h
    ld      [SFX_Pointer+1],a
    ret
.nrx0
    ld      a,[hl+]
    ldh     [c],a
    ret
.nrx1
    inc     c
    ld      a,[hl+]
    ldh     [c],a
    dec     c
    ret
.nrx2
    push    bc
    inc     c
    inc     c
    ld      a,[hl+]
    ldh     [c],a
    pop     bc
    ret
.nrx3
    push    bc
    inc     c
    inc     c
    inc     c
    ld      a,[hl+]
    ldh     [c],a
    pop     bc
    ret
.nrx4
    push    bc
    inc     c
    inc     c
    inc     c
    inc     c
    ld      a,[hl+]
    ldh     [c],a
    pop     bc
    ret

SFX_LoadWave:
    push    bc
    ld      a,%10111011
    ldh     [rNR51],a
    xor     a
    ldh     [rNR30],a
    for     n,16
        ld      a,[hl+]
        ldh     [$ff30+n],a
    endr
    ld      a,%11111111
    ldh     [rNR51],a
    ld      a,$80
    ldh     [rNR30],a
    pop     bc
    ret

section "SFX data",romx

; bit 7: stop
; bit 6: timer
; bit 5: load new wave
; bit 4: NRx4
; bit 3: NRx3
; bit 2: NRx2
; bit 1: NRx1
; bit 0: NRx0

SFX_MenuCursor:
    db  1,SFX_CH1
    db  %00_0_11110
    db  $bf,$f0
    dw  $8790
    db  %00_0_10100
    db  $c0
    db  $87
    db  %00_0_10100
    db  $90
    db  $87
    db  %00_0_10100
    db  $60
    db  $87
    db  %00_0_10100
    db  $30
    db  $87
    db  %00_0_10100
    db  $00
    db  $87
    db  %10000000

SFX_MenuSelect:
    db  0,SFX_CH1
    db  %01_0_11110
    db  3
    db  $3f,$f0
    dw  $8642
    db  %01_0_11110
    db  3
    db  $7f,$f0
    dw  $8721
    db  %00_0_11110
    db  $3f,$f0
    dw  $8790
    db  %00_0_10100
    db  $d0
    db  $87
    db  %00_0_10100
    db  $b0
    db  $87
    db  %00_0_10100
    db  $90
    db  $87
    db  %00_0_10100
    db  $90
    db  $87
    db  %00_0_10100
    db  $70
    db  $87
    db  %00_0_10100
    db  $50
    db  $87
    db  %00_0_10100
    db  $30
    db  $87
    db  %00_0_10100
    db  $10
    db  $87
    db  %00_0_10100
    db  $00
    db  $87
    db  %10000000

SFX_Spring:
    db  0,SFX_CH1
    db  %01_0_11110
    db  4
    db  $bf,$f0
    dw  $8483
    db  %01_0_11110
    db  4
    db  $bf,$f0
    dw  $8107
    db  %00010100
    db  $00
    db  $80
    db  %10000000

SFX_Pause:
    db  0,SFX_CH3
    db  %01_1_11100
    db  2
    db  $01,$23,$45,$66,$76,$65,$43,$21,$0f,$ed,$cb,$aa,$9a,$ab,$cd,$ef
    db  $20
    dw  $483 | 1<<15
    db  %01_0_00100
    db  2
    db  $40
    db  %01_0_11100
    db  2
    db  $20
    dw  $642
    db  %01_0_00100
    db  2
    db  $40
    db  %01_0_00100
    db  4
    db  $60
    db  %00_0_00100
    db  0
    db  %10_0_00000

SFX_BackToMenu:
    db  0,SFX_CH3
    db  %01_1_11100
    db  1
    db  $01,$23,$45,$66,$76,$65,$43,$21,$0f,$ed,$cb,$aa,$9a,$ab,$cd,$ef
    db  $20
    dw  $693 | 1<<15
    db  %01_0_11000
    db  1
    dw  $02c
    db  %01_0_11000
    db  1
    dw  $6cd
    db  %01_0_01000
    db  1
    db  low($6d6)
    db  %01_0_01100
    db  1
    db  $40
    db  low($6df)
    db  %01_0_01000
    db  1
    db  low($6e7)
    db  %01_0_01100
    db  1
    db  $60
    db  low($6ef)
    db  %01_0_01000
    db  1
    db  low($6f7)
    db  %10_0_00100
    db  0