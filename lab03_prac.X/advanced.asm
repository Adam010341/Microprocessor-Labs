List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	;0x00 = high byte
	;0x01 = low byte
	movlw 0xFF;
	movwf 0x00;
	movwf 0x02;
	movlw 0x9C;
	movwf 0x01;
	movwf 0x03;
	
	btfss 0x00, 7; skip if negative
	GOTO positive;
	movlw 0xFF;
	xorwf 0x02, f;
	xorwf 0x03, f;
	incf 0x03, f;
	bnc no_carry
	incf 0x02;
	no_carry:
	movff 0x02, 0x10;
	movff 0x03, 0x11;
	GOTO terminate
	
	positive:
	movff 0x02, 0x10;
	movff 0x03, 0x11;
	
	terminate:
	GOTO terminate
end

