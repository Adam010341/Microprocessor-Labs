List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 

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
	
	movlw 0x00;
	movwf 0x00;
	
	movlw 0x04;
	movwf 0x01;
	
	movlw 0x00;
	movwf 0x02;
	
	movlw 0x10;
	movwf 0x03;
	
	comp_16bit 0x00, 0x01, 0x02, 0x03, 0x04;
	
    end