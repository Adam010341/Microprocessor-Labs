List p=18f4520 ;???PIC18F4520
    ;???PIC18F
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ; ???0x00???????
	
	movlf macro literal, f
	    movlw literal;
	    movwf f;
	endm
	
	Mul_Add macro x1, x2, x3, x4, y1, y2, y3, y4  ;(x1 x2 / x3 x4) + (y1 y2 / y3 y4) 
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    ;A/B + C/D
	    ;(x1 x2 / x3 x4) + (y1 y2 / y3 y4) 
	    ;A * D + C * B  
	    ;x1 * y3 + x1 * y4 + x2 * y3
	    ;y1 * x3 + y1 * x4 + y2 * x3
	    ;output address:
		;0x20 0x21 = numerator
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    
	    ;first mult
	    ;x1 * y3 + x1 * y4 + x2 * y3
	    ;;; mult and store x1 y3;;;;;;;;;;;;;;;;
	    movf x1, w;
	    mulwf y3;
	    movff PRODL, 0x30;0x30 = low byte
	    movff PRODH, 0x31;0x31 = high byte
	    movff 0x30, 0x20;
	    
	    ;;; mult and store x1 y4;;;;;;;;;;;;;;;;
	    movf x1, w;
	    mulwf y4;
	    movff PRODL, 0x32; 0x32 = high byte
	    
	    ;;; mult and store x2 y3;;;;;;;;;;;;;;;;
	    movf x2, w;
	    mulwf y3;
	    movff PRODL, 0x33; 0x33 = high byte
	    
	    ;;;add the product of first mult (only add high byte);;;;;;;;;;;;;;;;;;;;;;
	    movf 0x31, w;
	    addwf 0x32, w;
	    addwf 0x33, w;
	    movwf 0x21;
	    
	    ;second mult
	    ;y1 * x3 + y1 * x4 + y2 * x3
	    ;;; mult and store x1 y3;;;;;;;;;;;;;;;;
	    movf y1, w;
	    mulwf x3;
	    movff PRODL, 0x30;0x30 = low byte
	    movff PRODH, 0x31;0x31 = high byte
	    
	    ;;; mult and store x1 y4;;;;;;;;;;;;;;;;
	    movf y1 ,w;
	    mulwf x4;
	    movff PRODL, 0x32; 0x32 = high byte
	    
	    ;;; mult and store x2 y3;;;;;;;;;;;;;;;;
	    movf y2, w;
	    mulwf x3;
	    movff PRODL, 0x33; 0x33 = high byte
	    
	    ;;;add the high byte product of two mult ;;;;;;;;;;;;;;;;;;;;;;
	    movf 0x31, w;
	    addwf 0x32, w;
	    addwf 0x33, w;
	    addwf 0x21, f; first high + second high
	    
	    ;;;add the low byte of pproduct of two mult;;;;;;;;;;;;;;;;;;;;
	    movf 0x30, w;
	    addwf 0x20, f; 
	    
	    ;;;check carry;;;;;;;;;;;;;;;;;;;;;;;;;;
	    bnc no_carry; if no carry go to no_carry
	    incf 0x21
	    no_carry:
	endm
	
	Mul_Sub macro x1, x2, x3, x4, y1, y2, y3, y4  ;(x1 x2 / x3 x4) + (y1 y2 / y3 y4) 
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    ;A/B - C/D
	    ;(x1 x2 / x3 x4) - (y1 y2 / y3 y4) 
	    ;A * D - C * B  
	    ;x1 * y3 + x1 * y4 + x2 * y3
	    ;y1 * x3 + y1 * x4 + y2 * x3
	    ;output address:
		;0x22 0x23 = numerator
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    
	    ;;;;;;;;;;;;;;;;;;;;;;;;;first mult;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	    ;x1 * y3 + x1 * y4 + x2 * y3
	    ;;; mult and store x1 y3;;;;;;;;;;;;;;;;
	    movf x1, w;
	    mulwf y3;
	    movff PRODL, 0x30;0x30 = low byte
	    movff PRODH, 0x31;0x31 = high byte
	    movff 0x30, 0x20;
	    
	    ;;; mult and store x1 y4;;;;;;;;;;;;;;;;
	    movf x1, w;
	    mulwf y4;
	    movff PRODL, 0x32; 0x32 = high byte
	    
	    ;;; mult and store x2 y3;;;;;;;;;;;;;;;;
	    movf x2, w;
	    mulwf y3;
	    movff PRODL, 0x33; 0x33 = high byte
	    
	    ;;;add the product of first mult (only add high byte);;;;;;;;;;;;;;;;;;;;;;
	    movf 0x31, w;
	    addwf 0x32, w;
	    addwf 0x33, w;
	    movwf 0x21;
	    
	    ;;;;;;;;;;;;;;;;;;;;;;;;;;second mult;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	    ;y1 * x3 + y1 * x4 + y2 * x3
	    ;;; mult and store x1 y3;;;;;;;;;;;;;;;;
	    movf y1, w;
	    mulwf x3;
	    movff PRODL, 0x30;0x30 = low byte
	    movff PRODH, 0x31;0x31 = high byte
	    
	    ;;; mult and store x1 y4;;;;;;;;;;;;;;;;
	    movf y1 ,w;
	    mulwf x4;
	    movff PRODL, 0x32; 0x32 = high byte
	    
	    ;;; mult and store x2 y3;;;;;;;;;;;;;;;;
	    movf y2, w;
	    mulwf x3;
	    movff PRODL, 0x33; 0x33 = high byte
	    
	    ;;; Do 2's complement on the first/second product;;;;;;;;;;;;;;;;;;;;
	    movf 0x31, w;
	    addwf 0x32, w;
	    addwf 0x33, f;
	    movlw 0xFF; flipper
	    xorwf 0x33, f;
	    xorwf 0x30, f;
	    incf 0x30;
	    bnc no_carry_sub
	    incf 0x33;
	    no_carry_sub:
	    movf 0x33, w;
	    ;;;add the high byte product of two mult ;;;;;;;;;;;;;;;;;;;;;;
	    addwf 0x21, f; first high + (-second high)
	    
	    ;;;add the low byte of pproduct of two mult;;;;;;;;;;;;;;;;;;;;
	    movf 0x30, w;
	    addwf 0x20, f; 
	    
	    ;;;check carry;;;;;;;;;;;;;;;;;;;;;;;;;;
	    bnc no_carry_sub2; if no carry go to no_carry
	    incf 0x21
	    no_carry_sub2:
	endm
	
	Sub_16bit macro x1, x2, y1, y2 ;;;0x22 = low byte, 0x23 = high byte, y1 y2 is the bigger one
	    ;;; do 2's complement on y1*y2;;;;;;;;;
	    ;intermediate register
		;0x54 = x1;
		;0x55 = x2;
	    movff x1, 0x54
	    movff x2, 0x55
	    movlw 0xFF; flipper
	    xorwf 0x54, f;
	    xorwf 0x55, f;
	    INCF 0x54;
	    bnc no_carry_sub_16bit
	    incf 0x71;
	    no_carry_sub_16bit:
	    ;;;add the product;;;;;;;;;;;;;;;;;;;;;;
	    ;0x04 = low byte
	    ;0x05 = high byte
	    ;0x06 = low byte
	    ;0x07 = high byte
	    
	    ;;;add low byte;;;;;;;;;;;;;;;;;;;;;;;;;
	    movf y1, w;
	    addwf 0x54, w;
	    movwf 0x22;
	    
	    ;;;check carry;;;;;;;;;;;;;;;;;;;;;;;;;;
	    bnc no_carry_sub_16bit2; if no carry go to no_carry
	    incf y2
	    no_carry_sub_16bit2:
	    ;;;add high byte and carry;;;;;;;;;;;;;;;
	    movf y2, w;
	    addwf 0x55, w;
	    movwf 0x23;
	endm
	
	compareAndswap macro x1, x2, y1, y2
	    local hi_differs, do_swap, no_swap
	    movf y2, w
	    cpfseq x2 ; skip if x2 == y2 
	    bra hi_differs
	    movf y1, w        
	    cpfsgt x1 ; skip if x1 > y1        
	    goto no_swap
	    goto do_swap
	hi_differs:
	    movf y2, w
	    cpfsgt x2; skip if x2 > y2      
	    goto no_swap
	do_swap:
	    movf x1, w
	    movff y1, x1
	    movwf y1
	    movf x2, w
	    movff y2, x2
	    movwf y2
	no_swap:
	endm
	
	division macro x1, x2, div_low, div_high
	    local loop_division, no_carry_division, no_carry_division2, check_x2, terminate_division
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    ;x1 x2 / div_low div_high
	    ;intermediate address
		;accumulator 0x50, 0x51 (low high)
		;0x52 = div_low
		;0x53 = div_high
	    ;output address: 
		;x1,x2
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    ;;;do 2's complement on div_low
	    clrf 0x50 
	    clrf 0x51
	    movff div_low, 0x52;
	    movff div_high, 0x53;
	    movlw 0xFF; flipper
	    xorwf 0x52, f;
	    xorwf 0x53, f;
	    INCF 0x52;
	    bnc loop_division;
	    incf 0x61;
	    loop_division:
		;;;add low byte;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		movf 0x52, w;
		addwf x1, f; x1 = x1 - div_low
		;;;check carry;;;;;;;;;;;;;;;;;;;;;;;;;;
		bnc no_carry_division; if no carry go to no_carry
		incf x2
		no_carry_division:
		;;;add high byte;;;;;;;;;;;;;;;;;;;;
		movf 0x53, w;
		addwf x2, f; 
		;;;accumulator ++;;;;;;;;;;;;;;;;;;
		incf 0x50;
		bnc no_carry_division2
		incf 0x51;
		no_carry_division2:
		;;;check if x1 and x2 are zero;;;;;;
		decf x1;
		incf x1;
		bz check_x2
		GOTO loop_division
		check_x2:
		decf x2;
		incf x2
		bz terminate_division
		GOTO loop_division
	    terminate_division:
	    movff 0x50, x1;
	    movff 0x51, x2;
	endm
	
	Mul_16bit macro x1,x2,y1,y2 ;low high low high
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    ;X * Y
	    ;(x1 x2)* (y1 y2)
	    ;low = 0x24 = x1 * y1 (low) 
	    ;high = 0x25 = x1 * y1 (high) + x1 * y2 (low) + x2 * y1 (low)
	    ;output address:
		;0x24 0x25 low high
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    
	    ;low = 0x24 = x1 * y1 (low) 
	    movf x1, w;
	    mulwf y1;
	    movff PRODL, 0x24;0x30 = low byte
	    movff PRODH, 0x31;0x31 = high byte
	    
	    ;high = 0x25 = 0x25 (x1 * y1 (high)) + x1 * y2 (low) + x2 * y1 (low);;;;;;;;;;;;;;;;
	    movf x1, w;
	    mulwf y2;
	    movff PRODL, 0x32; 0x32 = high byte
	    
	    ;;; mult and store x2 y3;;;;;;;;;;;;;;;;
	    movf x2, w;
	    mulwf y1;
	    movff PRODL, 0x33; 0x33 = high byte
	    
	    ;;;add the product of first mult (only add high byte);;;;;;;;;;;;;;;;;;;;;;
	    movf 0x31, w;
	    addwf 0x32, w;
	    addwf 0x33, w;
	    movwf 0x25;
	endm
	;;;;;;;;;;;;;;;;;;;;;macro end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;macro end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;macro end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;macro end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;;;;;;;;;;;;;;;;;;;macro end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;;init variable;;;;;;;;;;;;;;;;;;;;;
	;;;A/B op1 C/D op2 E/F
	movlf 0x65, 0x00;A
	movlf 0x17, 0x01;B
	movlf 0x2E, 0x02;C
	movlf 0x0B, 0x03;D
	movlf 0xAB, 0x04;E
	movlf 0x3E, 0x05;F
	movlf 0x01, 0x06;op1
	movlf 0x00, 0x07;op2
	;;;0x10 = numerator ans high byte
	;;;0x11 = numerator ans low byte
	;;;0x12 = denominator ans high byte
	;;;0x13 = denominator ans low byte
	;;;;;;;;;;Determine precedence;;;;;;;;;;;;;;;;;;;;;;
	btfsc 0x06, 1    
	bra op1_op2
	btfss 0x07, 1 
	bra op1_op2
	bra op2_op1
	op1_op2:
	movff 0x06, 0x0E;
	movff 0x00, 0xA1; move A to 0xA1
	movff 0x01, 0xB1; move B to 0xB1
	movff 0x02, 0xC1; move C to 0xC1
	movff 0x03, 0xD1; move D to 0xD1
	RCALL fractionCalc;
	movff 0x07, 0x0E ; move op2 to ox0E
	movff 0xC1, 0xA1 ; move C1 to A1
	movff 0xC2, 0xA2 ; move C2 to A2
	movff 0xD1, 0xB1 ; move D1 to B1
	movff 0xD2, 0xB2 ; move D2 to B2
	movff 0x04, 0xC1 ; move E1 to C1
	movff 0x05, 0xD1 ; move F1 to D1
	clrf 0xC2
	clrf 0xD2
	RCALL fractionCalc
	GOTO answer
	
	op2_op1:
	movff 0x07, 0x0E
	movff 0x02, 0xA1; move C to 0xA1
	movff 0x03, 0xB1; move D to 0xB1
	movff 0x04, 0xC1; move E to 0xC1
	movff 0x05, 0xD1; move F to 0xD1
	RCALL fractionCalc;
	movff 0x06, 0x0E
	movff 0x00, 0xA1;
	movff 0x01, 0xB1;
	RCALL fractionCalc
	GOTO answer
	
	answer:
	movff 0xC2, 0x10;
	movff 0xC1, 0x11;
	movff 0xD2, 0x12;
	movff 0xD1, 0x13;
	GOTO terminate
	
	terminate:
	GOTO terminate
	
	fractionCalc: 
	;{numerator, denominator} = fractionCalc(A,B,C,D,op);
	;result will be stored in A/B;
	
	;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    ;A/B op C/D
	    ;input argument address: 
		;0xA1,0xA2,0xB1,0xB2,0x0E,0xC1,0xC2,0xD1,0xD2 
	    ;output address: 
		;0xC1,0xC2,0xD1,0xD2
	;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	

	    ;;;;;;;check op;;;;;;;;;;;;
	    INCF 0x0E;
	    DECF 0x0E;
	    bz ADD
	    DECF 0x0E
	    bz SUB
	    DECF 0x0E
	    bnz skip_MULT
	    goto MULT
	    skip_MULT:
	    DECF 0x0E
	    bnz finish
	    goto DIV
	    finish:
	return
	
	
	ADD:
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
		;A/B + C/D
		;input argument address: 
		    ;0xA1,0xA2,0xB1,0xB2,0x0E,0xC1,0xC2,0xD1,0xD2 
		;temporary address: 
		    ;0x20 = B * D low
		    ;0x21 = B * D high
		    ;{0x22,0x23} = Mul_Add 0x0A,0x0D,0x0C,0x0B
		;output address: 
		    ;C/D
		    ;(A1 A2 / B1 B2) + (C1 C2 / D1 D2) 
		    ;0xC1,0xC2, 0xD1, 0xD2
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;0x22 = B1 * D1 low;;;;;;;;;;;;;;;;;
	    movf 0xB1, w;
	    mulwf 0xD1;
	    movff PRODL, 0x22;
	    movff PRODH, 0x23;
	    ;;;;;;;;;;;;;;;;;;0x23 = 0x21 (B1 * D1 high) + B1 * D2 low + B2 * D1 low;;;;;;;;;;;;;;;;;
	    ;0x21 = 0x21 + A1 * D2 low
	    movf 0xB1, w;
	    mulwf 0xD2;
	    movf PRODL, w;
	    addwf 0x23, f;
	    ;0x21 = 0x21 + A2 * D1 low
	    movf 0xB2, w;
	    mulwf 0xD1;
	    movf PRODL, w;
	    addwf 0x23, f;
	    
	    ;;;;;;;;;;;;;;;;;{0x20,0x21} = Mul_Add 0x0A,0x0D,0x0C,0x0B and call GCD
	    Mul_Add 0xA1,0xA2,0xB1,0xB2,0xC1,0xC2,0xD1,0xD2 
	    RCALL GCD
	    ;;;;;;;;;;;;;set return value;;;;;;;;;;;;;;;;;;;;
	GOTO finish
	
	
	SUB:
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
		;A/B - C/D
		;input argument address: 
		    ;0xA1,0xA2,0xB1,0xB2,0x0E,0xC1,0xC2,0xD1,0xD2 
		;temporary address: 
		    ;0x20 = A1 * D1 low
		    ;0x21 = A1 * D1 high + A1 * D2 low + A2 * D1 low
		    ;{0x22,0x23} = Mul_Sub 0xA1,A2,B1,B2,C1,C2,D1,D2
		;output address: 
		    ;C/D
		    ;(A1 A2 / B1 B2) + (C1 C2 / D1 D2) 
		    ;0xC1,0xC2, 0xD1, 0xD2
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;0x22 = B1 * D1 low;;;;;;;;;;;;;;;;;
	    movf 0xB1, w;
	    mulwf 0xD1;
	    movff PRODL, 0x22;
	    movff PRODH, 0x23;
	    ;;;;;;;;;;;;;;;;;;0x23 = 0x21 (B1 * D1 high) + B1 * D2 low + B2 * D1 low;;;;;;;;;;;;;;;;;
	    ;0x21 = 0x21 + A1 * D2 low
	    movf 0xB1, w;
	    mulwf 0xD2;
	    movf PRODL, w;
	    addwf 0x23, f;
	    ;0x21 = 0x21 + A2 * D1 low
	    movf 0xB2, w;
	    mulwf 0xD1;
	    movf PRODL, w;
	    addwf 0x23, f;
	    
	    ;;;;;;;;;;;;;;;;;{0x20,0x21} = Mul_Add 0x0A,0x0D,0x0C,0x0B and call GCD
	    Mul_Sub 0xA1,0xA2,0xB1,0xB2,0xC1,0xC2,0xD1,0xD2 
	    RCALL GCD
	    ;;;;;;;;;;;;;set return value;;;;;;;;;;;;;;;;;;;;
	GOTO finish
	
	
	MULT:
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
		;A/B * C/D
		;input argument address: 
		    ;0xA1,0xA2, 0xB1,0xB2, 0x0E, 0xC1,0xC2, 0xD1,0xD2 
		;temporary address: 
		    ;0x20 = A * C low
		    ;0x21 = A * C high
		    ;0x22 = B * D low
		    ;0x23 = B * D high
		;output address: 
		    ;C/D
		    ;0xC1,0xC2, 0xD1,0xD2
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;;;0x20 = A * C low;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;;;0x21 = A * C high;;;;;;;;;;;;;;;;;;;
	    Mul_16bit 0xA1,0xA2, 0xC1, 0xC2
	    movff 0x24, 0x20;
	    movff 0x25, 0x21;
	    ;;;;;;;;;;;;;;;;;;;;;;0x22 = B * D low;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;;;;;0x23 = B * D high;;;;;;;;;;;;;;;;;;;;;	
	    Mul_16bit 0xB1, 0xB2, 0xD1, 0xD2
	    movff 0x24, 0x22;
	    movff 0x25, 0x23;
	    RCALL GCD
	GOTO finish
	
	
	DIV:
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
		;A/B * D/C
		;input argument address: 
		    ;0x0A, 0x0B, 0x0E, 0x0C, 0x0D 
		;temporary address: 
		    ;0x20 = A * D low
		    ;0x21 = A * D high
		    ;0x22 = B * C low
		    ;0x23 = B * C high
		;output address: 
		    ;C/D
		    ;0x0C, 0x0D
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;;;;;0x20 = A * D low;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;;;;;0x21 = A * D high;;;;;;;;;;;;;;;;;;;;;	
	    Mul_16bit 0xA1,0xA2, 0xD1, 0xD2
	    movff 0x24, 0x20;
	    movff 0x25, 0x21;
	    ;;;;;;;;;;;;;;;;;;;;;;0x22 = B * C low;;;;;;;;;;;;;;;;;;;;;	
	    ;;;;;;;;;;;;;;;;;;;;;;0x23 = B * C high;;;;;;;;;;;;;;;;;;;;;	
	    Mul_16bit 0xB1, 0xB2, 0xC1, 0xC2
	    movff 0x24, 0x22;
	    movff 0x25, 0x23;
	    RCALL GCD
	GOTO finish
	
	GCD:
	    ;greatest common divisor = GCD(numerator, denominator);
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    ;while a != b:
	    ;	if a > b:  
	    ;	    a = a - b
	    ;	else:
	    ;	    b = b - a
	    ;do simplification, return simplified C/D
	    ;input argument address: 
		;0x20 = A low
		;0x21 = A high
		;0x22 = B low
		;0x23 = B high
	    ;intermediate variable address:
		;A = smaller
		;B = bigger
		;0x20 = sub_16bit return lower
		;0x21 = sub_16bit return higher
		;0x24, 0x25, 0x26, 0x27 A low high B low high
	    ;output address: 
		;C/D
		;0xC1,0xC2, 0xD1, 0xD2
	    ;;;;;;;;;;;Define variable address;;;;;;;;;;;;;;;;;;;;;
	    movff 0x20, 0x24
	    movff 0x21, 0x25
	    movff 0x22, 0x26
	    movff 0x23, 0x27
	    movf 0x20, w;
	    subwf 0x22, w;
	    bnz inner_loop
	    movf 0x21, w;
	    subwf 0x23, w;
	    bnz inner_loop
	    GOTO simp
	    inner_loop:
		compareAndswap 0x20, 0x21, 0x22, 0x23 ; make B bigger A smaller
		Sub_16bit 0x20, 0x21, 0x22, 0x23 ; Do B - A
		movf 0x20, w;	
		subwf 0x22, w;
		bnz inner_loop
		movf 0x21, w;
		subwf 0x23, w;
		bnz inner_loop
	    simp:
		;0x20, 0x21 are the GCD (low high)
		division 0x24, 0x25, 0x20, 0x21;
		division 0x26, 0x27, 0x20, 0x21
		movff 0x24, 0xC1
		movff 0x25, 0xC2
		movff 0x26, 0xD1
		movff 0x27, 0xD2
	return
end