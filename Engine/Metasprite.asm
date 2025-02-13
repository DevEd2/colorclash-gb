; Metasprite utility routines

; USAGE: incspr filename
; EXAMPLE: incspr run01
macro incspr
section "Sprite defintion - \1",romx
Sprite_\1:
    db  ((Sprite_\1_GFX.end-Sprite_\1_GFX) / $10) - 1
    dbw bank(Sprite_\1_GFX),Sprite_\1_GFX + $10
.sdef   include "GFX/\1.sdef"
section "Sprite GFX - \1",romx,align[4]
Sprite_\1_GFX:
    incbin  "GFX/\1.2bpp.wle"
.end
endm

def ANIM_CMD_GOTO   = $80

section "Metasprite RAM",wram0
Metasprite_OAMPos:  db

section "Metasprite routines",rom0

; INPUT: hl = pointer to metasprite definition
;         b = bank of metasprite definition
;         d = X coordinate
;         e = Y coordinate
;         c = horizontal flip? (0 = no, 1 = yes)
DrawMetasprite:
    rst     _Bankswitch
    ld      a,d
    ld      [hTemp],a
    ld      a,e
    ld      [hTemp2],a
    push    de
    push    bc
    ; get transfer size
    ld      a,[hl+]
;    ld      c,a
    ; get GFX pointer
    ld      a,[hl+]
;    ld      b,a
;    push    hl
;    ld      a,[hl+]
;    ld      h,[hl]
;    ld      l,a
;    ld      a,c
;    ld      c,1
;    push    bc
;    call    HDMA_AddToQueue
;    pop     bc
    
;    pop     hl
    inc     hl
    inc     hl
    pop     de
    rr      e
    jr      nc,.right
    ; transfer to OAM
.left
    pop     bc
    push    hl
    ld      hl,OAMBuffer
    ld      a,[Metasprite_OAMPos]
    ld      e,a
    ld      d,0
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
:   ld      a,[hl+]
    and     a
    jr      z,.done
    ld      b,a
    ld      a,[hTemp]
    add     b
    add     16
    xor     %10000000
    ld      [de],a
    inc     e
    ld      a,[hl+]
    cpl
    ld      b,a
    ld      a,[hTemp2]
    add     b
    xor     %10000000
    ld      [de],a
    inc     e
    ld      a,[hl+]
    ld      b,a
    ld      a,[Metasprite_OAMPos]
    rra
    rra
    add     b
    dec     a
    ld      [de],a
    inc     e
    ld      a,[hl+]
    set     5,a
    ld      [de],a
    inc     e
    jr      :-
.right
    pop     bc
    push    hl
    ld      hl,OAMBuffer
    ld      a,[Metasprite_OAMPos]
    ld      e,a
    ld      d,0
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
:   ld      a,[hl+]
    and     a
    jr      z,.done
    ld      b,a
    ld      a,[hTemp]
    add     b
    add     16
    xor     %10000000
    ld      [de],a
    inc     e
    ld      a,[hl+]
    ld      b,a
    ld      a,[hTemp2]
    add     b
    add     8
    xor     %10000000
    ld      [de],a
    inc     e
    ld      a,[hl+]
    ld      b,a
    ld      a,[Metasprite_OAMPos]
    rra
    rra
    add     b
    dec     a
    ld      [de],a
    inc     e
    ld      a,[hl+]
    ld      [de],a
    inc     e
    jr      :-
    
.done
    ld      a,[Metasprite_OAMPos]
    and     a
    jr      z,:++
    cp      e
    ret     z
    ld      b,a
    ld      a,e
    ld      [Metasprite_OAMPos],a
    sub     b
:   ld      [hl],0
    inc     l
    dec     b
    jr      nz,:-
    ret
:   ld      a,e
    ld      [Metasprite_OAMPos],a
    
    ret
