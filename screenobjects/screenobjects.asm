    PROCESSOR 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; include required files with definition and macros 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    INCLUDE "vcs.h"
    INCLUDE "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start an unitialized segment at $80 for variable declaration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG.U Variables
    ORG $80
P0Height DS 1          ; defines one byte for player 0 height
P1Height DS 1          ; defines one byte for player 1 height

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; starts our ROM code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG
    ORG $F000

Reset:
    CLEAN_START

    LDX #$80            ; build background color
    STX COLUBK          ;

    LDA #%1111          ; white playfield color
    STA COLUPF          ;

    LDA #10             ; A = 10
    STA P0Height        ; P0Height = 10
    STA P1Height        ; P1Height = 10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; we set the TIA register for the color of P0 and P1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #$48            ; player 0 color light red
    STA COLUP0          ;

    LDA #$c6            ; player 1 color light green
    STA COLUP1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start new frame by configuring VBANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFarme:
    LDA #02
    STA VBLANK          ; turn VBLANK on
    STA VSYNC           ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; generate three line of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        STA WSYNC       ; three scanline for VSYNC
    REPEND
    LDA #0              ;
    STA VSYNC           ; turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; let the TIA output the 37 recommmended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 37
        STA WSYNC       ;
    REPEND

    LDA #0              ;
    STA VBLANK          ; turn off VBLANK 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set the CTRLPF register to allow playfield reflection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDX #%00000010      ; CTRLPF register (D0 means reflect the PF)
    STX CTRLPF          ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draw the 192 visible scanline 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VisibleScanline:
    ; draw 10 empety scanlines at the top of the frame
    REPEAT 10
        STA WSYNC
    REPEND

    ; displays 10 scanlines for the scoreboard number
    ; pulls data forom an array of bytes defined at NumberBitmap
    LDY #0              ;
ScorBaoardLoop:
    LDA NumberBitmap,Y
    STA PF1
    STA WSYNC
    INY
    CPY #10             ; compare Y register with 10 after decrement for looping all scan lines and the bytes inside
    BNE ScorBaoardLoop

    LDA #0
    STA PF1             ; disable playfield

    ; draw 50 empety scanlines 
    REPEAT 50
        STA WSYNC
    REPEND

    ; dispalys 10 scanlines for the player 0 graphics.
    ; pulls data from an array of bytes defined at PlayerBitmap
    LDY 0
Player0Loop:
    LDA PlayerBitmap,Y
    STA GRP0
    STA WSYNC
    INY
    CPY P0Height             ; compare Y register with 10 after decrement for looping all scan lines and the bytes inside
    BNE Player0Loop

    LDA #0
    STA GRP0            ; disable player 0

    ; dispalys 10 scanlines for the player 0 graphics.
    ; pulls data from an array of bytes defined at PlayerBitmap
    LDY #0
Player1Loop:
    LDA PlayerBitmap,Y
    STA GRP1
    STA WSYNC
    INY
    CPY P1Height
    BNE Player1Loop     ; compare Y register with 10 after decrement for looping all scan lines and the bytes inside

    LDA #0
    STA GRP1            ; disable player 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;draw the remaining 102 scanlines 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 102
        STA WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #02
    STA VBLANK
    REPEAT 30
        STA WSYNC
    REPEND
    LDA #0
    STA VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; loop to next frame 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    JMP StartFarme

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; defines an array of bytes to draw the screenboard number 
;; we add this bytes i the final ROM addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFE8
PlayerBitmap:
    .byte #%01111110    ;  ###### 
    .byte #%11111111    ; ########
    .byte #%10011001    ; #  ##  #
    .byte #%11111111    ; ########
    .byte #%11111111    ; ########
    .byte #%11111111    ; ########
    .byte #%10111101    ; # #### #
    .byte #%11000011    ; ##    ##
    .byte #%11111111    ; ########
    .byte #%01111110    ;  ###### 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; defines an array of bytes to draw the screenboard number 
;; we add this bytes i the final ROM addresses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFF2
NumberBitmap:
    .byte #%00001110   ; ########
    .byte #%00001110   ; ########
    .byte #%00000010   ;      ###
    .byte #%00000010   ;      ###
    .byte #%00001110   ; ########
    .byte #%00001110   ; ########
    .byte #%00001000   ; ###
    .byte #%00001000   ; ###
    .byte #%00001110   ; ########
    .byte #%00001110   ; ########

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; complete ROM size 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFFC
    .word Reset
    .word Reset    