    PROCESSOR 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; include required files with VCS register memory mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    INCLUDE "vcs.h"
    INCLUDE "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; declare the variables strating from memory address $80  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG.U Variables
    ORG $80

JetXPos         byte            ; player 0 x-position
JetYPos         byte            ; player 0 y-position
BomberXPos      byte            ; player 1 X-position
BomberYPos      byte            ; player 1 y-position
Score           byte            ; 2-digit score stored as BCD
Timer           byte            ; 2-digit timer stored as BCD
Temp            byte            ; auxiliary variable to store temporary score values
OnesDigitOffset word            ; lookup table offset for the score 1`s digit
TensDigitOffset word            ; lookup table offset for the score 10`s digit
JetSpritePtr    word            ; pointer to player0 sprite lookup table
JetColorPtr     word            ; pointer to player0 color lookup table
BomberSpritePtr word            ; pointer to player1 sprite lookup table
BomberColorPtr  word            ; pointer to player1 color lookup table
JetAnimOffset   byte            ; player0 sprite frame offset for animation
Random          byte            ; random number generated to set enemy position
ScoreSprite     byte            ; store the sprite bit pattern for the score
TimerSprite     byte            ; store the sprite bit pattern for the timer
TerrainColor    byte            ; store the color of the terrain
RiverColor      byte            ; store the color of the river

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9                  ; player0 sprite height(# rows in lookup  table)
BOMBER_HEIGHT = 9               ; player1 sprite height(# rows in lookup table)
DIGITS_HEIGHT = 5               ; scoreboard digit height (# rows in lookup table)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start our ROM code at memory address $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG code
    ORG $F000

Reset:
    CLEAN_START                 ; call macro to reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initize RAM variables and TIA registers 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #10
    STA JetYPos                 ; JetYPos = 10

    LDA #60
    STA JetXPos                 ; JetXPos = 60

    LDA #83
    STA BomberYPos              ; BomberYPos = 83

    LDA #54
    STA BomberXPos              ; BomberXPos = 54 

    LDA #%11010100
    STA Random                  ; Random = $D4

    LDA #0
    STA Score                   ; score = 0
    STA Timer                   ; timer = 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialize the pointers to correct lookup table address
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #<JetSprite
    STA JetSpritePtr            ; low-byte pointer for jet sprite lookup table
    LDA #>JetSprite
    STA JetSpritePtr+1          ; hi-byte pointer for jet sprite lookup table

    LDA #<JetColor
    STA JetColorPtr             ; low-byte pointer for jet color lookup table
    LDA #>JetColor
    STA JetColorPtr+1           ; hi-byte pointer for jet color lookup table

    LDA #<BomberSprite
    STA BomberSpritePtr         ; low-byte pointer for bomber sprite lookup table
    LDA #>BomberSprite
    STA BomberSpritePtr+1          ; hi-byte pointer for bomber sprite lookup table

    LDA #<BomberColor
    STA BomberColorPtr          ; low-byte pointer for bomber color lookup table
    LDA #>BomberColor
    STA BomberColorPtr+1        ; hi-byte pointer for bomber color lookup table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #2
    STA VBLANK                  ; turn on VBLANK
    STA VSYNC                   ; turn on VSYNC
    REPEAT 3
        STA WSYNC               ; display 3 recommended lines of VSYNC
    REPEND
    LDA #0
    STA VSYNC                   ; turn off VSYNC
    REPEAT 33
        STA WSYNC               ; display the recommended lines of VBLANK
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; calculations and tasks preformed in the pre-VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA JetXPos
    LDY #0                      ; loading my register with the code of my object witch is player0 
    JSR SetObjectXPos           ; jump to my subrutine

    LDA BomberXPos
    LDY #1                      ; bomber object code is 1 becouse it is player1
    JSR SetObjectXPos 

    JSR CalculateDigitOffset    ; calculate scoreboard digit lookup table offset

    STA WSYNC
    STA HMOVE                   ; apply the horizontal offsets previously set

    LDA #0
    STA VBLANK                  ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display the score board lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #0                      ; clear TIA registers before each new frame
    STA COLUBK
    STA PF0
    STA PF1
    STA PF2
    STA GRP0
    STA GRP1
    STA CTRLPF                  
    
    LDA #$1E
    STA COLUPF

    LDX #DIGITS_HEIGHT          ; start X counter with 5 (height of digits)

ScoreDigitLoop:

;; start of setting Score in scoreboard

    LDY TensDigitOffset         ; get the tens digit offset for the score
    LDA Digits,Y                ; load the bit pattern from the lookup table
    AND #$F0                    ; mask/remove the graphics for the ones digit
    STA ScoreSprite             ; save the score tens digit pattern in a variable

    LDY OnesDigitOffset         ; get the ones digit offset for score
    LDA Digits,Y                ; load the digit bit pattern from lookup table
    AND #$0F                    ; mask/remove the graphics for the tens digit

    ORA ScoreSprite             ; merge it with the saved tens digit sprite
    STA ScoreSprite             ; and save it

    STA WSYNC                   ; wait for the end of scanline
    STA PF1                     ; update the playfield to display the score sprite

;; start of setting timer in Scoreboarde

    LDY TensDigitOffset+1       ; get the left digit offset for the timer
    LDA Digits,Y                ; load the digits pattern from lookup table
    AND #$F0                    ; mask/remove the graphics for the ones digit
    STA TimerSprite             ; save the timer tens digit pattern in a variable

    LDY OnesDigitOffset+1       ; get the ones digit offset for the timer
    LDA Digits,Y                ; load the digits pattern from lookup table
    AND #$0F                    ; mask/remove the graphics for the ones digit
    ORA TimerSprite             ; merge with the saved tens digit graphic
    STA TimerSprite             ; and save it

    JSR Sleep12Cycles           ; waste some cycles 

    STA PF1                     ; update the  playfield for timer display

    LDY ScoreSprite             ; preload for the next scanline
    STA WSYNC                   ; wait for the next scanline

    STY PF1                     ; update payfield for the score display
    INC TensDigitOffset
    INC TensDigitOffset+1
    INC OnesDigitOffset
    INC OnesDigitOffset+1       ; increment all digits for the next line of data

    JSR Sleep12Cycles           ; waste some cycles

    DEX                         ; X--
    STA PF1                     ; update the playfield for the timer display
    BNE ScoreDigitLoop          ; if DEX != 0, then branch to ScoreDigitLoop

    STA WSYNC 
    
    LDA #0
    STA PF0
    STA PF1
    STA PF2                  
    STA WSYNC
    STA WSYNC
    STA WSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display the 96 visible scanlines (because 2-line kernel)
;; 192 - 20 (scoreboard scanlines) = 172 / 2 = 86 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLines:
    LDA TerrainColor
    STA COLUPF                  ; set the terrain background color

    LDA RiverColor              ; set the river background color
    STA COLUBK

    LDA #%00000001
    STA CTRLPF                  ; enable playfield reflection

    LDA #$F0
    STA PF0                     ; setting PF0 bit pattern

    LDA #$FC
    STA PF1                     ; setting PF1 bit pattern

    LDA #0                      
    STA PF2                     ; setting PF2 bit pattern

    LDX #85                     ; x counts the umber of remaining scanlines
GameLineLoop:
AreWeInsideJetSprite:
    TXA                         ; transfer X to A 
    SEC                         ; make sure the carry flag is set before subtraction
    SBC JetYPos                 ; subtract sprite Y-cordinate
    CMP JET_HEIGHT              ; are we inside the sprite height bounds?
    BCC DrawSpriteP0            ; if the result < sprite height then call the draw routine
    LDA #0                      ; else, set lookup table index to zero
DrawSpriteP0:
    CLC                         ; clear carry flag before addition
    ADC JetAnimOffset           ; jump to the correct sprite frame address in memory

    TAY                         ; load Y so we can work with the pointer
    LDA (JetSpritePtr),Y        ; load player0 bitmap data from lookup table 
    STA WSYNC                   ; wait for scanline
    STA GRP0                    ; set graphics for player0
    LDA (JetColorPtr),Y         ; load player color from lookup table
    STA COLUP0                  ; set color of player0

AreWeInsideBomberSprite:
    TXA
    SEC
    SBC BomberYPos
    CMP BOMBER_HEIGHT
    BCC DrawSpriteP1
    LDA #0
DrawSpriteP1:
    TAY

    LDA #%00000101
    STA NUSIZ1                  ; stretch player 1 sprite 

    LDA (BomberSpritePtr),Y 
    STA WSYNC
    STA GRP1
    LDA (BomberColorPtr),Y
    STA COLUP1

    DEX                         ; X--
    BNE GameLineLoop            ; repeat next main game scanline until finished

    LDA #0
    STA JetAnimOffset           ; reset jet animation frame to zero each frame 

    STA WSYNC                   ; wait for a scanline

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display overscan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #2
    STA VBLANK                  ; turn VBLANK on again
    REPEAT 30
        STA WSYNC               ; display 30 recommended lines of VBLANK overscan
    REPEND
    LDA #0
    STA VBLANK                  ; turn oof VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; process joystick input for player0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    LDA #%00010000              ; player0 joystick up
    BIT SWCHA
    BNE CheckP0Down             ; if bit pattern doesnt match, bypass Up block
    LDA JetYPos                 
    CMP #70                     ; if (player0 Y position > 70)
    BPL CheckP0Down             ;    then: skip increment
    INC JetYPos                 ;    else: increment Y position
    LDA #0
    STA JetAnimOffset           ; reset animation frame to first frame

CheckP0Down:
    LDA #%00100000              ; player0 joystick down
    BIT SWCHA
    BNE CheckP0Left             ; if bit pattern doesnt match, bypass Down block
    LDA JetYPos
    CMP #5                      ; if (player0 Y position < 5)
    BMI CheckP0Left             ;    then: skip decrement
    DEC JetYPos                 ;    else: decrement Y position
    LDA #0
    STA JetAnimOffset           ; reset animation frame to first frame

CheckP0Left:
    LDA #%01000000              ; player0 joystick left
    BIT SWCHA
    BNE CheckP0Right            ; if bit pattern doesnt match, bypass Left block
    LDA JetXPos
    CMP #35                     ; if (player0 X position < 35)
    BMI CheckP0Right            ;    then: skip decrement
    DEC JetXPos                 ;    else: decrement X position
    LDA JET_HEIGHT              
    STA JetAnimOffset           ; set animation offset to second frame

CheckP0Right:
    LDA #%10000000              ; player0 joystick Right
    BIT SWCHA
    BNE EndInputCheck           ; if bit pattern doesnt match, bypass Right block
    LDA JetXPos
    CMP #100                    ; if (player0 X position > 100)
    BPL EndInputCheck           ;    then: skip increment
    INC JetXPos                 ;    else: increment X position
    LDA JET_HEIGHT              
    STA JetAnimOffset           ; set animation offset to second frame

EndInputCheck:                  ; fallback when no input was performed 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; calculation to update position for next fram
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdateBomberPosition:
    LDA BomberYPos
    CLC
    CMP #0                      ; compare bomber Y-position with zero
    BMI ResetBomberPosition     ; if it is < 0 then reset Y-position to the top 
    DEC BomberYPos              ; else, decrement enemy Y-position for next frame
    JMP EndPositionUpdate
ResetBomberPosition:
    JSR GetRandomBomberPosition ; call subroutine for random X-position
SetScoreValues:
    SED                         ; set BCD mode for score and timer values
    LDA Score                   
    CLC
    ADC #1
    STA Score                   ; add 1 to the score (BCD does not like INC)

    LDA Timer
    CLC
    ADC #1
    STA Timer                   ; add 1 to the timer (BCD does not like INC)
    CLD                         ; disable BCD mode after updating score and timer

EndPositionUpdate:              ; fallback for the position update code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; check for objects collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckCollisionP0P1:             ; collision beetween jet and bomber
    LDA #%10000000              ; CXPPMM bit 7 detects P0 and P1 collision
    BIT CXPPMM                  ; check CXPPMM bit 7 with the above pattern
    BNE P0P1Collided            ; collision between P0 and P1 happened
    
    JSR SetTerrainRiverColor    ; else, set playfield color to green and blue

    JMP EndCollisionCheck       ; else, jump to end collision check
P0P1Collided:
    JSR GameOver                ; call gameover subroutine

EndCollisionCheck:              ; fallback 
    STA CXCLR                   ; clear all collision flag before he next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    JMP StartFrame              ; continue to dispay the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set the colors for the terrain and river 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetTerrainRiverColor SUBROUTINE
    LDA #$C2
    STA TerrainColor                ; set terrain color to green

    LDA #$84
    STA RiverColor                  ; set river color to blue
    
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; subroutine to handle object horizontal position with fine offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A is the target x-cordinate position in pixels of our object 
;; Y is the object type (0:player0, 1:player1 2:missile0  3:missile1 4:ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos SUBROUTINE
    STA WSYNC                   ; start a fresh new scanline
    SEC                         ; make sure carry flag is set before subtraction
Div15Loop:
    SBC #15                     ; subtract 15 from accumulator
    BCS Div15Loop               ; loop until carry-flag is clear
    EOR #7                      ; exclusive or 7 with register A (handle offset range from -8 to 7)
    ASL
    ASL
    ASL
    ASL                         ; four shift left to get only the top four bits
    STA HMP0,Y                  ; store the fine offset to the correct HMxx
    STA RESP0,Y                 ; fix object position in 15-step increment
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; game over subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameOver SUBROUTINE
    LDA #$30
    STA TerrainColor            ; set the terrain color to red
    STA RiverColor              ; set the river color to red

    LDA #0
    STA Score                   ; score = 0 

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; subroutine to generate a linear-feedback shift rwgister random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; generate a LFSR random number 
;; divide random value by 4 to limit the size of thr result to match river
;; add 30 to compensate for left green playfield
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetRandomBomberPosition SUBROUTINE
    LDA Random
    ASL
    EOR Random
    ASL
    EOR Random
    ASL
    ASL
    EOR Random
    ASL
    ROL Random                  ; performs a series of shifts and bit operations
    
    LSR
    LSR                         ; divide the value by 4 with 2 right shifts
    STA BomberXPos              ; save it to the variable BomberXPos
    LDA #30
    ADC BomberXPos              ; BomberXPos + 30
    STA BomberXPos              ; set the new value to the BomberXPos variable

    LDA #96
    STA BomberYPos              ; sets the Y-position to the top of screen

    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; subroutine to handle scoreboard digits to be displayed on the screen 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; convertthe high and low nibbles of the variable score and timer 
;; inti the offsets and digits lookup tableso the values can be displayed
;; each digit has a height of 5 bytes in the lookup table
;;
;; for the low nibble we need to multiply by 5
;; - we can use left shifts to perform multiplication by 2 
;; - for any number N, the value of N * 5 = (N * 2 * 2) 
;;
;; for the upper nibble, since its already times 16, we need ti divide it 
;; and then multiply by 5
;; - we can use right shifts to perform division by 2
;; - and for any number N, the value of (N / 16) * 5 = (N / 2 / 2) + (N / 2 / 2 / 2 / 2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CalculateDigitOffset SUBROUTINE
    LDX #1                      ; X register is the loop counter
PrepareScoreLoop:               ; this will loop twice, first x = 1, and then x = 0

    LDA Score,X                 ; load A with timer (x = 1) or score (x = 0)
    AND #$0F                    ; remove the tens digit by masking 4 bits 00001111
    STA Temp                    ; save the value of A into temporary variable
    ASL                         ; shift left (it is now N * 2)
    ASL                         ; shift left (it is now N * $)
    ADC Temp                    ; add the value saved in Temp ( + N)
    STA OnesDigitOffset,X       ; save A in OnesDigitOffset + 1 or OnesDigitOffset

    LDA Score,X                 ; load A with timer (x = 1) or score (x = 0)
    AND #$F0                    ; emove the ones digit by masking four bits 11110000
    LSR                         ; shift right (it is now N / 2) 
    LSR                         ; shift right (is is now N / 4)
    STA Temp                    ; save the value of A into temp
    LSR                         ; shift right (it is now N / 8)
    LSR                         ; shift right (it is now N / 16)
    ADC Temp                    ; add the value saved in Temp (N / 16) + (N / 4) 
    STA TensDigitOffset,X       ; store A in TensDigitOffset + 1 or TensDigitOffset

    DEX                         ; X--
    BPL PrepareScoreLoop        ; while x > 0, loop to pass a second time
    
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; subrutine to waste 12 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; JSR takes 6 cycles 
;; RTS takes 6 cycles
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Sleep12Cycles SUBROUTINE
    RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Digits:
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00110011          ;  ##  ##
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #
    .byte %00010001          ;   #   #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %00010001          ;   #   #
    .byte %01110111          ; ### ###

    .byte %00100010          ;  #   #
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #

    .byte %01110111          ; ### ###
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01100110          ; ##  ##
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01010101          ; # # # #
    .byte %01100110          ; ##  ##

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01110111          ; ### ###

    .byte %01110111          ; ### ###
    .byte %01000100          ; #   #
    .byte %01100110          ; ##  ##
    .byte %01000100          ; #   #
    .byte %01000100          ; #   #

JetSprite:
    .byte #%00000000         ;
    .byte #%00010100         ;   # #
    .byte #%01111111         ; #######
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

JetSpriteTurn:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00111110         ;  #####
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00011100         ;   ###
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #

BomberSprite:
    .byte #%00000000         ;
    .byte #%00001000         ;    #
    .byte #%00001000         ;    #
    .byte #%00101010         ;  # # #
    .byte #%00111110         ;  #####
    .byte #%01111111         ; #######
    .byte #%00101010         ;  # # #
    .byte #%00001000         ;    #
    .byte #%00011100         ;   ###

JetColor:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$BA
    .byte #$0E
    .byte #$08

JetColorTurn:
    .byte #$00
    .byte #$FE
    .byte #$0C
    .byte #$0E
    .byte #$0E
    .byte #$04
    .byte #$0E
    .byte #$0E
    .byte #$08

BomberColor:
    .byte #$00
    .byte #$32
    .byte #$32
    .byte #$0E
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40
    .byte #$40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFFC                   ; move to position $FFFC in memory
    word Reset                  ; write 2 bytes with the program reset address
    word Reset                  ; write 2 bytes with the interruption vector