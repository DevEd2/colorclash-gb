section "Debug menu RAM",wram0

Debug_MenuPos:          db
Debug_MenuMax:          db
Debug_MenuCursorOffset: db
Debug_MenuJumpTablePtr: dw

section "Debug menu routines",rom0

    GM_Debug:
    call    LCDOff
    di
    
    ; clear both VRAM banks
    ld      a,1
    ldh     [rVBK],a
    ld      hl,_VRAM
    ld      bc,_SRAM-_VRAM
    ld      e,0
    call    MemFill
    xor     a
    ldh     [rVBK],a
    ld      hl,_SCRN0
    ld      bc,_SRAM-_VRAM
    ld      e," "
    call    MemFill
    
    ; load font
    ld      hl,Font
    ld      de,_VRAM
    ld      bc,Font.end-Font
    call    CopyTiles1BPP
    
    ; load palettes
    ld      hl,Pal_GrayscaleInverted
    push    hl
    xor     a
    call    LoadPal
    ld      a,8
    pop     hl
    call    LoadPal
    call    CopyPalettes
    ; draw main menu
    ld      hl,Debug_String_Header1
    ld      de,_SCRN0+$00
    call    PrintString2
    ld      hl,Debug_String_BuildDate
    ld      de,_SCRN0+$20
    call    PrintString2
    ld      hl,Debug_String_RGBDSVersion1
    ld      de,_SCRN0+$40
    call    PrintString2
    ld      hl,Debug_String_RGBDSVersion2
    ld      de,_SCRN0+$60
    call    PrintString2
    
    ld      hl,Debug_MainMenuItemText
    ld      de,$98a2
    call    Debug_DrawMenuItems
    
    ; init main debug menu
    ld      a,DEBUG_MAIN_MENU_NUM_ITEMS - 1
    ld      [Debug_MenuMax],a
    xor     a
    ld      [Debug_MenuPos],a
    ld      a,low(Debug_JumpTable_Main)
    ld      [Debug_MenuJumpTablePtr],a
    ld      a,high(Debug_JumpTable_Main)
    ld      [Debug_MenuJumpTablePtr+1],a
    ld      a,55
    ld      [Debug_MenuCursorOffset],a
    
    ld      a,LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_OBJON
    ldh     [rLCDC],a
    ld      a,IEF_VBLANK
    ldh     [rIE],a
    ei
    
DebugLoop:
    call    Debug_DrawCursor
    ; do debug menu
    ldh     a,[hPressedButtons]
    bit     BIT_UP,a
    jr      nz,.up
    bit     BIT_DOWN,a
    jr      nz,.down
    bit     BIT_A,a
    jr      z,:+
    ld      hl,Debug_MenuJumpTablePtr
    ld      a,[hl+]
    ld      d,[hl]
    ld      e,a
    ld      a,[Debug_MenuPos]
    ld      l,a
    ld      h,0
    add     hl,hl
    add     hl,de
    ld      a,[hl+]
    ld      h,[hl]
    ld      l,a
    call    Debug_CallHL
    jr      :+
.up
    ld      a,[Debug_MenuPos]
    dec     a
    cp      -1
    ld      [Debug_MenuPos],a
    jr      nz,:+
    ld      a,[Debug_MenuMax]
    ld      [Debug_MenuPos],a
    jr      :+
.down
    ld      a,[Debug_MenuPos]
    ld      b,a
    ld      a,[Debug_MenuMax]
    cp      b
    jr      nz,.down_nowrap
.down_wrap
    xor     a
    ld      [Debug_MenuPos],a
    jr      :+
.down_nowrap
    ld      a,b
    inc     a
    ld      [Debug_MenuPos],a
    ; fall through
:   halt
    jr      DebugLoop

Debug_CallHL:
    bit     7,h
    jr      nz,.error
    jp      hl
.error
    push    af
    ld      a,ERR_BAD_JUMP_GENERIC
    ldh     [hErrType],a
    pop     af
    rst     $38

Debug_JumpTable_Main:
    dw  GM_Logo         ; start game
    dw  .dummy          ; sound test
    dw  .dummy          ; sprite viewer
    dw  .dummy          ; debug config
def DEBUG_MAIN_MENU_NUM_ITEMS = (@-Debug_JumpTable_Main)/2
.dummy
    ret

Debug_DrawMenuItems:
    ld      a,[hl+]
    ld      c,a
    or      [hl]
    jr      z,.done
    ld      a,[hl+]
    ld      b,a
:   ld      a,[bc]
    cp      -1
    jr      z,.next
    inc     bc
    ld      [de],a
    inc     de
    jr      :-
.next
    ld      a,e
    and     %11100000
    add     $22
    ld      e,a
    jr      nc,:+
    inc     d
:   jr      Debug_DrawMenuItems
.done
    ret

Debug_DrawCursor:
    ld      hl,OAMBuffer
    ld      a,[Debug_MenuPos]
    add     a   ; x2
    add     a   ; x4
    add     a   ; x8
    ld      b,a
    ld      a,[Debug_MenuCursorOffset]
    add     b
    ld      [hl+],a
    ld      a,8
    ld      [hl+],a
    ld      [hl],$35
    ret

def _MONTH equs "{d:__UTC_MONTH__}"
if __UTC_DAY__ < 10
def _DAY equs "0{d:__UTC_DAY__}"
else
def _DAY equs "{d:__UTC_DAY__}"
endc
def _YEAR equs strsub("{d:__UTC_YEAR__}",3)

Debug_String_BuildDate:
    db  "BUILD {_MONTH}{_DAY}{_YEAR}",-1

purge _MONTH
purge _DAY
purge _YEAR

Debug_String_RGBDSVersion1: db  "RGBDS VERSION:",-1
Debug_String_RGBDSVersion2: db  strupr("{__RGBDS_VERSION__}"),-1

if BUILD_NAME == 0
Debug_String_Header1:       db  "COLORCLASH GBC",-1
else
Debug_String_Header1:       db  "AVALANCHE GBC",-1
endc

Debug_String_StartGame:     db  "START GAME",-1
Debug_String_SoundTest:     db  "SOUND TEST",-1
Debug_String_SpriteView:    db  "SPRITE VIEWER",-1
Debug_String_Config:        db  "DEBUG OPTIONS",-1

Debug_MainMenuItemText:
    dw  Debug_String_StartGame
    dw  Debug_String_SoundTest
    dw  Debug_String_SpriteView
    dw  Debug_String_Config
    dw  0
