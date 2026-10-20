List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; ???0x00???????

	
	;testcase 0x3C7B, output 0xB7C3
	;;;;init high byte;;;;;;;;;;;;;;;
	movlw 0x2E
	movwf 0x00
	
	;;;;init low byte;;;;;;;;;;;;;;;
	movlw 0x5B
	movwf 0x01
	
	;;;;mask;;;;;;;;;;;;;;;;;;;;;;;;
	movlw 0xF0;
	movwf 0x05;0x05 = mask = 0xF0
	;;;;main;;;;;;;;;;;;;;;;;;;;;;;;
	;;0x02 = function argument
	;;0x03 = remainder
	;;0x04 = high byte
	
	;;;;;first word;;;;;;;;;;;;;;;;;;;;;;
	movff 0x00, 0x02 ; set high byte as argument
	RCALL division;
	RLNCF 0x03, f;
	RLNCF 0x03, f;
	RLNCF 0x03, f;
	RLNCF 0x03, f;
	movff 0x03, 0x11; move the result to 0x11
	;;;;;second word;;;;;;;;;;;;;;;;;;;;;
	movf 0x11, w;
	RRNCF 0x04, f;
	RRNCF 0x04, f;
	RRNCF 0x04, f;
	RRNCF 0x04, f;
	addwf 0x04,w;
	movwf 0x11;
	;movff 0x04, 0x02 ; 
	;RCALL division
	;movf 0x11,w;
	;addwf 0x03, f;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;third word;;;;;;;;;;;;;;;;;;;;;;
	movff 0x01, 0x02 ; set high byte as argument
	RCALL division;
	RLNCF 0x03, f;
	RLNCF 0x03, f;
	RLNCF 0x03, f;
	RLNCF 0x03, f;
	movff 0x03, 0x10; move the result to 0x11
	;;;;;forth word;;;;;;;;;;;;;;;;;;;;;
	movf 0x10, w;
	RRNCF 0x04, f;
	RRNCF 0x04, f;
	RRNCF 0x04, f;
	RRNCF 0x04, f;
	addwf 0x04,w;
	movwf 0x10;
	;movff 0x04, 0x02
	;RCALL division
	;movf 0x10, w;
	;addwf 0x03, f;
	
	GOTO terminate
	;;;;subroutine;;;;;;;;;;;;;;;;;;;
	division:
	    ;;0x02 = function argument
	    ;;0x03 = remainder
	    ;;0x04 = high byte
	    ;;;0x05 = AND mask = 0xF0
	    movf 0x02, w;
	    ;;;;mask the low bits;;;;;;;;;;;;;;
	    andwf 0x05, w;
	    ;;;;put quotient in 0x04;;;;;;;;;;;
	    movwf 0x04;
	    ;;;;;calculate remainder and return;;;;;;
	    subwf 0x02, f; 0x02 = 0x02 - high byte
	    movff 0x02, 0x03;
	return
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	terminate:
	GOTO terminate
end