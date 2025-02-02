; ================================================================
; General purpose math library
; Copyright (c) 2023 DevEd
;
; Permission is hereby granted, free of charge, to any person obtaining
; a copy of this software and associated documentation files (the
; “Software”), to deal in the Software without restriction, including
; without limitation the rights to use, copy, modify, merge, publish,
; distribute, sublicense, and/or sell copies of the Software, and to
; permit persons to whom the Software is furnished to do so, subject to
; the following conditions:
;
; The above copyright notice and this permission notice shall be
; included in all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
; IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
; CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
; TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
; ======================================================================

def INC_MUL     = 1 ; multiplication
def INC_DIV     = 1 ; division
def INC_POW     = 1 ; square (NYI)
def INC_SQRT    = 1 ; square root
def INC_SINCOS  = 1 ; sine + cosine
def INC_ATAN2   = 1 ; 2-argument arctangent
def INC_RAND    = 1 ; 32-bit PRNG
def INC_LERP    = 1 ; linear interpolation (NYI)
def INC_HEX2BCD = 1 ; hexadecimal to BCD

macro neg
    cpl
    inc     a
endm

if INC_RAND
section "RNG seeds",hram
Math_RNGSeed1:  ds  2
Math_RNGSeed2:  ds  2
endc

section "Math routines",rom0

if INC_MUL
; Multiply a 16-bit number by an 8 bit number.
; INPUT:    hl = multiplicand
;           b  = multiplier
; OUTPUT:   hl = result
; DESTROYS: af bc de hl
Math_Mul16:
    call    Math_Abs16
    push    af
    ld      e,b
    ld      d,0
:   add     hl,de
    dec     b
    jr      nz,:-
    pop     af
    ret     nz
    jp      Math_Neg16
endc

if INC_DIV
; Divide a 16-bit number by an 8-bit number.
; INPUT:    hl = dividend
;            b = divisor
; OUTPUT:   hl = result
;            a = remainder
; DESTROYS: af -c -- hl
Math_Div16:
    ld      a,b
    and     a
    jr      z,.error
    ld      c,16
    xor     a
.loop
    add     hl,hl
    rla
    cp      b
    jr      c,:+
    inc     l
    sub     b
:   dec     c
    jr      nz,.loop
    ret
.error
    push    af
    ld      a,ERR_DIV_ZERO
    ldh     [hErrType],a
    pop     af
    rst     Error
endc

if INC_POW
; Raise a number to the second power.
; INPUT:    hl = number
; OUTPUT:   hl = result
; DESTROYS: ?? ?? ?? ??
Math_Square:
    ; TODO
    ret
endc

if INC_SQRT
; Get the square root A.
; INPUT:     a = number
; OUTPUT:   hl = result (Q7.8)
; DESTROYS: -- bc -- hl
Math_SquareRoot:
    ld      c,a
    ld      b,0
    add     hl,bc
    add     hl,bc
    ld      b,h
    ld      c,l
    ld      hl,Math_SquareRootTable
    jp      Math_LUT16
endc

if INC_SINCOS
; Calculate the sine and cosine of an 8-bit angle (0 = 0 deg, 256 = 360 deg)
; INPUT:     a = angle
; OUTPUT:   hl = sine (Q7.8)
;           de = cosine (Q7.8)
; DESTROYS: af bc de hl
Math_SinCos:   
    ld      c,a
    ld      b,0
    ld      hl,Math_SineTable
    call    Math_LUT16
    push    hl
    ld      hl,Math_CosineTable
    call    Math_LUT16
    ld      d,h
    ld      e,l
    pop     hl
    ret
endc

; Just calculate the sine of an 8-bit angle
; INPUT:     a = angle
; OUTPUT:   hl = sine (Q7.8)
; DESTROYS:
Math_Sine:
    ld      c,a
    ld      b,0
    ld      hl,Math_SineTable
    jp      Math_LUT16

; Just calculate the cosine of an 8-bit angle
; INPUT:     a = angle
; OUTPUT:   hl = sine (Q7.8)
; DESTROYS:
Math_Cosine:
    ld      c,a
    ld      b,0
    ld      hl,Math_CosineTable
    jp      Math_LUT16

if INC_HEX2BCD
Math_Hex2BCD8:
    ld      c,a
    ld      b,8
    xor     a
