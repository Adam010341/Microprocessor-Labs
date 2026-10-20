List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 

	Mul_Add macro x1,x2,y1,y2
	    movf x1, w;
	    mulwf x2;
	    
	    movff PRODH, 0x10;
	    movff PRODL, 0x11;
	    
	    movf y1, w;
	    mulwf y2;
	    
	    movf PRODL, w;
	    addwf 0x11, f;
	    
	    bnc no_carry
	    incf 0x10, f;
	    no_carry:
	    movf PRODH, w;
	    addwf 0x10, f;
	endm
	
	movlw 0xDC;
	movwf 0x00;
	
	movlw 0xA0;
	movwf 0x01;
	
	movlw 0xB0;
	movwf 0x02;
	
	movlw 0x30;
	movwf 0x03;
	
	Mul_Add 0x00, 0x01, 0x02, 0x03;
	
	terminate:
	GOTO terminate
end
	
 
 