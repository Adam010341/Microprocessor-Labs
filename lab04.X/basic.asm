List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; ???0x00???????
	
	Mul_Add macro x1, x2, y1, y2
	    
	    ;;;init x1 x2;;;;;;;;;;;;;;;;
	    movlw x1
	    movwf 0x00
	    
	    movlw x2
	    movwf 0x01
	    
	    
	    ;;; mult and store x1 x2;;;;;;;;;;;;;;;;
	    mulwf 0x00;
	    movff PRODL, 0x04;0x04 = low byte
	    movff PRODH, 0x05;0x05 = high byte
	    
	    
	    ;;;init y1 y2;;;;;;;;;;;;;;;;
	    movlw y1
	    movwf 0x02
	    
	    movlw y2
	    movwf 0x03
	    
	    ;;; mult and store y1 y2;;;;;;;;;;;;;;;;
	    mulwf 0x02;
	    movff PRODL, 0x06;0x06 = low byte
	    movff PRODH, 0x07;0x07 = high byte
	    
	    ;;;add the product;;;;;;;;;;;;;;;;;;;;;;
	    ;0x04 = low byte
	    ;0x05 = high byte
	    ;0x06 = low byte
	    ;0x07 = high byte
	    
	    ;;;add low byte;;;;;;;;;;;;;;;;;;;;;;;;;
	    movf 0x04, w;
	    addwf 0x06, w;
	    movwf 0x11;
	    
	    ;;;check carry;;;;;;;;;;;;;;;;;;;;;;;;;;
	    bnc no_carry; if no carry go to no_carry
	    incf 0x05
	    no_carry:
	    ;;;add high byte and carry;;;;;;;;;;;;;;;
	    movf 0x05, w;
	    addwf 0x07, w;
	    movwf 0x10;
	endm
	
	Mul_Add 0x48,0x06,0x5A,0x04
	
	terminate:
	GOTO terminate
end