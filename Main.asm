; =============================================================================
; COLORCLASH/AVALANCE
; Game Boy Color version by Ed Whalen
; Copyright (C) 2002-2025 Revival Studios
;
; This project is licensed under the terms of the MIT License. See the LICENSE
; file in the root directory of this repository for the full license terms.
; =============================================================================

    include "hardware.inc/hardware.inc"

def BUILD_DEBUG = 0
def STACK_TOP = $e000

def BUILD_LOGO = 0 ; 0 = Karma Studios, 1 = Revival Studios
def BUILD_NAME = 0 ; 0 = Colorclash, 1 = Avalanche

def BIT_A           equ 0
def BIT_B           equ 1
def BIT_SELECT      equ 2
def BIT_START       equ 3
def BIT_RIGHT       equ 4
def BIT_LEFT        equ 5
def BIT_UP          equ 6
def BIT_DOWN        equ 7

def BTN_A           equ 1 << BIT_A
def BTN_B           equ 1 << BIT_B
def BTN_START       equ 1 << BIT_START
def BTN_SELECT      equ 1 << BIT_SELECT
def BTN_RIGHT       equ 1 << BIT_RIGHT
def BTN_LEFT        equ 1 << BIT_LEFT
def BTN_UP          equ 1 << BIT_UP
def BTN_DOWN        equ 1 << BIT_DOWN

def ERR_RST_38                      equ 0
def ERR_INVALID_STAT_HANDLER        equ 1
def ERR_DIV_ZERO                    equ 2
def ERR_INVALID_LEVEL_SCRIPT_CMD    equ 3
def ERR_BAD_JUMP_GENERIC            equ 8

macro lb
    assert  (\2 > 0) & (\2 < 256)
    assert  (\3 > 0) & (\3 < 256)
    ld      \1,(\2<<8) | \3
endm

macro djnz
    dec     b
    jr      nz,\1
endm

macro rgb
    dw      \1 | \2 << 5 | \3 << 10
endm

macro rgb8
    dw      (\1>>3) | (\2 >>3) << 5 | (\3 >> 3) << 10
endm
    
macro farcall
    ld      a,bank(\1)
    rst     _Bankswitch
    call    \1
endm

macro pushbank
    ldh     a,[hROMB0]
    push    af
endm

macro popbank
    pop     af
    ld      [rROMB0],a
    ldh     [hROMB0],a
endm

macro dbw
    db      \1
    dw      \2
endm

macro dwb
    dw      \1
    db      \2
endm

macro dbwb
    db      \1
    dw      \2
    db      \3
endm

macro dwfar
    db      bank(\1)
    dw      \1
endm

macro play_sound_effect
    ld      a,bank(\1)
    ld      hl,\1
    call    PlaySFX
endm

; =============================================================================

section "OAM buffer",wramx
OAMBuffer:  ds  40*4

section "System variables",hram
hOAMDMA:            ds  16 ;_OAMDMA_End-_OAMDMA

hROMB0:             db

hPaused:            db
hGlobalTimer:       db

hVBlankFlag:        db
hSTATFlag:          db
hTimerFlag:         db
hSerialFlag:        db
hJoypadFlag:        db

hHeldButtons:       db
hPressedButtons:    db
hReleasedButtons:   db

hResetTimer:        db

hGBCFlag:           db
hGBAFlag:           db

hInterruptFlags:    db

hTemp:              db
hTemp2:             db
hTemp3:             dw
hTemp4:             dw

hWarmBoot:          db

hSTATPointer:       dw

hAF:                dw
hBC:                dw
hDE:                dw
hHL:                dw
hSP:                dw
hIE:                db
hErrType:           db

def INT_VBLANK      = 0
def INT_STAT        = 1
def INT_TIMER       = 2
def INT_SERIAL      = 3
def INT_JOYPAD      = 4

def WARM_BOOT_MAGIC = 56

; =============================================================================

section "Reset $00",rom0[$00]
_Bankswitch:
    ld      [rROMB0],a
    ldh     [hROMB0],a
    ret
    
section "Reset $08",rom0[$08]
_WaitVBlank:
    jp      WaitVBlank

section "Reset $10",rom0[$10]
Reset10:
    ret

section "Reset $18",rom0[$18]
Reset18:
    ret

section "Reset $20",rom0[$20]
Reset20:
    ret