:   sla     c
    adc     a
    daa
    dec     b
    jr      nz,:-
    ret
endc

if INC_ATAN2
; ================================================================
; 8-bit atan2
; Adapted from https://www.msx.org/forum/msx-talk/development/8-bit-atan2
;
; Calculate the angle, in a 256-degree circle.
; The trick is to use logarithmic division to get the y/x ratio and
; integrate the power function into the atan table.
;
;   input
;   B = x, C = y    in -128,127
;
;   output
;   A = angle       in 0-255
;
;      |
;  q1  |  q0
;------+-------
;  q3  |  q2
;      |
; ================================================================

Math_ATan2:
    ld      de,$8000
    ld      a,c
    add     a,d
    rl      e           ; y-
    ld      a,b
    add     a,d
    rl      e           ; x-
    dec     e
    jr      z,.q1
    dec     e
    jr      z,.q2
    dec     e
    jr      z,.q3
.q0 ld      h,Math_Log2Table / 256
    ld      l,b
    ld      a,[hl]      ; 32*log2(x)
    ld      l,c
    sub     [hl]        ; 32*log2(x/y)
    jr      nc,.1       ; |x|>|y|
    neg                 ; |x|<|y|   A = 32*log2(y/x)
.1  ld      l,a
    ld      h,Math_ATanTable / 256
    ld      a,[hl]
    ret     c           ; |x|<|y|
    neg
    and     $3f         ; |x|>|y|
    ret
.q1 ld      a,b
    neg
    ld      b,a
    call    .q0
    neg
    and     $7F
    ret

.q2 ld      a,c
    neg
    ld      c,a
    call    .q0
    neg
    ret

.q3 ld      a,b
    neg
    ld      b,a
    ld      a,c
    neg
    ld      c,a
    call    .q0
    add     a,128
    ret
endc

if INC_RAND

def RNG_SEED_1  = 31416
def RNG_SEED_2  = 52197

Math_InitRandSeed:
    ld      hl,Math_RNGSeed1
    ld      a,low(RNG_SEED_1)
    ld      [hl+],a
    ld      a,high(RNG_SEED_1)
    ld      [hl+],a
    ld      a,low(RNG_SEED_2)
    ld      [hl+],a
    ld      a,high(RNG_SEED_2)
    ld      [hl+],a
    ret

; Returns a random number in HL.
; adapted from https://learn.cemetech.net/index.php/Z80:Math_Routines#rand.3B_very_fast
Math_Random:
    push    af
    ld      hl,Math_RNGSeed1
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ld      b,h
    ld      c,l
    add     hl,hl
    add     hl,hl
    inc     l
    add     hl,bc
    ld      a,l
    ldh     [Math_RNGSeed1],a
    ld      a,h
    ldh     [Math_RNGSeed1+1],a
    ld      hl,Math_RNGSeed2
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    add     hl,hl
    pop     af
    sbc     a
    and     %00101101
    xor     l
    ldh     [Math_RNGSeed2],a
    ld      a,h
    ldh     [Math_RNGSeed2+1],a
    ld      l,a
    add     hl,bc
    ret

; Returns a random number from 0 to a given 8-bit integer.
; INPUT:    a = range + 1
; OUTPUT:   a = result
; DESTROYS: bc, hl
Math_RandRange:
    push    af
    call    Math_Random
    push    hl
    ld      h,d
    ld      l,e
    pop     de
    pop     af
    ld      hl,0
    ld      b,h
    add     a
    jr      nc,:+  
    ld      h,d
    ld      l,e
:   add     hl,hl
    rla
    jr      nc,:+
    add     hl,de
    adc     b
:   add     hl,hl
    rla
    jr      nc,:+
    add     hl,de
    adc     b
:   add     hl,hl
    rla
    jr      nc,:+
    add     hl,de
    adc     b
:   add     hl,hl
    rla
    jr      nc,:+
    add     hl,de
    adc     b
:   add     hl,hl
    rla
    jr      nc,:+
    add     hl,de
    adc     b
:   add     hl,hl
    rla
    jr      nc,:+
    add     hl,de
    adc     b
:   add     hl,hl
    rla
    ret     nc
    add     hl,de
    adc     a,b
    ret
endc

