    PROCESSOR 6502

    INCLUDE "vcs.h"
    INCLUDE "macro.h"

    SEG code
    ORG $F000

Start:
    CLEAN_START     ; tells macro to safely clear memory and TIA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; start a new frame by turning on VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NextFrame:
    LDA #2          ; same as binary value %00000010
    STA VBLANK      ; turn on VBLANK 
    STA VSYNC       ; turn on VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; generate the three line of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    STA WSYNC       ; first scanline 
    STA WSYNC       ; second scanline
    STA WSYNC       ; third scanline

    LDA #0
    STA VSYNC       ; turn off VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; let the TIA output the recommended 37 scanline of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDX #37         ; x = 37(to count 37 scanlines)
LoopVBlank:
    STA WSYNC       ; hit WSYNC and wait to next scanline
    DEX             ; x--
    BNE LoopVBlank  ; loop while X != 0

    LDA #0
    STA VBLANK      ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draw 192 visible scanline (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDX #192        ; counter for 192 visible scanline 
LoopVisible:
    STX COLUBK      ; set the background color
    STA WSYNC       ; wait for the next scanline 
    DEX             ; x--
    BNE LoopVisible ; loop while X != 0 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; output 30 more VBLANK lines (overscan) to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #2          ;
    STA VBLANK      ; git and turn on VBLANK again for 30 more scanline in the end (over scanline)
    
    LDX #30         ; counter for 30 scanline (over scanline)
LoopOverscan:
    STA WSYNC       ; wait for the next scanline
    DEX             ; X--
    BNE LoopOverscan; loop while x != 0

    JMP NextFrame   ;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; complete my ROM size to 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFFC       ; defines origin to FFFC
    .word Start     ; reset vector at $FFFC (where program starts)
    .word Start     ; interrupt vector at $FFFE (unused in VCS)