section "Reset $28",rom0[$28]
Reset28:
    ret

section "Reset $30",rom0[$30]
Reset30:
    ret

section "Reset $38",rom0[$38]
Error:
    ld      b,b
    jp      ErrorScreen

; =============================================================================

section "VBlank interrupt vector",rom0[$40]
IRQ_VBlank: jp  DoVBlank

section "LCD status interrupt vector",rom0[$48]
IRQ_STAT:   jp  DoSTAT

section "Timer interrupt vector",rom0[$50]
IRQ_Timer:  jp  DoTimer

section "Serial interrupt vector",rom0[$58]
IRQ_Serial: reti

section "Joypad interrupt vector",rom0[$60]
IRQ_Joypad: reti

; =============================================================================

section "ROM header",rom0[$100]
Header_EntryPoint:  
    jr  ProgramStart                                    ;
    ds  2,0                                             ; padding
Header_NintendoLogo:    ds  48,0                        ; handled by rgbfix
if BUILD_NAME == 0
Header_Title:           db  "COLORCLASH"                ; must be 15 chars or less!
else
Header_Title:           db  "AVALANCHE"                 ; must be 15 chars or less!
endc
                        ds  (Header_Title + 15) - @,0   ; padding
Header_GBCSupport:      db  CART_COMPATIBLE_GBC         ;
Header_NewLicenseCode:  dw                              ; not needed
Header_SGBSupport:      db  $00                         ; $03 = enable SGB features (requires old license code to be set to $33)
Header_CartridgeType:   db  CART_ROM_MBC5               ; 
Header_ROMSize:         ds  1                           ; handled by rgbfix
Header_RAMSize:         db  0                           ; not used
Header_DestinationCode: db  1                           ; 0 = Japan, 1 = not Japan
Header_OldLicenseCode:  db  $33                         ; must be $33 for SGB support
Header_Revision:        db  -1                          ; revision (-1 for prerelease builds)
Header_Checksum:        db  0                           ; handled by rgbfix
Header_ROMChecksum:     dw  0                           ; handled by rgbfix

; =============================================================================

    newcharmap MainFont
def chars equs "ABCDEFGHIJKLMNOPQRSTUVWXYZ.,?!0123456789: ÄÖÜß"
def char = 0
rept strlen("{chars}")
    charmap strsub("{chars}", char + 1, 1), char
def char = char + 1
endr

; =============================================================================

section "Program code",rom0[$150]
ProgramStart:
    di
    ; init stack
    ld      sp,STACK_TOP
    push    af
    push    bc
    ; clear HRAM
    ld      hl,_HRAM
    ld      b,$7f
    xor     a
    call    MemFillSmall
    ; set dummy STAT handler
    ld      a,low(STAT_Dummy)
    ldh     [hSTATPointer],a
    ld      a,high(STAT_Dummy)
    ldh     [hSTATPointer+1],a
    ; load ROM bank 1
    ld      a,1
    ld      [rROMB0],a
    ldh     [hROMB0],a
    ; write GBC and GBA flags
    pop     bc
    pop     af
    ld      hl,hGBCFlag
    ld      [hl+],a
    ld      [hl],b
    ; clear VRAM
    call    LCDOff
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    ld      e,0
    call    MemFill
    ; copy OAM DMA routine
    ld      hl,_OAMDMA
    ld      de,hOAMDMA
    ld      b,_OAMDMA_End-_OAMDMA
    call    MemCopySmall
    ; clear OAM
    ld      hl,OAMBuffer
    ld      b,40*4
    xor     a
    call    MemFillSmall
    ; clear HDMA queue
    ld      hl,HDMAQueue
    ld      b,8*16
    xor     a
    call    MemFillSmall
    call    HDMA_ResetQueue
    ; Very Bad Amulator™ lockout
    ld      a,5
    add     a
    daa
    push    af
    pop     hl
    bit     5,l
    jr      nz,VBALockout
    
    ; non-GBC/GBA lockout
    ldh     a,[hGBCFlag]
    cp      $11
    jr      nz,NonColorLockout
    
    ld      a,-1
    ld      [SFX_Priority],a
    xor     a
    ld      [SFX_Playing],a
    
    ; enable double speed mode
    ldh     [rIE],a
    ld      a,$30
    ldh     [rP1],a
    ld      a,1
    ldh     [rKEY1],a
    stop
    
    call    Math_InitRandSeed
    
 
    ldh     a,[hWarmBoot]
    cp      WARM_BOOT_MAGIC
    jr      nz,:+
    ; any code that should be run on cold boot only goes here
