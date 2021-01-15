    PROCESSOR 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; include required files with definition and macros 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    INCLUDE "vcs.h"
    INCLUDE "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; starts our ROM code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    SEG
    ORG $F000

Reset:
    CLEAN_START

    LDX #$80            ; build background color
    STX COLUBK          ;

    LDA #$1C            ; yellow playfield color
    STA COLUPF          ;

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
    LDX #%00000001      ; CTRLPF register (D0 means reflect the PF)
    STX CTRLPF          ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draw the 192 visible scanline 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; skip 7 scanline with no PF set
    LDX #0
    STX PF0
    STX PF1
    STX PF2
    REPEAT 7
        sta WSYNC
    REPEND
    
    ; set PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
    LDX #%11100000
    STX PF0
    LDX #%11111111
    STX PF1
    STX PF2
    REPEAT 7
        STA WSYNC
    REPEND

    ; set the next 164 lines only with PF0 third bit enabled 
    LDX #%00100000
    STX PF0
    LDX #0
    STX PF1
    STX PF2
    REPEAT 164
        STA WSYNC
    REPEND

    ; set the PF0 to 1110 (LSB first) and PF1-PF2 as 1111 1111
    LDX #%11101111
    STX PF0
    LDX #%11111111
    STX PF1
    STX PF2
    REPEAT 7
        STA WSYNC
    REPEND

    ; skip 7 vertical lines with no PF set
    LDX #0
    STX PF0
    STX PF1
    STX PF2
    REPEAT 7
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
;; complete ROM size 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFFC
    .word Reset
    .word Reset    