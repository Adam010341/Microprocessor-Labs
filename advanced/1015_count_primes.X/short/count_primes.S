    // Algorithm: segmented sieve over odd numbers only, 255 numbers per segment
    ;count_primes(n, m):
	// 1. Edge cases
	;if n < 2: n = 2                          // 0 and 1 are not prime
	;if m < n: return 0
	;count = 0
	;if n == 2: count = 1                     // 2 is the only even prime, count it here

	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;first = n / 2                            // index of the first odd number >= n
	;last = (m - 1) / 2                       // index of the last odd number <= m
	;if last < first: return count            // no odd number in [n, m], e.g. (4,4)
	;first_seg = first / 255 ; first_idx = first % 255   // Half_div255
	;last_seg = last / 255   ; last_idx = last % 255
	;arr[0 ~ 254] = 0                         // 0 = maybe prime, 0xFF = composite
	;if first_seg != last_seg: arr[0 ~ first_idx-1] = 0xFF   // numbers below n in the first segment (markBelowN)

	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;for cur_seg = first_seg to last_seg:
	;    for p in {3, 5, 7, 11, ..., 251}:    // one row of primes per prime
	;        if p * p is in a later segment: break
	;        if p is not in next_arr[] yet:
	;            if p * p is in this segment: next[p] = (index of p * p) % 255
	;            else: next[p] = first odd multiple of p in this segment   // setStart: first segment only, multiply instead of divide
	;    for p in next_arr[]:
	;        for x = next[p]; x < 255; x += p:    // odd multiples are 2p apart, so indices are p apart
	;            arr[x] = 0xFF
	;        next[p] = x - 255                    // the next segment carries on from here, no new start point

	// 4. Count what was not crossed out in this segment (count_array)
	;    if cur_seg == last_seg:                  // last segment: only up to m (count_last)
	;        lo = (cur_seg == first_seg) ? first_idx : 0
	;        count += number of 0 in arr[lo ~ last_idx]   // the 0xFF entries add up to -(number of composites)
	;        return count
	;    count += number of 0 in arr[0 ~ 254]      // CountAndResetArray: numbers below n were crossed out in 2.
	;    arr[0 ~ 254] = 0                          // clear it for the next segment
    ;return count

; count_primes.S (short version) -- PIC18F4520, pic-as (XC8 v4.00)
;
;   extern unsigned int count_primes(unsigned int n, unsigned int m);
;
; Same idea as ../count_primes.S, written with loops instead of unrolled code:
; shorter and easier to read, roughly twice as many cycles.
;
; Segmented sieve over odd numbers only.
;   g = (v-1)/2       index of the odd number v (v = 2g+1)
;   segment K         g = 255K .. 255K+254, kept in arr positions 1..255
;                     (position = index in segment + 1, position 0 unused)
;   arr               all 256 bytes of bank 1, so it starts at a multiple of
;                     256 and FSR2L carries out exactly after position 255
;   entry             00h = maybe prime, FFh = composite
; For every odd prime p <= 251 whose multiples are being crossed out,
; next_arr[] holds p and the index of its next multiple. Marking a segment is
;   setf INDF2 / addwf FSR2L (+p) / bnc
; and when FSR2L carries, the value left in it is the index of the next
; multiple in the NEXT segment, so it is saved and reused as is.
; p starts being crossed out in the segment Kp that holds p*p (from p*p).
; Do not name anything seg: it is a reserved word in pic-as.

#include"xc.inc"
GLOBAL _count_primes, _n, _m, count, temp1, temp2, temp3;
EXTRN _count_primes$0, _count_primes$1
    
PSECT udata_acs
_n: DS 2;           n (made >= 2)
_m: DS 2;
count: DS 2;        answer
cur_seg: DS 1;      current segment K
first_seg: DS 1;    segment of the first odd number >= n
first_idx: DS 1;    ... and its index in that segment
last_seg: DS 1;     segment of the last odd number <= m
last_idx: DS 1;     ... and its index in that segment
prime_cnt: DS 1;    number of primes in next_arr[]
temp1: DS 1;        p (the prime being added in AddNewPrime)
temp2: DS 2;        scratch: Half_div255 input/output, AddNewPrime
temp3: DS 1;        loop counter
#define n_l _n
#define n_h (_n+1)
#define m_l _m
#define m_h (_m+1)
#define cnt_l count
#define cnt_h (count+1)
#define temp2_l temp2
#define temp2_h (temp2+1)
PSECT udata_bank1       ; 256 bytes = all of bank 1 (256-aligned)
arr:   DS 256
PSECT udata_bank2
next_arr: DS 106    ; 53 x [p, index of the next multiple of p]
    
