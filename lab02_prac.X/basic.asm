List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ;
	
	LFSR 0, 0x140;
	LFSR 1, 0x141;
	LFSR 2, 0x142;
	
	movlw 0x05;
	movwf INDF0;addr - 3
	
	movlw 0x1E;
	movwf INDF1;addr - 2
	
	movlw 0x15;
	movwf INDF2;addr - 1
	
	; 0x01 = loop counter = 4
	movlw 0x04;
	movwf 0x01;
	
	loop:
	decf 0x01;
	bz terminate
	btfsc INDF2, 0; skip if addr - 1 == even
	GOTO odd;
	movf POSTINC0, w;
	addwf POSTINC1, w;
	addwf POSTINC2, w;
	movwf INDF2;
	GOTO loop
	
	odd:
	movf POSTINC2, w;
	subwf POSTINC1, w;
	movwf INDF2;
	incf FSR0L, f;
	GOTO loop
	
	terminate:
	GOTO terminate
end