:   ld      a,WARM_BOOT_MAGIC
    ldh     [hWarmBoot],a
    ld      a,1
    ld      [Options_Music],a
    ld      [Options_SFX],a
if BUILD_DEBUG
    jp      GM_Debug
else
    jp      GM_Logo
endc

; =============================================================================

NonColorLockout:
    ld      a,bank(LockoutDMGTiles)
    rst     _Bankswitch
    ld      hl,LockoutDMGTiles
    ld      de,_VRAM
    call    DecodeWLE

    ld      hl,LockoutDMGMap
    ld      de,_SCRN0
    ld      bc,$1412
    call    LoadTilemap

    ld      a,%00011011
    ldh     [rBGP],a

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh     [rLCDC],a

    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
:   halt
    jr      :-

VBALockout:
    ld      a,bank(LogoHeaderTiles)
    rst     _Bankswitch
    ld      hl,LogoHeaderTiles
    ld      de,_VRAM
    call    DecodeWLE

    ld      hl,LogoHeaderMap
    ld      de,_SCRN0
    lb      bc,SCRN_X_B,6
    call    LoadTilemapAttr

    ld      a,1
    ldh     [rVBK],a
    ld      hl,LockoutVBATiles
    ld      de,_VRAM
    call    DecodeWLE

    xor     a
    ldh     [rVBK],a
    ld      hl,LockoutVBAMap
    ld      de,_SCRN0 + (6 * SCRN_VX_B)
    lb      bc,SCRN_X_B,SCRN_Y_B-6
    call    LoadTilemapAttr

    ; GBC palette
    ld      hl,LogoHeaderPalette
    ld      a,$80
    ldh     [rBCPS],a
    rept    7*8
    ld      a,[hl+]
    ldh     [rBCPD],a
    endr
    ld      hl,FontPalette
    rept    8
    ld      a,[hl+]
    ldh     [rBCPD],a
    endr

    ; DMG palette (just in case)
    ld      a,%00011011
    ldh     [rBGP],a

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh     [rLCDC],a
    
    jr      @

;NonColorLockoutText:
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "  THIS GAME IS NOT  "
;    db      "COMPATIBLE WITH THIS"
;    db      "      SYSTEM.       "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "

;VBALockoutText:
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "THIS EMULATOR IS NOT"
;    db      " SUPPORTED BY THIS  "
;    db      "       GAME.        "
;    db      "                    "
;    db      " PLEASE USE A NEWER "
;    db      "  EMULATOR SUCH AS  "
;    db      "SAMEBOY TO PLAY THIS"
;    db      "       GAME.        "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
;    db      "                    "
    
; =============================================================================
; Error handler    
; =============================================================================

