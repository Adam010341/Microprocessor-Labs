#include"xc.inc"
GLOBAL _gcd, first, second,  k
EXTRN _gcd$1, _gcd$0
   
PSECT udata_acs
first: DS 1
second: DS 1
k: DS 1
PSECT mytext, local, class=CODE, reloc=2
 
_gcd:
    movff _gcd$0, first;
    movff _gcd$1, second;
    
    div_both:
	//test if even
	BTFSC first, 0;skip if even
	GOTO div_first
	BTFSC second, 0; skip if even
	GOTO div_first;
	BCF STATUS, 0; clear carry
	RRCF first,f;
	BCF STATUS, 0; clear carry;
	RRCF second;
	INCF k, f;
	
	GOTO div_both

	
    div_first:
	BTFSC first, 0;skip if even
	GOTO loop
	BCF STATUS, 0;clear carry;
	RRCF first, f;
	
    loop:
	BTFSC second, 0;skip if even
	GOTO swap 
	BCF STATUS, 0;clear carry;
	RRCF second, f;
	GOTO loop
	
	swap: ; swap if b<a
	    movf first, w;
	    subwf second,w; b - a;
	    bnn subtract; goto b - a if b - a is non-negative
	    movf first, w;
	    movff second, first;
	    movwf second;
	    
	subtract:
	    movf first, w;
	    subwf second,f; b - a;
	    bz calc_answer
	    GOTO loop
	  
    calc_answer:
	incf k, f;
	decf k, f;
	bz finish
	double:
	    RLNCF first;
	    DECF k,f;
	    bnz double
    finish:
	movff first, _gcd$0;
    return
    
;gcd(a, b):             
;    k = 0
;
;    
;    while (a and b are both even):
;        a = a >> 1
;        b = b >> 1
;        k = k + 1;

    
;    while (a is even):
;        a = a >> 1
;
;    
;    loop:
;        while (b is even):  
;            b = b >> 1;

;        if a > b:    
;            swap(a, b);
;
;        b = b - a       
;        if b == 0:
;            break
;
;   return a << k