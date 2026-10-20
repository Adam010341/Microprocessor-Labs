List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	Sub_16bit macro x1, x2, y1, y2; high low high low
	    local no_carry
	    movf y2, w;
	    subwf x2, f;x2 - y2
	    bc no_carry;
	    decf x1;
	    no_carry:
	    movf y1, w;
	    subwf x1, f;x1 - y1
	endm
	
	comp_16bit macro x1, x2, y1, y2, out; if x >= y out = 1 
	    local compare_low,set_one,set_zero, less_qual, finish;
	    CLRF out;
	    movf y1, w;
	    cpfsgt x1; skip if x1 > y1;
	    GOTO less_equal
	    GOTO set_one
	    
	    less_equal:
	    movf y1, w;
	    cpfslt x1; skip if x1 < y1;
	    GOTO equal
	    GOTO finish
	   
	    equal:
	    movf y2, w;
	    cpfslt x2; skip if x2 < y2;
	    GOTO set_one;
	    GOTO finish;
	    
	    set_one:
	    incf out, f;
	    finish:
	endm
	
	;;;set dividend;;;;;
	movlw 0x3C;
	movwf 0x00;
	movlw 0x7B;
	movwf 0x01;
	
	;;set divisor = 16;;;
	movlw 0x00;
	movwf 0x02;
	movlw 0x10;
	movwf 0x03;
	
	RCALL division
	movff 0x15, 0x10;
	RLNCF 0x10;
	RLNCF 0x10;
	RLNCF 0x10;
	RLNCF 0x10;
	RCALL division
	movf 0x15, w;
	addwf 0x10, f;
	
	RCALL division
	movff 0x15, 0x11;
	RLNCF 0x11;
	RLNCF 0x11;
	RLNCF 0x11;
	RLNCF 0x11;
	RCALL division
	movf 0x15, w;
	addwf 0x11, f;
	
	terminate:
	GOTO terminate
	
	
	division:
	    ;;;;;;;;;define variables;;;;;;;;;
	    ;input (A/B)
		;A = 0x00, 0x01, high low;
		;B = 0x02, 0x03, high low;
	    ;output
		;0x04 = quotient high
		;0x14 = quotient low
		;0x05 = remainder high
		;0x15 = remainder low
	    ;intermediate variable
		;A' = 0x06, 0x07, high low; used in sub_16bit
		;compare_flag = 0x08
	    CLRF 0x04;
	    CLRF 0x14;
	    CLRF 0x05;
	    CLRF 0x15;
	    loop:
		CLRF 0x08;
		comp_16bit 0x00, 0x01, 0x02, 0x03, 0x08; compare A and B, if A'>=B, 0x08 = 1
		btfss 0x08, 0;skip if 0x08 (flag) == 1;
		GOTO finish; if A < B: return
		Sub_16bit 0x00, 0x01, 0x02, 0x03;
		incf 0x14;
		bnc no_carry
		incf 0x04;
		no_carry:
		GOTO loop
	    finish:
		movff 0x00, 0x05;move A to remainder 0001 0010 0011 0100
		movff 0x01, 0x15;
		movff 0x04, 0x00;move quotient to A
		movff 0x14, 0x01;
	    return
end