ErrorScreen:
if BUILD_DEBUG
    ; this code is such a fucking mess...
    di
    ld      [hSP],sp
    ld      sp,hl
    ld      [hHL],sp
    ld      sp,$fffe
    push    af
    pop     hl
    ld      a,l
    ldh     [hAF],a
    ld      a,h
    ldh     [hAF+1],a
    ld      a,c
    ldh     [hBC],a
    ld      a,b
    ldh     [hBC+1],a
    ld      a,e
    ldh     [hDE],a
    ld      a,d
    ldh     [hDE+1],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    halt
    xor     a
    ldh     [rLCDC],a
    di    
    
    ; clear VRAM
    ld      a,1
    ldh     [rVBK],a
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    ld      e,0
    call    MemFill
    xor     a
    ldh     [rVBK],a
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    ld      e,0
    call    MemFill
    
    ld      hl,Font
    ld      de,_VRAM
    ld      bc,Font.end-Font
    call    CopyTiles1BPP
    
    ld      hl,Font
    ld      de,_VRAM+$800
    ld      bc,Font.end-Font
    call    CopyTiles1BPPInverted
    
    ld      hl,_SCRN0
    ld      bc,_SCRN1-_SCRN0
    ld      e," "
    call    MemFill
        
    ld      de,_SCRN0+6
    ld      hl,str_ErrorHeader
    call    PrintStringInverted
    
    ld      a,[hErrType]
    cp      NUM_ERROR_STRINGS
    ld      hl,ErrorStrings.unknown
    jr      nc,:+

    ld      c,a
    ld      b,0
    ld      hl,ErrorStringPointers
    add     hl,bc
    add     hl,bc
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
:   ld      de,_SCRN0+$40
    call    PrintString    
    ld      hl,str_AF
    ld      de,_SCRN0+$81
    call    PrintString
    ld      de,_SCRN0+$8c
    call    PrintString
    ld      de,_SCRN0+$a1
    call    PrintString
    ld      de,_SCRN0+$ac
    call    PrintString
    ld      de,_SCRN0+$c1
    call    PrintString
    ld      de,_SCRN0+$cc
    call    PrintString
    ld      de,_SCRN0+$e1
    call    PrintString
    ld      de,_SCRN0+$ec
    call    PrintString
    
    ld      de,_SCRN0+$120
    call    PrintString
    
    ld      hl,_SCRN0+$144
    ld      bc,$20
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    add     hl,bc
    ld      [hl],":"
    
    ld      de,$9884
    ld      hl,hAF+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$988f
    ld      hl,hBC+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    
    ld      de,$98a4
    ld      hl,hDE+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$98af
    ld      hl,hHL+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    
    ld      de,$98c4
    ld      hl,hSP+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$98cf
    ldh     a,[rIE]
    call    PrintHex
    
    ld      de,$98e4
    ld      hl,hSTATPointer+1
    ld      a,[hl-]
    call    PrintHex
    ld      a,[hl]
    call    PrintHex
    ld      de,$98ef
    ldh     a,[hGBCFlag]
    call    PrintHex
    ldh     a,[hGBAFlag]
    call    PrintHex
    
    ld      hl,hSP
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    push    hl
    ld      de,$9940
    ld      b,8
:   push    bc
    push    de
    ld      a,h
    call    PrintHex
    ld      a,l
    call    PrintHex
    pop     de
    ld      a,e
    add     $20
    ld      e,a
    jr      nc,:+
    inc     d
:   ld      bc,6
    add     hl,bc
    pop     bc
    dec     b
    jr      nz,:--
    pop     hl
    di
    ld      sp,hl
    ld      b,8
    ld      de,$9946
:   ; cant have rept and an anonymous label on the same line smh my head
    rept    3
    pop     hl
    ; calling PrintHex here trashes the stack so we need to inline it for both h and l
    ld      a,h
    swap    a
    and     $f
    ld      [de],a
    inc     e
    ld      a,h
    and     $f
    ld      [de],a
    inc     e
    ld      a,l
    swap    a
    and     $f
    ld      [de],a
    inc     e
    ld      a,l
    and     $f
    ld      [de],a
    inc     e
    inc     de ; advance one char
    endr
    ld      hl,(($9946 + (6 * 3))-$9946)-1
    add     hl,de
    ld      d,h
    ld      e,l
    dec     b
    jr      nz,:-
    
    ld      sp,$fffe
    ei
    
    ; GBC palette
    ld      hl,Pal_BSOD
    xor     a
    call    LoadPal
    call    CopyPalettes
    ; DMG palette (just in case)
    ld      a,%00011011
    ldh     [rBGP],a
    
    ; farcall DSX_StopMusic
    ; xor     a
    ; ld      [DSFX_Enabled],a
    ; ldh     [rNR52],a

    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000
    ldh     [rLCDC],a
    
    xor     a
    ldh     [rSCX],a
    ldh     [rSCY],a
    
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
ErrLoop:
    halt
    jr      ErrLoop

str_ErrorHeader:    db  "=ERROR!=",0
str_AF:             db  "AF=",0
str_BC:             db  "BC=",0
str_DE:             db  "DE=",0
str_HL:             db  "HL=",0
str_SP:             db  "SP=",0
str_IE:             db  "IE=",0
str_RP:             db  "RP=",0
str_Console:        db  "GB=",0
str_StackTrace:     db  "STACK TRACE:",0

ErrorStringPointers:
ErrorStrings:
    dw      .trap
    dw      .invstathandler
    dw      .divbyzero
    dw      .invlscmd
    dw      .invlsasm
    dw      .invlsstatus
    dw      .invmuscmd
    dw      .invsfxcmd
    dw      .badjumptable
