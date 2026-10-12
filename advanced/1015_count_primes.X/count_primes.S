#include"xc.inc"
GLOBAL _count_primes, _n, _m, count, _lo, _hi, temp1, temp2, temp3;
EXTRN _count_primes$0, _count_primes$1
    
PSECT udata_acs
_n: DS 2
_m: DS 2
count: DS 2
_lo: DS 2
_hi: DS 2
temp1: DS 1;
temp2: DS 2;
temp3: DS 1;
temp4: DS 2;
#define n_l _n
#define n_h (_n+1)
#define m_l _m
#define m_h (_m+1)
#define cnt_l count
#define cnt_h (count+1)
#define low_l _lo
#define low_h (_lo+1)
#define high_l _hi
#define high_h (_hi+1)
#define temp2_l temp2
#define temp2_h (temp2+1)
#define temp4_l temp4
#define temp4_h (temp4+1)
PSECT udata_bank1       ; 256 bytes ?? bank 1???????????
arr:   DS 256
    
PSECT primetbl, class=CODE, reloc=2
primes:
    DB 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67
    DB 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131, 137, 139
    DB 149, 151, 157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211, 223
    DB 227, 229, 233, 239, 241, 251
    DB 0      
    
PSECT mytext, local, class=CODE, reloc=2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;macros;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Add_16bit macro x1, x2, y1, y2 ;high low high low, stored in x
    movf y2, w, a;
    addwf x2, f, a;
    bnc no_carry
    incf x1, f, a;
    no_carry:
    movf y1, w, a;
    addwf x1, f, a;
endm
    
Move_hilo_ptr macro hi_h, hi_l, lo_h, lo_l
    local no_carry, no_overflow
    ;low = high + 1
    movff hi_l, lo_l
    movff hi_h, lo_h
    incf  lo_l, f, a
    bnc   no_carry
    incf  lo_h, f, a
    no_carry:
    ;high = low + 255 (16-bit add)
    movlw 0xFF
    addwf lo_l, w, a
    movwf hi_l, a
    movlw 0
    addwfc lo_h, w, a
    movwf hi_h, a
    bnc   no_overflow
    setf  hi_h, a        ; if high > 65535 then high = 65535
    setf  hi_l, a
    no_overflow:
endm
    
comparePsquare macro x1, x2 ;;;prod high prod low
    local cps_exit, cps_ok
    movf  x1, w, a
    subwf m_h, w, a       
    bnc   cps_exit
    bnz   cps_ok          
    movf  x2, w, a
    subwf m_l, w, a        
    bc    cps_ok           
cps_exit:
    goto  finish_count_primes_segment
cps_ok:
endm

Sub_16bit macro x1, x2, y1, y2 ;high low high low, x - y, stored in x
    local no_carry, no_carry_twos
    ;x2 - y2
    movf   y2, w, a
    subwf  x2, f, a; x_l = x_l - y_l
    movf   y1, w, a
    subwfb x1, f, a; x_h = x_h - y_h - borrow
endm
    
compare_16bit macro x1, x2, y1, y2, out ; if x >= y : out == 1
    local cmp_done, cmp_ge
    clrf  out, a
    movf  y1, w, a
    subwf x1, w, a        
    bnc   cmp_done
    bnz   cmp_ge           ; x1 > y1
    movf  y2, w, a
    subwf x2, w, a        
    bnc   cmp_done
cmp_ge:
    incf  out, f, a