; Compare BC to DE.
; INPUT:    bc = value 1
;           de = value 2
; OUTPUT:   zero = set if equal
;           carry = set if bc < de
; DESTROYS: a
Math_Compare16:
    ld  a,b
    cp  d
    ret nz
    ld  a,c
    cp  e
    ret

; Negate a 16-bit number in HL.
; INPUT:    hl = num
; OUTPUT:   hl = -num
; DESTROYS: af -- de hl
Math_Neg16:
    ld      a,l
    cpl
    ld      l,a
    ld      a,h
    cpl
    ld      h,a
    inc     hl
    ret

; Get the absolute value of a signed 8-bit number.
; INPUT:     a = number
; OUTPUT:    a = result
Math_Abs8:
    bit     7,a
    ret     z
    cpl
    inc     a
    ret

; Get the absolute value of a Q7.8 number.
; INPUT:    hl = number
; OUTPUT:   hl = result
Math_Abs16:
    bit     7,h
    ret     z
    jr      Math_Neg16

; 8-bit lookup table stub
; INPUT:    hl = LUT pointer
;            c = offset
Math_LUT8:
    ld      b,0
    add     hl,bc
    ld      a,[hl]
    ret

; 16-bit lookup table stub
; INPUT:    hl = LUT pointer
;           bc = offset
; OUTPUT:   hl = result
; DESTROYS: af -- -- hl
Math_LUT16:
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    ret

if INC_SINCOS
Math_SineTable:
    dw      $0000,$0006,$000c,$0012,$0019,$001f,$0025,$002b
    dw      $0031,$0038,$003e,$0044,$004a,$0050,$0056,$005c
    dw      $0061,$0067,$006d,$0073,$0078,$007e,$0083,$0088
    dw      $008e,$0093,$0098,$009d,$00a2,$00a7,$00ab,$00b0
    dw      $00b5,$00b9,$00bd,$00c1,$00c5,$00c9,$00cd,$00d1
    dw      $00d4,$00d8,$00db,$00de,$00e1,$00e4,$00e7,$00ea
    dw      $00ec,$00ee,$00f1,$00f3,$00f4,$00f6,$00f8,$00f9
    dw      $00fb,$00fc,$00fd,$00fe,$00fe,$00ff,$00ff,$00ff
    ; continues through Math_CosineTable
Math_CosineTable:
    dw      $0100,$00ff,$00ff,$00ff,$00fe,$00fe,$00fd,$00fc
    dw      $00fb,$00f9,$00f8,$00f6,$00f4,$00f3,$00f1,$00ee
    dw      $00ec,$00ea,$00e7,$00e4,$00e1,$00de,$00db,$00d8
    dw      $00d4,$00d1,$00cd,$00c9,$00c5,$00c1,$00bd,$00b9
    dw      $00b5,$00b0,$00ab,$00a7,$00a2,$009d,$0098,$0093
    dw      $008e,$0088,$0083,$007e,$0078,$0073,$006d,$0067
    dw      $0061,$005c,$0056,$0050,$004a,$0044,$003e,$0038
    dw      $0031,$002b,$0025,$001f,$0019,$0012,$000c,$0006
    dw      $0000,$fffa,$fff4,$ffee,$ffe7,$ffe1,$ffdb,$ffd5
    dw      $ffcf,$ffc8,$ffc2,$ffbc,$ffb6,$ffb0,$ffaa,$ffa4
    dw      $ff9f,$ff99,$ff93,$ff8d,$ff88,$ff82,$ff7d,$ff78
    dw      $ff72,$ff6d,$ff68,$ff63,$ff5e,$ff59,$ff55,$ff50
    dw      $ff4b,$ff47,$ff43,$ff3f,$ff3b,$ff37,$ff33,$ff2f
    dw      $ff2c,$ff28,$ff25,$ff22,$ff1f,$ff1c,$ff19,$ff16
    dw      $ff14,$ff12,$ff0f,$ff0d,$ff0c,$ff0a,$ff08,$ff07
    dw      $ff05,$ff04,$ff03,$ff02,$ff02,$ff01,$ff01,$ff01
    dw      $ff00,$ff01,$ff01,$ff01,$ff02,$ff02,$ff03,$ff04
    dw      $ff05,$ff07,$ff08,$ff0a,$ff0c,$ff0d,$ff0f,$ff12
    dw      $ff14,$ff16,$ff19,$ff1c,$ff1f,$ff22,$ff25,$ff28
    dw      $ff2c,$ff2f,$ff33,$ff37,$ff3b,$ff3f,$ff43,$ff47
    dw      $ff4b,$ff50,$ff55,$ff59,$ff5e,$ff63,$ff68,$ff6d
    dw      $ff72,$ff78,$ff7d,$ff82,$ff88,$ff8d,$ff93,$ff99
    dw      $ff9f,$ffa4,$ffaa,$ffb0,$ffb6,$ffbc,$ffc2,$ffc8
    dw      $ffcf,$ffd5,$ffdb,$ffe1,$ffe7,$ffee,$fff4,$fffa
    ; Math_SineTable ends here
    dw      $0000,$0006,$000c,$0012,$0019,$001f,$0025,$002b
    dw      $0031,$0038,$003e,$0044,$004a,$0050,$0056,$005c
    dw      $0061,$0067,$006d,$0073,$0078,$007e,$0083,$0088
    dw      $008e,$0093,$0098,$009d,$00a2,$00a7,$00ab,$00b0
    dw      $00b5,$00b9,$00bd,$00c1,$00c5,$00c9,$00cd,$00d1
    dw      $00d4,$00d8,$00db,$00de,$00e1,$00e4,$00e7,$00ea
    dw      $00ec,$00ee,$00f1,$00f3,$00f4,$00f6,$00f8,$00f9
    dw      $00fb,$00fc,$00fd,$00fe,$00fe,$00ff,$00ff,$00ff
    
