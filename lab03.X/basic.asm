List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	movlw 0x0F
	movwf 0x20 ; 0x20 = original, 0x21 = answer
	
	;mask even number = 1010 1010 = 0xAA
	movlw 0xAA
	movwf 0x00 ;mask even
	
	;mask odd number = 0101 0101 = 0x55
	movlw 0x55
	movwf 0x01 ;mask even
	
	
	;WERG = 0x20 & 0x00, then 0x21 | WREG  then rotate right,
	movf 0x20, w ; move 0x20 to WREG
	andwf 0x00, w; WREG & 0x00 (mask even number of 0x20), store to WREG
	iorwf 0x21, f; WREG | 0x21, store to 0x21
	RRNCF 0x21, f; 0x21 rotate right
	
	;WERG = 0x20 & 0x01, then 0x01 rotate left, then 0x21 | WREG
	movf 0x20, w ; move 0x20 to WREG
	andwf 0x01, f; 0x20 & 0x01 (mask odd number of 0x20), store to 0x01
	RLNCF 0x01, f; 0x01 rotate left
	movf 0x01, w; move 0x01 to WREG
	iorwf 0x21, f; WREG | 0x21
	
	sleep
end 