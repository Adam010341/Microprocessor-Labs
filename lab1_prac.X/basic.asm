List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	
	movlw 0x0C;
	movwf 0x00;
	
	movlw 0x14;
	movwf 0x01;
	
	movlw 0x18;
	movwf 0x02;
	
	movlw 0x08;
	movwf 0x03;
	
	;;A1 = x1 + x2;
	movf 0x00, w;
	addwf 0x01, w;
	movwf 0x10;
	
	;;A2 = y1 + y2;
	movf 0x02, w;
	addwf 0x03, w;
	movwf 0x11;
	
	;;compare A1 and A2
	movf 0x11, w; put A1 in WREG;
	CPFSGT 0x10;skip if A1 > A2
	GOTO equal_less
	movlw 0x11;
	movwf 0x20;
	GOTO terminate;
	
	
	
	equal_less: ;A1 == < A2
	CPFSEQ 0x10; skip if A1 == A2
	GOTO less
	movlw 0x22;
	movwf 0x20;
	GOTO terminate
	
	less:
	movlw 0x33;
	movwf 0x20;
	
	terminate:
	GOTO terminate
    end