endc

if INC_SQRT
Math_SquareRootTable:
    dw      $000,$100,$16a,$1bc,$200,$23d,$274,$2a6,$2d5,$301,$32b,$352,$378,$39c,$3bf,$3e1
    dw      $401,$421,$440,$45e,$47b,$497,$4b3,$4ce,$4e8,$502,$51b,$534,$54d,$565,$57c,$594
    dw      $5aa,$5c1,$5d7,$5ed,$602,$618,$62d,$641,$656,$66a,$67e,$691,$6a5,$6b8,$6cb,$6de
    dw      $6f1,$703,$715,$727,$739,$74b,$75c,$76e,$77f,$790,$7a1,$7b2,$7c2,$7d3,$7e3,$7f3
    dw      $803,$813,$823,$833,$843,$852,$862,$871,$880,$88f,$89e,$8ad,$8bc,$8ca,$8d9,$8e7
    dw      $8f6,$904,$912,$920,$92e,$93c,$94a,$958,$966,$973,$981,$98e,$99c,$9a9,$9b6,$9c4
    dw      $9d1,$9de,$9eb,$9f8,$a04,$a11,$a1e,$a2b,$a37,$a44,$a50,$a5d,$a69,$a75,$a82,$a8e
    dw      $a9a,$aa6,$ab2,$abe,$aca,$ad6,$ae2,$aee,$af9,$b05,$b11,$b1c,$b28,$b33,$b3f,$b4a
    dw      $b55,$b61,$b6c,$b77,$b82,$b8e,$b99,$ba4,$baf,$bba,$bc5,$bd0,$bda,$be5,$bf0,$bfb
    dw      $c05,$c10,$c1b,$c25,$c30,$c3a,$c45,$c4f,$c5a,$c64,$c6f,$c79,$c83,$c8d,$c98,$ca2
    dw      $cac,$cb6,$cc0,$cca,$cd4,$cde,$ce8,$cf2,$cfc,$d06,$d10,$d1a,$d23,$d2d,$d37,$d41
    dw      $d4a,$d54,$d5e,$d67,$d71,$d7a,$d84,$d8d,$d97,$da0,$daa,$db3,$dbc,$dc6,$dcf,$dd8
    dw      $de2,$deb,$df4,$dfd,$e06,$e10,$e19,$e22,$e2b,$e34,$e3d,$e46,$e4f,$e58,$e61,$e6a
    dw      $e73,$e7c,$e85,$e8d,$e96,$e9f,$ea8,$eb1,$eb9,$ec2,$ecb,$ed3,$edc,$ee5,$eed,$ef6
    dw      $efe,$f07,$f10,$f18,$f21,$f29,$f32,$f3a,$f42,$f4b,$f53,$f5c,$f64,$f6c,$f75,$f7d
    dw      $f85,$f8d,$f96,$f9e,$fa6,$fae,$fb7,$fbf,$fc7,$fcf,$fd7,$fdf,$fe7,$fef,$ff7,$fff
