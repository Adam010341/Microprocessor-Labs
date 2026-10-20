List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	movlw 0x6D;
	movwf 0x20;
	
	movlw b'10101010';even mask
	movwf 0x01;
	
	movlw b'01010101';odd mask
	movwf 0x02;
	
	;even mask, rotate right;
	movf 0x20, w;
	andwf 0x01, w;
	movwf 0x03;
	RRNCF 0x03, f;store temp value in 0x03;
	
	;odd mask, rotate left;
	movf 0x20, w;
	andwf 0x02, w;
	movwf 0x04;
	RLNCF 0x04, f;store temp value in 0x04;
	
	movf 0x04, w;
	addwf 0x03, w;
	
	movwf 0x21;
end
	