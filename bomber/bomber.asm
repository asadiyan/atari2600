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
JetSpritePtr    word            ; pointer to player0 sprite lookup table
JetColorPtr     word            ; pointer to player0 color lookup table
BomberSpritePtr word            ; pointer to player1 sprite lookup table
BomberColorPtr  word            ; pointer to player1 color lookup table

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; define constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
JET_HEIGHT = 9                  ; player0 sprite height(# rows in lookup  table)
BOMBER_HEIGHT = 9               ; player1 sprite height(# rows in lookup table)

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #2
    STA VBLANK                  ; turn on VBLANK
    STA VSYNC                   ; turn on VSYNC
    REPEAT 3
        STA WSYNC               ; display 3 recommended lines of VSYNC
    REPEND
    LDA #0
    STA VSYNC                   ; turn off VSYNC
    REPEAT 37
        STA WSYNC               ; display 37 recommended lines of VBLANK
    REPEND
    STA VBLANK                  ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display the 96 visible scanlines (because 2-line kernel) 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameVisibleLines:
    LDA #$84
    STA COLUBK                  ; set color of background to blue

    LDA #$C2
    STA COLUPF                  ; set color of playfield(grass) to green

    LDA #%00000001
    STA CTRLPF                  ; enable playfield reflection

    LDA #$F0
    STA PF0                     ; setting PF0 bit pattern

    LDA #$FC
    STA PF1                     ; setting PF1 bit pattern

    LDA #0                      
    STA PF2                     ; setting PF2 bit pattern

    LDX #96                     ; x counts the umber of remaining scanlines
GameLineLoop:
AreWeInsideJetSprite:
    TXA                         ; transfer X to A 
    SEC                         ; make sure the carry flag is set before subtraction
    SBC JetYPos                 ; subtract sprite Y-cordinate
    CMP JET_HEIGHT              ; are we inside the sprite height bounds?
    BCC DrawSpriteP0            ; if the result < sprite height then call the draw routine
    LDA #0                      ; else, set lookup table index to zero
DrawSpriteP0:
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
;; loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    JMP StartFrame              ; continue to dispay the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; declare ROM lookup tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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