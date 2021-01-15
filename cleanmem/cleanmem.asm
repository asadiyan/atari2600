    PROCESSOR 6502

    SEG code    ;
    ORG $F000   ; Define the code origin at $F000

Start:          ; Lable
    SEI         ; Disable interrupts
    CLD         ; Disable the BCD(binary coded desimal) desimal math mode
    LDX #$FF    ; Loads the X register with #$FF
    TXS         ; Transfer the X register to the (S)tack pointer

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clear the page zero region ($00 to $FF)
; Meaning the entire RAM and also the entire TIA registers 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LDA #0      ; A = 0
    LDX #$FF    ; register X = #$FF
    STA $FF     ; make sure $FF zeroed before the loop starts
MemLoop:        ; Lable
    DEX         ; X--
    STA $0,X    ; Store the value of A inside memory address $0 + X
    BNE MemLoop ; loob until X is equal to zero (until zero flag set)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fill the ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ORG $FFFC   ;
    .word Start ; Reset vector at $FFFC (where the program starts)
    .word Start ; Interrupt vector at $FFFE (unused in the VCS)