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
        MOVLW   0x0D
        MOVWF   0x00, ACCESS
        MOVLW   0x0D
        MOVWF   0x01, ACCESS
        MOVLW   0x03
        MOVWF   0x02, ACCESS
        MOVLW   0x0C
        MOVWF   0x03, ACCESS
        MOVLW   0x0D
        MOVWF   0x04, ACCESS
        MOVLW   0x06
        MOVWF   0x05, ACCESS

        MOVLW   0x0D
        MOVWF   0x06, ACCESS
        MOVLW   0x0E
        MOVWF   0x07, ACCESS
        MOVLW   0x09
        MOVWF   0x08, ACCESS
        MOVLW   0x0F
        MOVWF   0x09, ACCESS
        MOVLW   0x0F
        MOVWF   0x0A, ACCESS
        MOVLW   0xFF
        MOVWF   0x0B, ACCESS

        MOVLW   0x03
        MOVWF   0x0C, ACCESS
        MOVLW   0x10
        MOVWF   0x0D, ACCESS
        MOVLW   0x05
        MOVWF   0x0E, ACCESS
        MOVLW   0x00
        MOVWF   0x0F, ACCESS
;---------------------------------------------------------------------
;       Instruction End
;---------------------------------------------------------------------

; Enter your code here
	
	;;;;set PC;;;;;;;;;;;
	movlw 0x00;PC=0x00
	movlb 5; BSR=5
	movwf 0x00, 1; PC address = 0x500
	;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;set FSR to 0;;;;;
	LFSR 0, 0x00; FSR0=a
	LFSR 1, 0x00; FSR1=b
	LFSR 2, 0x00; FSR2=c
	;;;;;;;;;;;;;;;;;;;;;;;;
	
	main_loop:
    
	    ;;;;initialize FSR to destination address;;;
	    movf 0x00, w, 1;WREG = value inside address 0x500
	    movwf FSR2L;FSR2 = value inside address 0x500
	    
	    movf POSTINC2, w;WREG = value inside address INDF2;
	    movwf FSR0L;
	    
	    movf POSTINC2, w; 
	    movwf FSR1L;
	    
	    movf INDF2, w;
	    movwf FSR2L;
	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
	    ;;;; *b - *a;;;;;;;;;;;;;;;;;;;;;;;
	    movf INDF0,w; move FSR0 (a) to WREG
	    subwf INDF1, f; *b-*a, stored in b;
	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	    ;;;;;compare if *b - *a is negative;;;;;;;
    	    bn ZeroOrNegative;
	    bz ZeroOrNegative;
	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	    ;;;;;set PC=PC+3;;;;;;;;;;;;;;;;;;;;;;;;;
	    movf 0x00, w, 1; move 0x500 to WERG
	    addlw 3;[0x500]+=3
	    movwf 0x00, 1; move WREG to 0x500
	    bc terminate
	    ;movlb 0; set BSR = 0
	    
	    GOTO comparePC;
	    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;;;;set PC = C;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ZeroOrNegative:
	    movf FSR2L,w; set PC to address of C
	    movwf 0x00, 1;
	    ;movlb 0;
	    GOTO comparePC;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
	;;;Compare PC with 0xFE;;;;;;;;;;;;;;;;;;
	    comparePC:
	    movlw 0xFE;
	    subwf 0x00, w, 1; 0x500 - 0xFE;
	    ;movlb 0;
	    bc terminate
	    GOTO main_loop
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
	terminate:
	    GOTO terminate
    end
	