; One row per odd prime p <= 251, in increasing order:
;   Kp, idx : segment and index of p*p  (divmod((p*p-1)/2, 255))
;   c       : 255 mod p
;   F       : ceil(c*65536/p), stored low byte first
; c and F give the start in the first segment without a division
; (AddNewPrime). The last row (Kp = 255) is never reached because K <= 128.
PSECT primetbl, class=CODE, reloc=2
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;    for p in {3, 5, 7, 11, ..., 251}:
primes:
    ;   Kp,   p, idx,   c, F_lo, F_hi
    DB   0,   3,   4,   0,   0,   0
    DB   0,   5,  12,   0,   0,   0
    DB   0,   7,  24,   3, 183, 109
    DB   0,  11,  60,   2, 140,  46
    DB   0,  13,  84,   8, 138, 157
    DB   0,  17, 144,   0,   0,   0
    DB   0,  19, 180,   8, 203, 107
    DB   1,  23,   9,   2,  67,  22
    DB   1,  29, 165,  23,   9, 203
    DB   1,  31, 225,   7, 207,  57
    DB   2,  37, 174,  33,  84, 228
    DB   3,  41,  75,   9,  50,  56
    DB   3,  43, 159,  40,  36, 238
    DB   4,  47,  84,  20, 240, 108
    DB   5,  53, 129,  43, 179, 207
    DB   6,  59, 210,  19, 113,  82
    DB   7,  61,  75,  11,  42,  46
    DB   8,  67, 204,  54,  85, 206
    DB   9,  71, 225,  42, 112, 151
    DB  10,  73, 114,  36,  64, 126
    DB  12,  79,  60,  18,  85,  58
    DB  13,  83, 129,   6, 130,  18
    DB  15,  89, 135,  77, 124, 221
    DB  18,  97, 114,  61, 254, 160
    DB  20, 101,   0,  53,  87, 134
    DB  20, 103, 204,  49, 202, 121
    DB  22, 107, 114,  41,  24,  98
    DB  23, 109,  75,  37, 231,  86
    DB  25, 113,   9,  29, 179,  65
    DB  31, 127, 159,   1,   5,   2
    DB  33, 131, 165, 124,  83, 242
    DB  36, 137, 204, 118, 128, 220
    DB  37, 139, 225, 116, 164, 213
    DB  43, 149, 135, 106,  31, 182
    DB  44, 151, 180, 104,  82, 176
    DB  48, 157,  84,  98, 204, 159
    DB  52, 163,  24,  92, 126, 144
    DB  54, 167, 174,  88, 230, 134
    DB  58, 173, 174,  82,  88, 121
    DB  62, 179, 210,  76, 178, 108
    DB  64, 181,  60,  74, 170, 104
    DB  71, 191, 135,  64, 200,  85
    DB  73, 193,   9,  62,  62,  82
    DB  76, 197,  24,  58,  95,  75
    DB  77, 199, 165,  56,  11,  72
    DB  87, 211,  75,  44,  99,  53
    DB  97, 223, 129,  32, 189,  36
    DB 101, 227,   9,  28, 148,  31
    DB 102, 229, 210,  26,  17,  29
    DB 106, 233, 114,  22,  44,  24
    DB 112, 239,   0,  16,  36,  17
    DB 113, 241, 225,  14, 224,  14
    DB 123, 251, 135,   4,  21,   4
    DB 255,   0,   0,   0,   0,   0

PSECT mytext, local, class=CODE, reloc=2

	// 1. Edge cases
	;if n < 2: n = 2
	;if m < n: return 0
	;count = 0
	;if n == 2: count = 1