endc

if INC_ATAN2
section "atan table",rom0,align[8]
Math_ATanTable:
    db      $20,$20,$20,$21,$21,$22,$22,$23,$23,$23,$24,$24,$25,$25,$26,$26
    db      $26,$27,$27,$28,$28,$28,$29,$29,$2A,$2A,$2A,$2B,$2B,$2C,$2C,$2C
    db      $2D,$2D,$2D,$2E,$2E,$2E,$2F,$2F,$2F,$30,$30,$30,$31,$31,$31,$31
    db      $32,$32,$32,$32,$33,$33,$33,$33,$34,$34,$34,$34,$35,$35,$35,$35
    db      $36,$36,$36,$36,$36,$37,$37,$37,$37,$37,$37,$38,$38,$38,$38,$38
    db      $38,$39,$39,$39,$39,$39,$39,$39,$39,$3A,$3A,$3A,$3A,$3A,$3A,$3A
    db      $3A,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3B,$3C,$3C,$3C,$3C
    db      $3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3C,$3D,$3D,$3D,$3D,$3D,$3D,$3D
    db      $3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3E,$3E,$3E,$3E
    db      $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E
    db      $3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3E,$3F,$3F,$3F,$3F
    db      $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
    db      $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
    db      $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
    db      $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F
    db      $3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F,$3F

section "log2 table",rom0,align[8]
Math_Log2Table:
    db      $00,$00,$20,$32,$40,$4A,$52,$59,$60,$65,$6A,$6E,$72,$76,$79,$7D
    db      $80,$82,$85,$87,$8A,$8C,$8E,$90,$92,$94,$96,$98,$99,$9B,$9D,$9E
    db      $A0,$A1,$A2,$A4,$A5,$A6,$A7,$A9,$AA,$AB,$AC,$AD,$AE,$AF,$B0,$B1
    db      $B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9,$B9,$BA,$BB,$BC,$BD,$BD,$BE,$BF
    db      $C0,$C0,$C1,$C2,$C2,$C3,$C4,$C4,$C5,$C6,$C6,$C7,$C7,$C8,$C9,$C9
    db      $CA,$CA,$CB,$CC,$CC,$CD,$CD,$CE,$CE,$CF,$CF,$D0,$D0,$D1,$D1,$D2
    db      $D2,$D3,$D3,$D4,$D4,$D5,$D5,$D5,$D6,$D6,$D7,$D7,$D8,$D8,$D9,$D9
    db      $D9,$DA,$DA,$DB,$DB,$DB,$DC,$DC,$DD,$DD,$DD,$DE,$DE,$DE,$DF,$DF
    db      $DF,$E0,$E0,$E1,$E1,$E1,$E2,$E2,$E2,$E3,$E3,$E3,$E4,$E4,$E4,$E5
    db      $E5,$E5,$E6,$E6,$E6,$E7,$E7,$E7,$E7,$E8,$E8,$E8,$E9,$E9,$E9,$EA
    db      $EA,$EA,$EA,$EB,$EB,$EB,$EC,$EC,$EC,$EC,$ED,$ED,$ED,$ED,$EE,$EE
    db      $EE,$EE,$EF,$EF,$EF,$EF,$F0,$F0,$F0,$F1,$F1,$F1,$F1,$F1,$F2,$F2
    db      $F2,$F2,$F3,$F3,$F3,$F3,$F4,$F4,$F4,$F4,$F5,$F5,$F5,$F5,$F5,$F6
    db      $F6,$F6,$F6,$F7,$F7,$F7,$F7,$F7,$F8,$F8,$F8,$F8,$F9,$F9,$F9,$F9
    db      $F9,$FA,$FA,$FA,$FA,$FA,$FB,$FB,$FB,$FB,$FB,$FC,$FC,$FC,$FC,$FC
    db      $FD,$FD,$FD,$FD,$FD,$FD,$FE,$FE,$FE,$FE,$FE,$FF,$FF,$FF,$FF,$FF
endc