def NUM_ERROR_STRINGS = (@ - ErrorStringPointers) / 2
    
.trap ;  ####################
    db  "RST $38 TRAP",0
.invstathandler
    db  "INVALID STAT HANDLER",0
.divbyzero
    db  "DIVISION BY ZERO",0
.invlscmd
;    db  "INV LEVEL SCRIPT CMD",0
    db  "UNUSED ERROR",0
.invlsasm
;    db  "INV LEVEL SCRIPT ASM",0
    db  "UNUSED ERROR",0
.invlsstatus
;    db  "INVALID LS STATUS",0
    db  "UNUSED ERROR",0
.invmuscmd
;    db  "INVALID MUS COMMAND",0
    db  "UNUSED ERROR",0
.invsfxcmd
;    db  "INVALID SFX COMMAND",0
    db  "UNUSED ERROR",0
.badjumptable
    db  "BAD JUMPTABLE OFFSET",0
.unknown
    db  "UNKNOWN ERROR",0
    ;    ####################
else
    jr      @
endc
; =============================================================================
; Interrupt handlers
; =============================================================================

WaitVBlank:
    push    hl
    ld      hl,hInterruptFlags
    res     INT_VBLANK,[hl]
:   ei
    halt
    bit     INT_VBLANK,[hl]
    jr      z,:-
    pop     hl
    ret

DoVBlank:
    push    af
    push    bc
    push    de
    push    hl
    pushbank
    
    ; update global timer
    ldh     a,[hPaused]
    and     a
    jr      nz,:+
    ld      hl,hGlobalTimer
    inc     [hl]
:   ; graphics updates
    call    UpdatePalettes
    call    hOAMDMA
    call    HDMA_RunQueue
    ; clear OAM
;    ldh     a,[hPaused]
;    and     a
;    jr      nz,:+
;    ld      hl,OAMBuffer
;    ld      b,40*4
;    xor     a
;    call    MemFillSmall
:   ; get input
    ld      a,[hHeldButtons]
    ld      c,a
    ld      a,P1F_5
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $f
    swap    a
    ld      b,a
    ld      a,P1F_4
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $f
    or      b
    ld      b,a
    ld      a,[hHeldButtons]
    xor     b
    and     b
    ld      [hPressedButtons],a     ; store buttons pressed this frame
    ld      e,a
    ld      a,b
    ld      [hHeldButtons],a        ; store held buttons
    xor     c
    xor     e
    ld      [hReleasedButtons],a    ; store buttons released this frame
    ld      a,P1F_5|P1F_4
    ld      [rP1],a
    ; update SFX
    call    UpdateSFX
:   ; set interrupt flag
    ld      hl,hInterruptFlags
    set     INT_VBLANK,[hl]
    popbank
    pop     hl
    pop     de
    pop     bc
    pop     af
    reti

DoSTAT:
    push    af
    push    bc
    push    de
    push    hl   
    ld      hl,hSTATPointer
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    bit     7,h
    jr      nz,.error
    call    .hl
    pop     hl
    pop     de
    pop     bc
    pop     af
    reti
.hl jp      hl

.error
    push    af
    ld      a,ERR_INVALID_STAT_HANDLER
    ldh     [hErrType],a
    pop     af
    rst     Error

STAT_Dummy:
    ret

DoTimer:
    push    af
    push    bc
    push    de
    push    hl
    ldh     a,[hROMB0]
    push    af
    call    GBMod_Update
    pop     af
    rst     _Bankswitch
    pop     hl
    pop     de
    pop     bc
    pop     af
    reti

; =============================================================================
; Useful routines
; =============================================================================

section "HDMA memory",wram0,align[0]
HDMAQueue:      ds  8 * 16
HDMAQueuePos:   db
HDMASize:       db

section "HDMA routines",rom0

; INPUT: a = size
;        b = source ROM/RAM bank
;        c = destination VRAM bank
;        hl = source address
HDMA_AddToQueue:
    push    af
    ld      a,[HDMAQueuePos]
    cp      $10
    jr      nc,.overflow
    push    hl

    ld      a,[HDMASize]
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    add     hl,hl   ; x16
    set     7,h

    push    hl
    ld      a,[HDMAQueuePos]
    ld      l,a
    ld      h,0
    add     hl,hl   ; x2
    add     hl,hl   ; x4
    add     hl,hl   ; x8
    ld      de,HDMAQueue
    add     hl,de
    pop     de

    ld      a,b
    ld      [hl+],a
    ld      a,c
    ld      [hl+],a
    pop     bc
    ld      a,b
    ld      [hl+],a
    ld      a,c
    ld      [hl+],a
    ld      a,d
    ld      [hl+],a
    ld      a,e
    ld      [hl+],a
    pop     af
    ld      [hl+],a
    ld      b,a
    ld      a,[HDMASize]
    add     b
    ld      [HDMASize],a
    ld      hl,HDMAQueuePos
    inc     [hl]
    ret