_count_primes:
    movff   _count_primes$0, n_l
    movff   (_count_primes$0+1), n_h
    movff   _count_primes$1, m_l
    movff   (_count_primes$1+1), m_h
    clrf    cnt_l, a
    clrf    cnt_h, a
    ; n < 2  ->  n = 2
    movf    n_h, w, a
    bnz     n_ok
    movlw   2
    cpfslt  n_l, a                  ; skip if n_l < 2
    bra     n_ok
    movwf   n_l, a
	// 1. Edge cases
	;if m < n: return 0
	;if n == 2: count = 1
n_ok:
    ; m < n  ->  0
    movf    n_l, w, a
    subwf   m_l, w, a
    movf    n_h, w, a
    subwfb  m_h, w, a               ; C = (m >= n)
    bnc     cp_return
    ; 2 is the only even prime: count it here
    movf    n_h, w, a
    bnz     not_two
    movlw   2
    cpfseq  n_l, a
    bra     not_two
    incf    cnt_l, f, a
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;first = n / 2
	;last = (m - 1) / 2
	;if last < first: return count
	;first_seg = first / 255 ; first_idx = first % 255
	;last_seg = last / 255   ; last_idx = last % 255
not_two:
    ; last odd <= m:  g = (m-1)/2  ->  last_seg, last_idx
    movlw   1
    subwf   m_l, w, a
    movwf   temp2_l, a
    movlw   0
    subwfb  m_h, w, a
    movwf   temp2_h, a
    rcall   Half_div255
    movff   temp2_h, last_seg
    movff   temp2_l, last_idx
    ; first odd >= n:  g = n/2  ->  first_seg, first_idx
    movff   n_l, temp2_l
    movff   n_h, temp2_h
    rcall   Half_div255
    movff   temp2_h, first_seg
    movff   temp2_l, first_idx
    ; no odd number in [n, m] (e.g. n = m = 4)  ->  done
    movf    first_seg, w, a
    subwf   last_seg, w, a
    bnc     cp_return
    bnz     have_odd
    movf    first_idx, w, a
    subwf   last_idx, w, a
    bnc     cp_return
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;arr[0 ~ 254] = 0
have_odd:
    ; arr = all 00h (maybe prime)
    lfsr    0, arr+1
    movlw   255
    movwf   temp3, a
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;arr[0 ~ 254] = 0
clr_arr_loop:
    clrf    POSTINC0, a
    decfsz  temp3, f, a
    bra     clr_arr_loop
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;if first_seg != last_seg: arr[0 ~ first_idx-1] = 0xFF
    ; if the first segment is not also the last, cross out the numbers
    ; below n in it, so the full-segment count below can count all 255
    movf    first_seg, w, a
    cpfseq  last_seg, a
    bra     markBelowN
    bra     initLoop
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;if first_seg != last_seg: arr[0 ~ first_idx-1] = 0xFF
markBelowN:
    movf    first_idx, w, a
    bz      initLoop
    movwf   temp3, a
    lfsr    0, arr+1
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;if first_seg != last_seg: arr[0 ~ first_idx-1] = 0xFF
mark_below_loop:
    setf    POSTINC0, a
    decfsz  temp3, f, a
    bra     mark_below_loop
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;for cur_seg = first_seg to last_seg:
	;    for p in {3, 5, 7, 11, ..., 251}:
initLoop:
    movff   first_seg, cur_seg
    clrf    prime_cnt, a
    lfsr    2, arr                  ; FSR2H stays on arr; only FSR2L moves
    clrf    TBLPTRU, a              ; TBLPTR -> first row of primes
    movlw   high(primes)
    movwf   TBLPTRH, a
    movlw   low(primes)
    movwf   TBLPTRL, a

; ---- loop: one segment per pass -----------------------------------------
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;    for p in {3, 5, 7, 11, ..., 251}:
	;        if p * p is in a later segment: break
	;        if p is not in next_arr[] yet:
loop:
    ; 1) add the primes whose p*p has been reached (rows with Kp <= cur_seg)
    tblrd*                          ; TABLAT = Kp of the next row (no advance)
    movf    TABLAT, w, a
    subwf   cur_seg, w, a           ; cur_seg - Kp: C = 0 if cur_seg < Kp, Z if equal
    bnc     count_primes_segment
    rcall   AddNewPrime             ; (keeps Z)
    bra     loop

    ; 2) cross out the multiples of every prime in next_arr[]
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;    for p in next_arr[]:
count_primes_segment:
    movf    prime_cnt, w, a
    bz      count_array
    movwf   temp3, a
    lfsr    1, next_arr
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;    for p in next_arr[]:
	;        for x = next[p]; x < 255; x += p:
next_prime:
    movf    POSTINC1, w, a          ; W = p
    movff   INDF1, FSR2L            ; index of the next multiple
    incf    FSR2L, f, a             ; position = index + 1
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;        for x = next[p]; x < 255; x += p:
	;            arr[x] = 0xFF
mark_loop:
    setf    INDF2, a
    addwf   FSR2L, f, a
    bc      finish_mark
    setf    INDF2, a
    addwf   FSR2L, f, a
    bnc     mark_loop
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;    for p in next_arr[]:
	;        next[p] = x - 255
finish_mark:
    movff   FSR2L, POSTINC1         ; carried value = index in the next segment
    decfsz  temp3, f, a
    bra     next_prime

    ; 3) count this segment. The entries are 00h or FFh, so adding them up
    ;    in W gives -(number of composites) mod 256.
	// 4. Count what was not crossed out in this segment (count_array)
	;    if cur_seg == last_seg:
count_array:
    movf    cur_seg, w, a
    cpfseq  last_seg, a
    bra     CountAndResetArray
	// 4. Count what was not crossed out in this segment (count_array)
	;        lo = (cur_seg == first_seg) ? first_idx : 0
    ; last segment: positions lo+1 .. last_idx+1, lo = first_idx if it is also the
    ; first segment, else 0. Nothing to clear afterwards.
    clrf    temp2_l, a
    cpfseq  first_seg, a            ; W = cur_seg
    bra     count_last
    movff   first_idx, temp2_l
	// 4. Count what was not crossed out in this segment (count_array)
	;        count += number of 0 in arr[lo ~ last_idx]
count_last:
    lfsr    0, arr+1
    movf    temp2_l, w, a
    addwf   FSR0L, f, a
    subwf   last_idx, w, a
    addlw   1
    movwf   temp2_h, a              ; temp2_h = how many numbers
    movwf   temp3, a
    movlw   0
	// 4. Count what was not crossed out in this segment (count_array)
	;        count += number of 0 in arr[lo ~ last_idx]
count_loop:
    addwf   POSTINC0, w, a
    decfsz  temp3, f, a
    bra     count_loop
    addwf   temp2_h, w, a           ; primes = count - composites
    addwf   cnt_l, f, a
    movlw   0
    addwfc  cnt_h, f, a
	// 4. Count what was not crossed out in this segment (count_array)
	;        return count
    ;return count
cp_return:
    movff   cnt_l, _count_primes$0
    movff   cnt_h, (_count_primes$0+1)
    return

	// 4. Count what was not crossed out in this segment (count_array)
	;    count += number of 0 in arr[0 ~ 254]
	;    arr[0 ~ 254] = 0
CountAndResetArray:                 ; all 255 positions, cleared for the next segment
    lfsr    0, arr+1
    movlw   85
    movwf   temp3, a
    movlw   0
	// 4. Count what was not crossed out in this segment (count_array)
	;    count += number of 0 in arr[0 ~ 254]
	;    arr[0 ~ 254] = 0
count_clear_loop:
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    decfsz  temp3, f, a
    bra     count_clear_loop
    addlw   255                     ; primes = 255 - composites
    addwf   cnt_l, f, a
    movlw   0
    addwfc  cnt_h, f, a
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;for cur_seg = first_seg to last_seg:
    incf    cur_seg, f, a
    bra     loop