cmp_done:
endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;macro end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
_count_primes:
    ;;;;;;;;;;;;;;initialziation;;;;;;;;;;;;;;;;;
    ;;;;;;;;initialize table pointer;;;;;;;
    CLRF TBLPTRU, a;
    movlw high(primes);
    movwf TBLPTRH, a;
    movlw low(primes);
    movwf TBLPTRL, a;
    ;;;;;;;;initialize array pointer;;;;;;;;;;;;
    LFSR 0, arr; INDF0 points to arr
    LFSR 1, arr; INDF1 points to arr
    LFSR 2, arr;
    ;;;;;;;;initialize variable;;;;;;;;;;;
    movff _count_primes$0,     n_l
    movff (_count_primes$0+1), n_h
    movff _count_primes$1,     m_l
    movff (_count_primes$1+1), m_h
    clrf  cnt_l, a            ; count = 0 (the judge calls this function many times)
    clrf  cnt_h, a
    RCALL ClearArr            ; arr = all 0 (do not rely on RAM being 0)
    ; if n < 2 : n = 2  (0 and 1 are not prime)
    movf  n_h, w, a
    bnz   n_ok
    movlw 2
    cpfslt n_l, a             ; skip next if n_l < 2
    bra   n_ok
    movwf n_l, a
    n_ok:
    ; if m < n : return 0
    compare_16bit m_h, m_l, n_h, n_l, temp3   ; temp3 = (m >= n)
    btfss temp3, 0, a
    bra   cp_return
    ; high = n - 1, then "loop" sets low = high + 1, high = low + 255 (saturated)
    movff n_l, high_l
    movff n_h, high_h
    movlw 1
    subwf high_l, f, a
    movlw 0
    subwfb high_h, f, a
    GOTO  loop
    ;movff m_l, high_l; high = n
    ;movff m_h, high_h; high = n
    ;Move_hilo_ptr high_h, high_l, low_h, low_l;
    ;decf low_l;
    ;bnc no_carry
    ;decf low_h;
    ;no_carry:
    ;decf high_l;
    ;bnc no_carry2
    ;decf high_h;
    ;no_carry2:
    loop:
	;;;;;;;;;;;move high low pointer foward;;;;;;;;;;;;;
	Move_hilo_ptr high_h, high_l, low_h, low_l;
	first_loop:
	RCALL check_high_ptr
	RCALL count_primes_segment
	;;;;;;;;;;;check array to increase count;;;;;;;;;;;;
	finishedAllPrimes:
	RCALL CountAndResetArray
	;;;;;;;;;;;check terminate condition;;;;;;;;;;;;;;;;
	movf high_h, w, a;
	subwf m_h, w, a; m_h - high_h
	bnz loop
	movf high_l, w, a;
	subwf m_l, w, a; m_l - high_l;
	bnz loop
	; return count as answer;
	cp_return:
	movff cnt_l, _count_primes$0;
	movff cnt_h, (_count_primes$0+1)
    return
    
    count_primes_segment:
	;count_primes_segment(n,m):
	;for each prime 'p', if p * p < m, iterate through all the multiples of p
	;for p in {2 ~ 251}:
	;   if p * p > m : return
	;   start = first multiple of p that's >=n
	;   if start < p * p : start= = p * p 
	;	for(x = p ; x <= m ; x += p){
	;	    arr[x] = 1; (0 = prime, 1 = not prime)
	;	}
	CLRF temp1, a; 
	CLRF temp2_l, a;
	CLRF temp2_h, a;
	CLRF TBLPTRU, a
	movlw high(primes)
	movwf TBLPTRH, a
	movlw low(primes)
	movwf TBLPTRL, a
	next_prime:
	    TBLRD*+; read prime
	    MOVF  TABLAT, W, a; W = p
	    movwf temp1, a; temp1 = p
	    movwf temp2_l, a; temp2 = p = stsart
	    clrf  temp2_h, a;

	    ;if p * p > m : return
	    mulwf temp2_l, a; p * p
	    comparePsquare PRODH, PRODL;
	    ;start = first multiple of p that's >=n
	    TSTFSZ temp1, a;
	    GOTO setStart;
	    return
	setStart: ;temp2 = start
	    compare_16bit temp2_h, temp2_l, low_h, low_l, temp3 ;if x >= y : out ==1
	    btfsc temp3, 0, a;
	    GOTO finishSetStart; branch if start >= n
	    ;start = start + p;
	    movf temp1, w, a;
	    addwf temp2_l, f, a;
	    bnc no_carry_setStart
	    incf temp2_h, f, a
	    bz finish_count_primes_segment ; start > 65535: no multiple in range
	    no_carry_setStart:
	    GOTO setStart;
	finishSetStart:
	    ;if start < p * p : start = p * p 
	    compare_16bit temp2_h, temp2_l, PRODH, PRODL, temp3; if start >= p * p : out ==1
	    ;if out == 0, set start = p * p
	    btfsc temp3, 0, a; 
	    GOTO finishSetStartSquare; branch if start >= n
	    movff PRODL, temp2_l;
	    movff PRODH, temp2_h; temp2 = start;
	finishSetStartSquare:;INDF2 moves forward, INDF0 stays at head
	    ;for x = start; x <= m; x += p:
	    ;	mark[start - lo] = 1
	    movff temp2_l, temp4_l;
	    movff temp2_h, temp4_h;
	    Sub_16bit temp4_h, temp4_l, low_h, low_l; start - lo
	    ;arr = arr + (start - lo)
	    movf FSR0L, w, a;
	    addwf temp4_l, w, a;
	    movwf FSR2L, a;
	    bnc no_carry_startlo
	    incf temp4_h, f, a;
	    no_carry_startlo:
	    movf FSR0H, w, a;
	    addwf temp4_h, w, a;
	    movwf FSR2H, a;
	    compare_16bit high_h, high_l, temp2_h, temp2_l, temp3 ; if m >= start : out == 1
	    btfss temp3, 0, a; skip if temp3 == 0
	    GOTO finish_count_primes_segment; branch if start > m
	    ;x += p
	    movf temp1, w, a;
	    addwf temp2_l, f, a;
	    bnc no_carry_finishSquare
	    incf temp2_h, f, a;
	    bnz no_carry_finishSquare
	    bsf INDF2, 0, a        ; x + p > 65535: mark current x, then stop
	    GOTO finish_count_primes_segment
	    no_carry_finishSquare:
	    ;ark[x - n] = 1
	    bsf INDF2, 0, a;
	    ; temp 1 = p
	    movf temp1, w, a;;
	    ; arr = arr + p
	    addwf FSR2L, f, a
	    bnc finishSetStartSquare
	    incf FSR2H, f, a;
	    bra finishSetStartSquare
	finish_count_primes_segment:
	    movff FSR0H, FSR1H;
	    movff FSR0L, FSR1L;
	    movff FSR0H, FSR2H;
	    movff FSR0L, FSR2L;
	    GOTO next_prime
    
    CountAndResetArray:
	movff high_l, temp4_l
	movff high_h, temp4_h
	Sub_16bit temp4_h, temp4_l, low_h, low_l     ; temp4 = hi - lo
	LFSR 2, arr
	clrf  temp1, a
	count_loop:
	    movf  POSTINC2, w, a
	    bnz   not_prime_entry
	    incf  cnt_l, f, a
	    bnc   not_prime_entry
	    incf  cnt_h, f, a
	    not_prime_entry:
	    movf  temp4_l, w, a
	    cpfseq temp1, a
	    bra   count_next
	    bra   count_done
	    count_next:
	    incf  temp1, f, a
	    bra   count_loop
	count_done:
	LFSR 1, arr
	clrf  temp1, a
	clear_loop:
	    clrf  POSTINC1, a
	    decfsz temp1, f, a
	    bra   clear_loop
	LFSR 2, arr
    return
    
    ClearArr:
	LFSR 1, arr
	clrf  temp1, a
	clr_arr_loop:
	    clrf  POSTINC1, a
	    decfsz temp1, f, a
	    bra   clr_arr_loop
    return

    check_high_ptr:
	movf  m_h, w, a
	subwf high_h, w, a     
	bnc   finish_check     
	bnz   setAsEqual       
	movf  m_l, w, a
	subwf high_l, w, a    
	bnc   finish_check      
	setAsEqual:
	movff m_h, high_h
	movff m_l, high_l
	finish_check:
    return
    
    
    // ????????
    ;count_primes(n, m):
	// 1. ???????
	;for x = n to m:
	 ;   mark[x - n] = 1

	// 2. ????????
	;for p in {2, 3, 5, 7, 11, ..., 251}:
	;    if p * p > m: break              // p ???????
	;    start = ?>= n ???? p ????
	;    if start < p * p: start = p * p  // ??? p ????
	;   for x = start; x <= m; x += p:
	;	mark[x - n] = 0

	// 3. 1 ????
	;if n == 1: mark[0] = 0

	// 4. ???? 1
    ;return mark ? 1 ???
