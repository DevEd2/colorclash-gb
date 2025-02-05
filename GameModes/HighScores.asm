
section "High score RAM",romx
Game_HighScores:
    ds  (5+4) * 5

section "High score screen routines",rom0
GM_HighScoreScreen:
    call    LCDOff
    ; TODO
    jr      @

HighScores_Default:
    db  "KARMA",0,5,0,0
    db  "KARMA",0,4,0,0
    db  "KARMA",0,3,0,0
    db  "KARMA",0,2,0,0
    db  "KARMA",0,1,0,0
