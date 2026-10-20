LIST    P=18F4520
#include <p18f4520.inc>
CONFIG  OSC = INTIO67
CONFIG  WDT = OFF

        ORG     0x0000
        GOTO    start

        ORG     0x0020
start:
;---------------------------------------------------------------------
;       Instruction Start
;---------------------------------------------------------------------
        MOVLW   0x04
        MOVWF   0x00, ACCESS
        MOVLW   0x05
        MOVWF   0x01, ACCESS
        MOVLW   0x03
        MOVWF   0x02, ACCESS
        MOVLW   0x01
        MOVWF   0x03, ACCESS
        MOVLW   0x02
        MOVWF   0x04, ACCESS
        MOVLW   0x00
        MOVWF   0x05, ACCESS
;---------------------------------------------------------------------
;       Instruction End
;---------------------------------------------------------------------

; Enter your code here

	;;set initial PC;;;
	movlb 0x03; BSR = 3;
	movlw 0x00;
	movwf 0x00, 1; 0x300 = PC
	
	
	loop:
	;;;test PC;;;;;;;
	movlw 0xFE
	cpfslt 0x00, 1;skip if 0x300 < 0xFE
	GOTO terminate
    
	;;;set FSR;;;;;;;
	LFSR 0, 0x000;
	LFSR 1, 0x000;
	LFSR 2, 0x000;
	movf 0x00, w, 1; move PC to WREG
	addwf FSR0L, f; FSR0 address = PC address
	
	movf POSTINC0, w;
	addwf FSR1L, f; FSR1 = *PC = a
	movf POSTINC0, w;
	addwf FSR2L, f; FSR2 = *(PC+1) = b
	movf POSTINC0, w;
	LFSR 0, 0x000;
	addwf FSR0L, f; FSR0 = *(PC+2) = c
	
	movf INDF1, w;
	subwf INDF2, f; b = b - a;
	bz zero
	bnn positive
	zero:
	movff FSR0L, 0x300;
	GOTO loop
	
	positive:
	movlw 0x03;
	addwf 0x00, f, 1; 0x300 += 3; PC += 3
	bc terminate
	GOTO loop
	
	terminate:
	GOTO terminate
end