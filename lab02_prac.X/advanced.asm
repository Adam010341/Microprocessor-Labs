List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; 
	;;set BSR
	movlb 0x02;
	;;first sequence
	movlw 0x05;
	movwf 0x00, 1;
	movlw 0x1A;
	movwf 0x01, 1;
	movlw 0x2C;
	movwf 0x02, 1;
	movlw 0x40;
	movwf 0x03, 1;
	movlw 0x7E;
	movwf 0x04, 1;
	movlw 0xA0;
	movwf 0x05, 1;
	;;second sequence
	movlw 0x06;
	movwf 0x10, 1;
	
	movlw 0x20;
	movwf 0x11, 1;
	
	movlw 0x33;
	movwf 0x12, 1;
	
	movlw 0x80;
	movwf 0x13, 1;
	
	movlw 0xF0;
	movwf 0x14, 1;
	;;set FSR;;;;;;;;;;
	LFSR 0, 0x200; sequence A head
	LFSR 1, 0x210; seuqnce B head
	LFSR 2, 0x230; temp_ans sequence head
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;set counter;;;;;;;;;
	movlw 0x06;
	movwf 0x00; 0x00 = sequence counter A;
	movlw 0x05;
	movwf 0x01; 0x01 = sequence counter B;
	movlw 0x011;
	movwf 0x02; 0x02 = reverse_ans counter
	
	loop:
	;;;;;compare A and B;;;;;;;;;;;;;
	movf INDF1, w;
	cpfsgt INDF0; skip if A > B;
	GOTO push_a;
	;;;;;Do append;;;;;;;;;;;;;;;;;;;
	movff POSTINC1, POSTINC2;
	decf 0x01;
	bz append_a;
	GOTO loop
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push_a:
	movff POSTINC0, POSTINC2;
	decf 0x00;
	bz append_b;
	GOTO loop
	
	append_a:
	movff POSTINC0, POSTINC2;
	decf 0x00;
	bz reverse_ans;
	GOTO append_a;
    
	append_b:
	movff POSTINC1, POSTINC2;
	decf 0x01;
	bz reverse_ans;
	GOTO append_b;
    
	reverse_ans:
	LFSR 1, 0x220; ans sequence head
	decf FSR2L;
	reverse_ans_loop:
	;LFSR 2 = temp_ans sequence head
	movff INDF2, POSTINC1;
	decf FSR2L;
	decf 0x02;
	bz terminate
	GOTO reverse_ans_loop;
	
	terminate:
	GOTO terminate	
end