.overflow
    ld      b,b
    pop     af
    ret

HDMA_ResetQueue:
    xor     a
    ld      [HDMAQueuePos],a
    ld      [HDMASize],a
    ret

; Must be run during VBlank!
HDMA_RunQueue:
    ld      a,[HDMAQueuePos]
    and     a
    ret     z
    ld      e,a
    ld      hl,HDMAQueue
    ldh     a,[hROMB0]
    push    af
.queueloop
:   ld      a,[hl+]
    and     a
    jr      z,.nextslot
    rst     _Bankswitch
    ld      a,[hl+]
    ldh     [rVBK],a
    ld      a,[hl+]
    ldh     [rHDMA1],a
    ld      a,[hl+]
    ldh     [rHDMA2],a
    ld      a,[hl+]
    ldh     [rHDMA3],a
    ld      a,[hl+]
    ldh     [rHDMA4],a
    ld      a,[hl+]
    set     7,a
    ldh     [rHDMA5],a
    inc     hl  ; skip dummy byte
    dec     e
    jr      nz,.queueloop
    xor     a
    call    HDMA_ResetQueue
    pop     af
    rst     _Bankswitch
    ret
.nextslot
    ld      a,l
    add     7
    ld      l,a
    jr      nc,:+
    inc     h
:   dec     e
    jr      nz,.queueloop

; print a null-terminated string to DE
; INPUT: hl = pointer
;        de = destination
PrintString:
    ld      a,[hl+]
    and     a
    ret     z
    ld      [de],a
    inc     de
    jr      PrintString
    
; print an FF-terminated string to DE
; INPUT: hl = pointer
;        de = destination
PrintString2:
    ld      a,[hl+]
    cp      -1
    ret     z
    ld      [de],a
    inc     de
    jr      PrintString2

; print a null-terminated color inverted string to DE
; INPUT: hl = pointer
;        de = destination
PrintStringInverted:
    ld      a,[hl+]
    and     a
    ret     z
    set     7,a
    ld      [de],a
    inc     de
    jr      PrintStringInverted

; Print hexadecimal number B at DE
; INPUT:  a = number
;        de = destination
PrintHex:
    ld      b,a
    swap    a
    and     $f
    ld      [de],a
    inc     e
    ld      a,b
    and     $f
    ld      [de],a
    inc     e
    ret

    include "Engine/Math.asm"

; INPUT: hl = source
;        de = destination
;        bc = size
CopyTiles1BPP:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPP
    ret

CopyTiles1BPPLight:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPPLight
    ret


CopyTiles1BPPDark:
    ld      a,[hl+]
    inc     de
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPPDark
    ret

CopyTiles1BPPInverted:
    ld      a,[hl+]
    cpl
    ld      [de],a
    inc     de
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,CopyTiles1BPPInverted
    ret
    
; INPUT: hl = source
;        de = destination
;        bc = dimensions (b = x, c = y)
LoadTilemap:
    push    bc
.loop
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    pop     bc
    dec     c
    ret     z
    push    hl
    ld      a,e
    and     %11100000
    ld      e,a
    ld      hl,$20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    push    bc
    jr      .loop

; INPUT: hl = source
;        de = destination
;        bc = dimensions (b = x, c = y)
LoadTilemapAttr:
    push    bc
.loop
    xor     a
    ldh     [rVBK],a
    ld      a,[hl+]
    ld      [de],a
    ld      a,1
    ldh     [rVBK],a
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    pop     bc
    dec     c
    jr      z,.done
    push    hl
    ld      a,e
    and     %11100000
    ld      e,a
    ld      hl,$20
    add     hl,de
    ld      d,h
    ld      e,l
    pop     hl
    push    bc
    jr      .loop
.done
    xor     a
    ldh     [rVBK],a
    ret

