DecodeWLESafe:
; Walle Length Encoding decoder
    ld  c,0
DecodeWLESafeLoop:
    ld  a,[hl+]
    ld  b,a
    and $c0
    jr  z,.literal
    cp  $40
    jr  z,.repeat
    cp  $80
    jr  z,.increment

.copy
    ld  a,b
    inc b
    ret z

    and $3f
    inc a
    ld  b,a
    ld  a,[hl+]
    push    hl
    ld  l,a
    ld  a,e
    scf
    sbc l
    ld  l,a
    ld  a,d
    sbc 0
    ld  h,a
    call    MemCopySmallSafe
    pop hl
    jr  DecodeWLESafeLoop

.literal
    ld  a,b
    and $1f
    bit 5,b
    ld  b,a
    jr  nz,.longl
    inc b
    call    MemCopySmallSafe
    jr  DecodeWLESafeLoop

.longl
    push    bc
    ld  a,[hl+]
    ld  c,a
    inc bc
    call    MemCopySafe
    pop bc
    jr  DecodeWLESafeLoop

.repeat
    call    .repeatIncrementCommon
.loopr
    ld  [de],a
    inc de
    dec b
    jr  nz,.loopr
    jr  DecodeWLESafeLoop

.increment
    call    .repeatIncrementCommon
.loopi
    ld  [de],a
    inc de
    inc a
    dec b
    jr  nz,.loopi
    ld  c,a
    jr  DecodeWLESafeLoop

.repeatIncrementCommon
    bit 5,b
    jr  z,.nonewr
    ld  c,[hl]
    inc hl
.nonewr
    ld  a,b
    and $1f
    inc a
    ld  b,a
    ld  a,c
    ret
