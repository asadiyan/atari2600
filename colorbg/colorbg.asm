    PROCESSOR 6502

    INCLUDE "vcs.h"
    INCLUDE "macro.h"

    SEG code
    ORG $F000       ; defines the origin of ROM at $F000

START:
    CLEAN_START     ; tells macro to safely clear the memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set background luminosity color to yellow 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LABLE:
    LDA #$1E        ; load color in to A (#$1E is NTCS yellow)
    STA COLUBK      ; store A to background color memory address $09

    JMP LABLE       ; repeat from start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; fill ROM size to exactly 4KB 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC       ; defines origin to FFFC
    .word START     ; reset vector at $FFFC (where program starts)
    .word START     ; interrupt vector at $FFFE (unused in VCS)