List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	movlw 0x00;
	movwf 0x01; 0x01 = lower order byte
	
	movlw 0x01;
	movwf 0x00; 0x00 = higher order byte
	
	movlw 0xFF; 1111 1111
	movwf 0x02; 0x02 = inverter
	
	btfss 0x00,7; if positive
	GOTO positive
	
	movf 0x01,w; move lower byte to WREG
	xorwf 0x02, w; WREG xor 0xFF, sotred to WREG
	addlw 1; add one to lower byte
	movwf 0x11; move result to 0x10
	
	movf 0x00,w; move higher byte to WREG
	xorwf 0x02, w; WREG xor 0xFF, stored to WREG
	bnc no_carry
	addlw 1; if carry==1, add one to higher byte;
	no_carry:
	movwf 0x10; move result to 0x10
	GOTO terminate;
	
	;0x10 = answer (higher order byte)
	;0x11 = answer (lower order byte)
	
	positive:
	movff 0x01, 0x11;
	movff 0x00, 0x10;
	
	terminate:
	GOTO terminate
end
	


