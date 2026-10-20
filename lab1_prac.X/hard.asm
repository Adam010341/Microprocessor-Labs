List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	movlw b'01111100';
	movwf 0x00;
	movwf 0x01; 
	
	; 0x02 = loop counter = 9
	movlw 0x09;
	movwf 0x02;
	
	;0x03 = accumulator
	CLRF 0x03;
	
	;0x04 = max;
	CLRF 0x04;
	
	loop:
	decf 0x02;
	bz terminate
	rrcf 0x01;
	bc add_one
	GOTO compare_flush

	add_one:
	incf 0x03;
	GOTO loop
	
	compare_flush:
	movf 0x04, w;
	cpfsgt 0x03;skip if accumulator > max;
	GOTO flush_accumulator;flush if accumulator < max;
	movf 0x03, w;
	movwf 0x04;
	movlw 0x00;
	movwf 0x03;
	GOTO loop
	
	flush_accumulator:
	movlw 0x00;
	movwf 0x03;
	GOTO loop
	
	terminate:
	GOTO terminate
end