; INPUT: hl = source
;        de = destination
;        bc = dimensions (b = x, c = y)
LoadBackgroundMap:
    push    bc
    push    de
    xor     a
    ldh     [rVBK],a
    push    bc
.loop
:   ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,:-
    ld      a,[hl+]
    add     $80
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop
    pop     bc
    dec     c
    jr      z,.attr
    push    bc
    jr      .loop
.attr
    pop     de
    pop     bc
    ld      a,1
    ldh     [rVBK],a
    push    bc
.loop2
:   ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,:-
    ld      a,[hl+]
    inc     a   ; HACK
    ld      [de],a
    inc     de
    dec     b
    jr      nz,.loop2
    pop     bc
    dec     c
    ret     z
    push    bc
    jr      .loop2
    ret
    
; INPUT: hl = destination
;         e = fill byte
;        bc = size   
MemFill:
    ld      [hl],e
    inc     hl
    dec     bc
    ld      a,b
    or      c
    jr      nz,MemFill
    ret

; INPUT: hl = destination
;         a = fill byte
;         b = size
MemFillSmall:
    ld      [hl+],a
    dec     b
    jr      nz,MemFillSmall
    ret

; INPUT: hl = source
;        de = destination
;        bc = size
MemCopy:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,MemCopy
    ret

MemCopySafe:
    ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,MemCopySafe
:   ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     bc
    ld      a,b
    or      c
    jr      nz,MemCopySafe
    ret

; INPUT: hl = source
;        de = destination
;        b = size
MemCopySmall:
    ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,MemCopySmall
    ret

MemCopySmallSafe:
    ldh     a,[rSTAT]
    and     STATF_BUSY
    jr      nz,MemCopySmallSafe
:   ld      a,[hl+]
    ld      [de],a
    inc     de
    dec     b
    jr      nz,MemCopySmall
    ret

LCDOff:
    ldh     a,[rLCDC]
    bit     7,a
    ret     z
:   ldh     a,[rSTAT]
    and     STATF_VBL
    jr      z,:-
    xor     a
    ldh     [rLCDC],a
    ret

    include "Engine/WLE_Decode.asm"
    include "Engine/WLE_Decode_Safe.asm"
    include "Engine/PerFade.asm"
    include "Engine/Metasprite.asm"

; =============================================================================

_OAMDMA: ; copied to HRAM during startup
    ld      a,high(OAMBuffer)
    ldh     [rDMA],a
    ; wait 160 cycles for transfer to complete
    ld      a,40
:   dec     a   
    jr      nz,:-
    ret
_OAMDMA_End:

; =============================================================================

if BUILD_DEBUG
Pal_BSOD:
    rgb  0, 0,31
    rgb  0, 0, 0
    rgb  0, 0, 0
    rgb 31,31,31
endc

; =============================================================================
; Game modes
; =============================================================================

if BUILD_DEBUG
    include "GameModes/DebugMenu.asm"
endc
    include "GameModes/Logos.asm"
    include "GameModes/Title.asm"
    include "GameModes/Game.asm"
    include "GameModes/OptionsMenu.asm"
    include "GameModes/HighScores.asm"
    include "GameModes/Credits.asm"

; =============================================================================

include "Audio/SFX.asm"
include "Audio/GBMod_Player.asm"

; =============================================================================

section "Lockout screen graphics and shared resources",romx

LockoutDMGTiles:    incbin  "GFX/lockout_dmg.2bpp.wle"
LockoutDMGMap:      incbin  "GFX/lockout_dmg.map"

LockoutVBATiles:    incbin  "GFX/lockout_vba.2bpp.wle"
LockoutVBAMap:      incbin  "GFX/lockout_vba.map"


LogoHeaderTiles:    incbin  "GFX/textheader.2bpp.wle"
LogoHeaderMap:      incbin  "GFX/textheader.map"
LogoHeaderPalette:  incbin  "GFX/textheader.pal"

Font:               incbin  "GFX/font8.2bpp.wle"
Pal_GrayscaleInverted:
FontPalette:        incbin  "GFX/font8.pal"

; =============================================================================

section "Module: Title screen",romx[$4000]
Mus_Title:      incbin  "Audio/Modules/title.gbm"

section "Module: Ingame",romx[$4000]
Mus_Ingame:     incbin  "Audio/Modules/ingame.gbm"
