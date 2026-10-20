List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	movlw b'10011001';
	movwf 0x00;
	movwf 0x02
	CLRF 0x10;
	
	; 0x01 = loop counter = 8
	movlw 0x08;
	movwf 0x01;
	
	loop:
	decf 0x01;
	bz last
	rrcf 0x02;
	bc push_one
	GOTO push_zero
	
	push_one:
	incf 0x10;
	rlncf 0x10;
	GOTO loop;
	
	push_zero:
	rlncf 0x10;
	GOTO loop;
	
	last:
	rrcf 0x02
	bc push_last_one
	GOTO compare
	
	push_last_one:
	incf 0x10;
	
	compare:
	movf 0x10, w;
	xorwf 0x00, w;
	bz equal
	GOTO not_equal
	
	equal:
	movlw 0xFF;
	movwf 0x11;
	GOTO terminate
	
	not_equal:
	movlw 0x00;
	movwf 0x11;
	
	terminate:
	GOTO terminate
end
