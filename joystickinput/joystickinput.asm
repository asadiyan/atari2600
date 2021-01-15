    PROCESSOR 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; include required files with register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    INCLUDE "macro.h"
    INCLUDE "vcs.h"
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start an uninitialized segment at $80 for var declaration.
;; we have memory from $80 to $FF to work with, minus a few at
;; the end if we use the stack
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG.U Variable
    ORG $80
P0XPos    byte           ; sprite X cordinate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; strat our ROM code segment starting at $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG Code
    ORG $F000

Reset:
    CLEAN_START          ; macro to clean memory and TIA

    LDX #$80             ; blue background color
    STX COLUBK

    LDX #$D0             ; green playfield floor color
    STX COLUPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; initialize variables 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #10
    STA P0XPos           ; initialize player X cordinate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
    LDA #2
    STA VBLANK           ; turn VBLANK on
    STA VSYNC            ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; display 3 vertical lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        STA WSYNC        ; first 3 VSYNC scanline
    REPEND
    LDA #0
    STA VSYNC            ; turn VSYNC off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set player horizontal position while we are the VBLANK 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA P0XPos           ; load register A with desired X position
    AND #$7F             ; same as AND 01111111, forces bit 7 to zero
                         ; keeping the value inside A always positive
    
    STA WSYNC            ; wait for next scanline
    STA HMCLR            ; clear old horizontal position value

    SEC                  ; set carry flag before subtraction
DivideLoop:
    SBC #15              ; A -= 15
    BCS DivideLoop       ; loop while carry flag is still set

    EOR #7               ; adjust the reminder in A between -8 and 7
    ASL                  ; shift left by 4, as HMP0 uses only for bits 
    ASL
    ASL
    ASL
    STA HMP0             ; set fine position 
    STA RESP0            ; reset 15-step brute position
    STA WSYNC            ; wait for next scanline 
    STA HMOVE            ; apply the fine position offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; let the TIA output the (37-2) recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 35
        STA WSYNC
    REPEND
    
    LDA #0
    STA VBLANK           ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draw the 192 visible scanline 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 160
        STA WSYNC        ; wait for 160 empty scanlines
    REPEND

    LDY #17                ; counter to draw 8 rows of bitmap
DrawBitmap:
    LDA P0Bitmap,Y       ; load player bitmap slice of data
    STA GRP0             ; set graphics for player 0 slice

    LDA P0Color,Y        ; load player color from lookup table 
    STA COLUP0           ; set color for player 0 slice

    STA WSYNC            ; wait for next scanline 

    DEY
    BNE DrawBitmap       ; repeat next scanline until finished

    LDA #0
    STA GRP0             ; disable P0 bitmap graphics

    LDA #$FF             ; enable grass playfield
    STA PF0
    STA PF1
    STA PF2

    REPEAT 15
        STA WSYNC        ; wait for remaining 15 empty scanlines
    REPEND

    LDA #0               ; disable grass playfield
    STA PF0
    STA PF1
    STA PF2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; output 30 more VBLANK over scanlines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Overscan:
    LDA #2
    STA VBLANK           ; turn VBLANK on again for overscan

    REPEAT 30
        STA WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; joystick input test for P0 up/down/left/right
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    LDA #%00010000
    BIT SWCHA
    BNE CheckP0Down
    INC P0XPos

CheckP0Down:
    LDA #%00100000
    BIT SWCHA
    BNE CheckP0Left
    DEC P0XPos

CheckP0Left:
    LDA #%01000000
    BIT SWCHA
    BNE CheckP0Right
    DEC P0XPos

CheckP0Right:
    LDA #%10000000
    BIT SWCHA
    BNE NoInput
    INC P0XPos

NoInput:
    ; fallback when no input was performed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    JMP StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; lookup table for player graphics bitmap
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Bitmap:
    byte #%00000000
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00010100
    byte #%00011100
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01011101
    byte #%01111111
    byte #%00111110
    byte #%00010000
    byte #%00011100
    byte #%00011100
    byte #%00011100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; lookup table for the player colors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Color:
    byte #$00
    byte #$F6
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$F2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$C2
    byte #$3E
    byte #$3E
    byte #$3E
    byte #$24

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; complete ROM size adding reset addresses at $FFFC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFFC
    .word Reset
    .word Reset