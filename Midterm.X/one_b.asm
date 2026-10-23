List p=18f4520 ;PIC18F4520
    #include<p18f4520.inc>
        CONFIG OSC = INTIO67
        CONFIG WDT = OFF
        org 0x00 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Common macros (lab1 ~ lab5)
; - 16bit arguments are always (high, low), same as test_1 / lab05
;   for lab04 style (low, high), swap the arguments yourself
; - all unsigned, except Neg_16bit / Abs_16bit
; - arguments must be in access bank (0x00 ~ 0x7F), BSR is not set
;   (movff works for any address)
; - temp registers use 0x6C ~ 0x7F, change the #define below if needed
; - if a macro calls other macros, copy those macros too
; - MPASM default radix is HEX, write decimal as .10 or D'10'
;
; Index:
;   Add_16bit, Sub_16bit
;   Mult_16bit
;   Mult_16bit_32
;   Div_16bit
;   Neg_16bit
;  Abs_16bit
;   Compare_16bit
;   Compare3_16bit
;   gcd_16bit
;   lcm_16bit
;   Frac_Reduce
;   Frac_Add
;   Frac_Sub
;   Frac_Mul
;   Frac_Div
;   Count_ones_8bit
;   Max_ones_8bit
;   Reverse_8bit
;   Sort_8bit
;
; lab05 style (pic-as):
;   replace #include<p18f4520.inc> with #include "xc.inc", remove CONFIG / org
;   replace the temp #define with:
;       PSECT udata_acs
;       M_L: DS 1
;       ... (DS 1 for each one)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; temp registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    #define M_L 0x6C ;Mult_16bit product low
    #define M_H 0x6D ;Mult_16bit product high
    #define G_K 0x6E ;gcd_16bit k (common power of 2)
    #define G_T 0x6F ;gcd_16bit compare result
    #define D_T 0x70 ;Div_16bit compare result
    #define D_C 0x71 ;Div_16bit loop counter
    #define R0 0x72 ;Frac_Reduce / lcm_16bit
    #define R1 0x73
    #define R2 0x74
    #define R3 0x75
    #define F0 0x76 ;Frac_Add / Frac_Sub
    #define F1 0x77
    #define F2 0x78
    #define F3 0x79
    #define S_I 0x7A ;Sort_8bit outer counter
    #define S_J 0x7B ;Sort_8bit inner counter
    #define S_T 0x7C ;Sort_8bit swap temp
    #define B_C 0x7D ;8bit macro loop counter
    #define B_T 0x7E ;8bit macro temp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16bit arithmetic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Add_16bit macro x1, x2, y1, y2 ;high low high low
    ;output: x = x + y (stored in x1 x2), y unchanged
    local no_carry
    movf y2, w;
    addwf x2, f;
    bnc no_carry
    incf x1, f;
    no_carry:
    movf y1, w;
    addwf x1, f;
endm

Sub_16bit macro x1, x2, y1, y2 ;high low high low
    ;output: x = x - y (stored in x1 x2), y unchanged
    local no_borrow
    movf y2, w;
    subwf x2, f;
    bc no_borrow
    decf x1, f;
    no_borrow:
    movf y1, w;
    subwf x1, f;
endm

Mult_16bit macro x1, x2, y1, y2 ;high low high low
    ;output: x = low 16bit of x * y (stored in x1 x2), y unchanged
    ;PROD_l = x2 * y2 low
    ;PROD_h = x2 * y2 high + x2 * y1 low + x1 * y2 low
    movf y2, w;
    mulwf x2;
    movff PRODL, M_L;
    movff PRODH, M_H;

    movf y1, w;
    mulwf x2;
    movf PRODL, w;
    addwf M_H, f;

    movf y2, w;
    mulwf x1;
    movf PRODL, w;
    addwf M_H, f;
    movff M_L, x2;
    movff M_H, x1;
endm

Mult_16bit_32 macro x1, x2, y1, y2, r3, r2, r1, r0 ;high low high low, r3 = highest byte
    ;output: r3 r2 r1 r0 = full 32bit x * y, x y unchanged (r must not overlap x y)
    ;r1 r0 = x2 * y2
    ;r3 r2 = x1 * y1
    ;r3 r2 r1 += x2 * y1 << 8
    ;r3 r2 r1 += x1 * y2 << 8
    local no_carry1, no_carry2, no_carry3, no_carry4
    movf y2, w;
    mulwf x2;
    movff PRODL, r0;
    movff PRODH, r1;

    movf y1, w;
    mulwf x1;
    movff PRODL, r2;
    movff PRODH, r3;

    movf y1, w;
    mulwf x2;
    movf PRODL, w;
    addwf r1, f;
    bnc no_carry1
    incf r2, f;
    bnc no_carry1
    incf r3, f;
    no_carry1:
    movf PRODH, w;
    addwf r2, f;
    bnc no_carry2
    incf r3, f;
    no_carry2:

    movf y2, w;
    mulwf x1;
    movf PRODL, w;
    addwf r1, f;
    bnc no_carry3
    incf r2, f;
    bnc no_carry3
    incf r3, f;
    no_carry3:
    movf PRODH, w;
    addwf r2, f;
    bnc no_carry4
    incf r3, f;
    no_carry4:
endm

Div_16bit macro x1, x2, y1, y2, r1, r2 ;high low high low high low
    ;output: x = x / y (quotient stored in x1 x2), r1 r2 = x % y (remainder), y unchanged
    ;if y = 0: x = 0xFFFF, r = original x
    ;long division: shift (r, x) left 1bit each time, if r >= y: r = r - y, quotient bit0 = 1
    local loop, do_sub, next
    clrf r1;
    clrf r2;
    movlw 0x10;
    movwf D_C; loop counter = 16
    loop:
    bcf STATUS, 0;
    rlcf x2, f;
    rlcf x1, f;
    rlcf r2, f;
    rlcf r1, f;
    bc do_sub; shift overflow means r must be >= y
    Compare_16bit r1, r2, y1, y2, D_T; if r >= y: D_T = 1
    btfss D_T, 0; skip if r >= y
    GOTO next
    do_sub:
    Sub_16bit r1, r2, y1, y2;
    incf x2, f; quotient bit0 = 1 (bit0 is always 0 after shift)
    next:
    decf D_C, f;
    bnz loop
endm

Neg_16bit macro x1, x2 ;high low
    ;output: x = -x (2's complement, stored in x1 x2)
    local no_carry
    movlw 0xFF; flipper
    xorwf x1, f;
    xorwf x2, f;
    incf x2, f;
    bnc no_carry
    incf x1, f;
    no_carry:
endm

Abs_16bit macro x1, x2 ;high low
    ;output: x = |x| (signed, stored in x1 x2)
    local positive
    btfss x1, 7; skip if negative
    GOTO positive
    Neg_16bit x1, x2;
    positive:
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16bit compare
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Compare_16bit macro a_h, a_l, b_h, b_l, out ;high low high low
    ;output: out = 1 if a >= b, out = 0 if a < b, a b unchanged
    local check_high, set_one, finish
    clrf out;
    movf b_h, w;
    cpfseq a_h; skip if a_h == b_h
    GOTO check_high
    movf b_l, w;
    cpfslt a_l; skip if a_l < b_l
    GOTO set_one
    GOTO finish
    check_high:
    cpfsgt a_h; skip if a_h > b_h (W = b_h)
    GOTO finish
    set_one:
    incf out, f;
    finish:
endm

Compare3_16bit macro a_h, a_l, b_h, b_l, out ;high low high low
    ;output: out = 0 if a < b, out = 1 if a == b, out = 2 if a > b, a b unchanged
    local check_high, check_low, is_greater, finish
    clrf out;
    movf b_h, w;
    cpfseq a_h; skip if a_h == b_h
    GOTO check_high
    movf b_l, w;
    cpfseq a_l; skip if a_l == b_l
    GOTO check_low
    incf out, f; a == b
    GOTO finish
    check_low:
    cpfsgt a_l; skip if a_l > b_l (W = b_l)
    GOTO finish
    GOTO is_greater
    check_high:
    cpfsgt a_h; skip if a_h > b_h (W = b_h)
    GOTO finish
    is_greater:
    incf out, f;
    incf out, f;
    finish:
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; gcd / lcm (needs Compare_16bit, Sub_16bit, Div_16bit, Mult_16bit)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

gcd_16bit macro a_h, a_l, b_h, b_l ;high low high low
    ;output: a = gcd(a, b) (stored in a_h a_l), b is destroyed
    ;gcd(0, b) = b, gcd(a, 0) = a
    ;binary gcd (lab05):
    ;    k = 0
    ;    while (a and b are both even): a >>= 1, b >>= 1, k++
    ;    while (a is even): a >>= 1
    ;    loop:
    ;        while (b is even): b >>= 1
    ;        if a > b: swap(a, b)
    ;        b = b - a
    ;        if b != 0: goto loop
    ;    return a << k
    local a_not_zero, div_both, div_first, main_loop, swap, subtract, calc_answer, double, finish
    ;;;;check zero;;;;;;;;;;;;;;;;;;;
    movf a_l, w;
    iorwf a_h, w;
    bnz a_not_zero
    movff b_l, a_l; a == 0, return b
    movff b_h, a_h;
    GOTO finish
    a_not_zero:
    movf b_l, w;
    iorwf b_h, w;
    bz finish; b == 0, return a
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    clrf G_K;

    div_both:
    btfsc a_l, 0; skip if even
    GOTO div_first
    btfsc b_l, 0; skip if even
    GOTO div_first
    bcf STATUS, 0;
    rrcf a_h, f;
    rrcf a_l, f;
    bcf STATUS, 0;
    rrcf b_h, f;
    rrcf b_l, f;
    incf G_K, f;
    GOTO div_both

    div_first:
    btfsc a_l, 0; skip if even
    GOTO main_loop
    bcf STATUS, 0;
    rrcf a_h, f;
    rrcf a_l, f;
    GOTO div_first

    main_loop:
    btfsc b_l, 0; skip if even
    GOTO swap
    bcf STATUS, 0;
    rrcf b_h, f;
    rrcf b_l, f;
    GOTO main_loop

    swap: ;if a > b: swap(a, b)
    Compare_16bit b_h, b_l, a_h, a_l, G_T; if b >= a: G_T = 1
    btfsc G_T, 0; skip if b < a
    GOTO subtract
    movf b_l, w;
    movff a_l, b_l;
    movwf a_l;
    movf b_h, w;
    movff a_h, b_h;
    movwf a_h;

    subtract: ;b = b - a, if b == 0: break
    Sub_16bit b_h, b_l, a_h, a_l;
    movf b_l, w;
    iorwf b_h, w;
    bz calc_answer
    GOTO main_loop

    calc_answer: ;a = a << k
    incf G_K, f;
    decf G_K, f;
    bz finish
    double:
    bcf STATUS, 0;
    rlcf a_l, f;
    rlcf a_h, f;
    decf G_K, f;
    bnz double
    finish:
endm

lcm_16bit macro a_h, a_l, b_h, b_l ;high low high low
    ;output: a = low 16bit of lcm(a, b) = a / gcd(a, b) * b (stored in a_h a_l), b unchanged
    movff a_h, R0;
    movff a_l, R1;
    movff b_h, R2;
    movff b_l, R3;
    gcd_16bit R0, R1, R2, R3; R0 R1 = gcd
    Div_16bit a_h, a_l, R0, R1, R2, R3; a = a / gcd
    Mult_16bit a_h, a_l, b_h, b_l; a = a * b
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; fraction (lab04 hard / test_1 do_op), A/B op C/D, reduced result stored back in A/B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Frac_Reduce macro n_h, n_l, d_h, d_l ;high low high low
    ;output: n/d reduced (n = n / gcd, d = d / gcd)
    movff n_h, R0;
    movff n_l, R1;
    movff d_h, R2;
    movff d_l, R3;
    gcd_16bit R0, R1, R2, R3; R0 R1 = gcd
    Div_16bit n_h, n_l, R0, R1, R2, R3; n = n / gcd
    Div_16bit d_h, d_l, R0, R1, R2, R3; d = d / gcd
endm

Frac_Add macro a_h, a_l, b_h, b_l, c_h, c_l, d_h, d_l ;A/B + C/D
    ;output: A/B = (A*D + C*B) / (B*D) reduced (stored in A B), C D unchanged
    movff a_h, F0;
    movff a_l, F1;
    Mult_16bit F0, F1, d_h, d_l; F0 F1 = A * D
    movff c_h, F2;
    movff c_l, F3;
    Mult_16bit F2, F3, b_h, b_l; F2 F3 = C * B
    Add_16bit F0, F1, F2, F3; F0 F1 = A * D + C * B
    Mult_16bit b_h, b_l, d_h, d_l; B = B * D
    movff F0, a_h;
    movff F1, a_l;
    Frac_Reduce a_h, a_l, b_h, b_l;
endm

Frac_Sub macro a_h, a_l, b_h, b_l, c_h, c_l, d_h, d_l ;A/B - C/D (requires A/B >= C/D)
    ;output: A/B = (A*D - C*B) / (B*D) reduced (stored in A B), C D unchanged
    movff a_h, F0;
    movff a_l, F1;
    Mult_16bit F0, F1, d_h, d_l; F0 F1 = A * D
    movff c_h, F2;
    movff c_l, F3;
    Mult_16bit F2, F3, b_h, b_l; F2 F3 = C * B
    Sub_16bit F0, F1, F2, F3; F0 F1 = A * D - C * B
    Mult_16bit b_h, b_l, d_h, d_l; B = B * D
    movff F0, a_h;
    movff F1, a_l;
    Frac_Reduce a_h, a_l, b_h, b_l;
endm

Frac_Mul macro a_h, a_l, b_h, b_l, c_h, c_l, d_h, d_l ;A/B * C/D
    ;output: A/B = (A*C) / (B*D) reduced (stored in A B), C D unchanged
    Mult_16bit a_h, a_l, c_h, c_l; A = A * C
    Mult_16bit b_h, b_l, d_h, d_l; B = B * D
    Frac_Reduce a_h, a_l, b_h, b_l;
endm

Frac_Div macro a_h, a_l, b_h, b_l, c_h, c_l, d_h, d_l ;A/B / C/D
    ;output: A/B = (A*D) / (B*C) reduced (stored in A B), C D unchanged
    Mult_16bit a_h, a_l, d_h, d_l; A = A * D
    Mult_16bit b_h, b_l, c_h, c_l; B = B * C
    Frac_Reduce a_h, a_l, b_h, b_l;
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 8bit / array (lab01, lab02)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Count_ones_8bit macro x, out
    ;output: out = number of 1 bits in x, x unchanged
    local loop
    clrf out;
    movlw 0x08;
    movwf B_C; loop counter = 8
    loop:
    btfsc x, 0; skip if bit0 == 0
    incf out, f;
    rrncf x, f; rotate 8 times -> x back to original
    decf B_C, f;
    bnz loop
endm

Max_ones_8bit macro x, out
    ;output: out = length of longest run of consecutive 1s in x (lab01 hard), x unchanged
    local loop, is_zero, next
    clrf out; max
    clrf B_T; current
    movlw 0x08;
    movwf B_C; loop counter = 8
    loop:
    btfss x, 0; skip if bit0 == 1
    GOTO is_zero
    incf B_T, f; current++
    movf B_T, w;
    cpfsgt out; skip if max > current
    movwf out; max = current
    GOTO next
    is_zero:
    clrf B_T; current = 0
    next:
    rrncf x, f; rotate 8 times -> x back to original
    decf B_C, f;
    bnz loop
endm

Reverse_8bit macro x, out
    ;output: out = x with bits reversed (bit0 <-> bit7 ...), x unchanged
    ;palindrome check: Reverse_8bit then compare with x (lab01 advanced)
    local loop
    movff x, B_T;
    movlw 0x08;
    movwf B_C; loop counter = 8
    loop:
    rrcf B_T, f; bit0 -> carry
    rlcf out, f; carry -> bit0
    decf B_C, f;
    bnz loop
endm

Sort_8bit macro addr, len ;addr = array start address (literal), len = length (literal, >= 2)
    ;output: addr ~ addr+len-1 sorted ascending (bubble sort, in place), uses FSR0
    ;for descending: change cpfslt INDF0 to cpfsgt INDF0
    ;NOTE: MPASM default radix is HEX, length 11 must be 0x0B or .11 (11 means 0x11)
    local outer, inner, no_swap, inner_done, finish
    movlw len - 1;
    movwf S_I; outer counter = len - 1
    outer:
    LFSR 0, addr;
    movff S_I, S_J; inner counter = S_I
    inner:
    movf POSTINC0, w; W = a[j], FSR0 -> a[j+1]
    cpfslt INDF0; skip if a[j+1] < a[j]
    GOTO no_swap
    movwf S_T; S_T = a[j]
    movf POSTDEC0, w; W = a[j+1], FSR0 -> a[j]
    movwf POSTINC0; a[j] = a[j+1], FSR0 -> a[j+1]
    movff S_T, INDF0; a[j+1] = old a[j]
    no_swap:
    dcfsnz S_J, f; skip if inner counter != 0
    GOTO inner_done
    GOTO inner
    inner_done:
    dcfsnz S_I, f; skip if outer counter != 0
    GOTO finish
    GOTO outer
    finish:
endm

movlf macro literal, f;
    movlw literal;
    movwf f;
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main (example, replace with the exam problem)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TRIANGULAR macro n, result; n = memory address of input value, result = memory address of output value
 ;0x30 = counter (1~n)
 local Tri_add, finish, loop
 CLRF 0x30;
 loop:
    incf 0x30;
    movf 0x30, w;
    cpfslt n; skip if n < 0x30;
    GOTO Tri_add
    GOTO finish
    
    Tri_add:
    addwf result, f;
    GOTO loop
 finish:
endm
    
   movlf 0x02, 0x00;
   movlf 0x09, 0x01;
   movlf 0x0F, 0x02;
    
    
    TRIANGULAR 0x00, 0x10;
    TRIANGULAR 0x01, 0x11;
    TRIANGULAR 0x02, 0x12;
 
    terminate:
    GOTO terminate
end



