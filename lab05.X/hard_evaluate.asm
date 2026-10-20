#include "xc.inc"
GLOBAL _evaluate
EXTRN _evaluate$0, _evaluate$1, _evaluate$2, _evaluate$3, _evaluate$4, _evaluate$5, _evaluate$6
GLOBAL ax, bx, cx, dx, SUM, term,op, op1, op2, op3
 
PSECT udata_acs
    ax: DS 2
    bx: DS 2
    cx: DS 2
    dx: DS 2
    op: DS 1
    op1: DS 1
    op2: DS 1
    op3: DS 1
    PRODUCT: DS 2;
    SUM: DS 2;
    term: DS 2;
    ans: DS 2
    #define a_l ax
    #define a_h (ax+1)
    #define b_l bx
    #define b_h (bx+1)
    #define c_l cx
    #define c_h (cx+1)
    #define d_l dx
    #define d_h (dx+1)
    #define PROD_l PRODUCT
    #define PROD_h (PRODUCT+1)
    #define sum_l SUM
    #define sum_h (SUM+1)
    #define term_l term
    #define term_h (term+1)
    
PSECT mytext, local, class=CODE, reloc=2
 
Add_16bit macro x1, x2, y1, y2 ;high low high low, stored in x
    local no_carry
    movf y2, w;
    addwf x2, f;
    bnc no_carry
    incf x1;
    no_carry:
    movf y1,w;
    addwf x1, f;
endm
    
Sub_16bit macro x1, x2, y1, y2 ;high low high low, x - y, stored in x
    local no_carry, no_carry_twos
    ;take 2's complement of y
    movlw 0xFF;
    xorwf y2, f;
    xorwf y1, f;
    incf y2;
    bnc no_carry_twos
    incf y1;
    no_carry_twos:
    ;x2 - y2
    movf y2, w;
    addwf x2, f; x2 - y2
    bnc no_carry
    incf x1;
    no_carry:
    movf y1,w;
    addwf x1, f; x1 - y1
endm
    
Mult_16bit macro x1, x2, y1, y2 ;high low high low, x * y, stored in x
    local no_carry
    ;ans_low = x2 * y2
    movf y2, w;
    mulwf x2;
    movff PRODL, PROD_l;
    movff PRODH, PROD_h;
    
    ;ans_high = x1 * y2 (low) + x2 * y1 (low)
    mulwf x1;
    movf PRODL, w;
    addwf PROD_h, f;
    ;ans_high = x1 * y2 (low) + x2 * y1 (low)
    movf x2, w;
    mulwf y1;
    movf PRODL, w;
    addwf PROD_h, f;
    ;store answer in x
    movff PROD_l, x2;
    movff PROD_h, x1;
endm

;for each (op_x, x) pair ;;;; e.g. (op1, b)
	;if op_x equals '*', do 
	    ;term = term * x
	;else
	    ;add/subtract sum and term based on op
	    ;op = op_x;
	    ;term = x
evaluate_two macro x1, x2, op_x; high, low
    local do_add, do_sub, do_multiply, finish
    movf op_x ,w;
    xorlw '*'; 
    bz do_multiply
    
    movf op ,w;
    xorlw '+'; 
    bz do_add
    
    movf op ,w;
    xorlw '-'; 
    bz do_sub
    
    do_add:
	;op = op_x
	movff op_x, op;
	;add/subtract sum and term based on op
	Add_16bit sum_h,sum_l,term_h,term_l;
	;term = x
	movff x2, term_l;
	movff x1, term_h;
	GOTO finish
    do_sub:
	;op = op_x
	movff op_x, op;
	;add/subtract sum and term based on op
	Sub_16bit sum_h,sum_l,term_h,term_l;
	;term = x
	movff x2, term_l;
	movff x1, term_h;
	GOTO finish
    do_multiply:
	Mult_16bit term_h, term_l, x1, x2;
    finish:
endm
 
;extern unsigned int evaluate(unsigned int a, char op1, unsigned int b, char op2, unsigned int c, char op3, unsigned int d);
_evaluate:
    movff _evaluate$0, a_l;
    movff (_evaluate$0+1), a_h;
    movff _evaluate$2, b_l;
    movff (_evaluate$2+1), b_h;
    movff _evaluate$4, c_l;
    movff (_evaluate$4+1), c_h;
    movff _evaluate$6, d_l;
    movff (_evaluate$6+1), d_h;
    movff _evaluate$1, op1;
    movff _evaluate$3, op2;
    movff _evaluate$5, op3;
    
    ;(12, '+', 34, '*', 2, '*', 3) 
    ;a op1 b op2 c op3 d
    ;;;;initialize variable;;;;;;
    ;sum = 0;
    ;op = +
    ;term = a;
    clrf sum_l, a
    clrf sum_h, a
    movlw '+';
    movwf op;
    movff a_h, term_h;
    movff a_l, term_l;
    
    ;;;;Call function;;;;;;;;;;;;
    evaluate_two b_h, b_l, op1;
    evaluate_two c_h, c_l, op2;
    evaluate_two d_h, d_l, op3;
    
    movf op ,w;
    xorlw '+'; 
    bz do_add
    
    movf op ,w;
    xorlw '-'; 
    bz do_sub
    
    do_add:
	;add/subtract sum and term based on op
	Add_16bit sum_h,sum_l,term_h,term_l;
	GOTO finish
    do_sub:
	Sub_16bit sum_h,sum_l,term_h,term_l;
    finish:
   
    movff sum_l, _evaluate$0
    movff sum_h, (_evaluate$0+1)
return
end
    
    
   
    
	