; ---- AddNewPrime ----------------------------------------------------------
; Reads the row at TBLPTR (Kp <= cur_seg), appends [p, start] to next_arr[].
; Z on entry: cur_seg == Kp  ->  start = index of p*p.
; Otherwise cur_seg > Kp, which only happens in the first segment (setStart):
; start = first index i with 2*(255*cur_seg + i) + 1 a multiple of p
;       = (h - r) mod p,   h = (p-1)/2,   r = 255*cur_seg mod p = cur_seg*c mod p
; with q = floor(cur_seg*c/p) = high byte of (cur_seg*F_hi + high(cur_seg*F_lo))
; (exact for cur_seg <= 128) and r = cur_seg*c - q*p (fits in 8 bits).
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;        if p is not in next_arr[] yet:
	;            if p * p is in this segment: next[p] = (index of p * p) % 255
	;            else: next[p] = first odd multiple of p in this segment
AddNewPrime:
    tblrd*+                         ; Kp (already used)
    tblrd*+
    movff   TABLAT, temp1           ; p
    tblrd*+
    movff   TABLAT, temp2_h         ; index of p*p
    bnz     setStart                ; tblrd/movff keep Z
    tblrd*+                         ; cur_seg == Kp: start at p*p, skip c, F_lo, F_hi
    tblrd*+
    tblrd*+
    bra     finishSetStart
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;            else: next[p] = first odd multiple of p in this segment
setStart:
    tblrd*+
    movf    TABLAT, w, a            ; c
    mulwf   cur_seg, a
    movff   PRODL, temp2_l          ; temp2_l = low(cur_seg*c)
    tblrd*+
    movf    TABLAT, w, a            ; F_lo
    mulwf   cur_seg, a
    movff   PRODH, temp2_h          ; temp2_h = high(cur_seg*F_lo)
    tblrd*+
    movf    TABLAT, w, a            ; F_hi
    mulwf   cur_seg, a              ; PROD = cur_seg*F_hi
    movf    temp2_h, w, a
    addwf   PRODL, w, a
    movlw   0
    addwfc  PRODH, w, a             ; W = q
    mulwf   temp1, a                ; PRODL = low(q*p)
    movf    PRODL, w, a
    subwf   temp2_l, f, a           ; temp2_l = r
    bcf     STATUS, 0, a
    rrcf    temp1, w, a             ; W = h = (p-1)/2
    movwf   temp2_h, a
    movf    temp2_l, w, a
    subwf   temp2_h, f, a           ; temp2_h = h - r, C = (h >= r)
    movf    temp1, w, a
    btfss   STATUS, 0, a
    addwf   temp2_h, f, a           ; h < r: add p
	// 3. Sieve one segment at a time (loop / AddNewPrime / count_primes_segment)
	;        if p is not in next_arr[] yet:
finishSetStart:
    lfsr    0, next_arr             ; FSR0 = next_arr + 2*prime_cnt
    bcf     STATUS, 0, a
    rlcf    prime_cnt, w, a         ; W = 2*prime_cnt
    addwf   FSR0L, f, a
    movlw   0
    addwfc  FSR0H, f, a
    movff   temp1, POSTINC0
    movff   temp2_h, INDF0
    incf    prime_cnt, f, a
    return

; ---- Half_div255 ----------------------------------------------------------
; in:  temp2_h:temp2_l = g (high:low)
; out: temp2_h = (g >> 1) / 255, temp2_l = (g >> 1) mod 255
; 256*hi + lo = 255*hi + (hi + lo) and hi + lo <= 382: one correction at most.
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;first_seg = first / 255 ; first_idx = first % 255
	;last_seg = last / 255   ; last_idx = last % 255
Half_div255:
    bcf     STATUS, 0, a
    rrcf    temp2_h, f, a
    rrcf    temp2_l, f, a
    movf    temp2_h, w, a
    addwf   temp2_l, f, a           ; temp2_l = hi + lo (low 8 bits), C = carry
    bc      div_carry
    incf    temp2_l, w, a           ; hi + lo == 255 ?
    bnz     finish_div
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;first_seg = first / 255 ; first_idx = first % 255
	;last_seg = last / 255   ; last_idx = last % 255
div_carry:
    incf    temp2_l, f, a           ; temp2_l = hi + lo - 255
    incf    temp2_h, f, a
	// 2. Odd numbers only: odd x has index g = (x - 1) / 2, 255 indices per segment
	;first_seg = first / 255 ; first_idx = first % 255
	;last_seg = last / 255   ; last_idx = last % 255
finish_div:
    return
