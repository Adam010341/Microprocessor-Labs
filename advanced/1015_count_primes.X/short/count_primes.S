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
	;seg0 = first / 255 ; idx0 = first % 255  // half_div255
	;segm = last / 255  ; idxm = last % 255
	;arr[0 ~ 254] = 0                         // 0 = maybe prime, 0xFF = composite
	;if seg0 != segm: arr[0 ~ idx0-1] = 0xFF  // numbers below n in the first segment

	// 3. Sieve one segment at a time (segment / add_prime / cross_out)
	;for seg = seg0 to segm:
	;    for p in {3, 5, 7, 11, ..., 251}:    // one row of ptab per prime
	;        if p * p is in a later segment: break
	;        if p is not in prm[] yet:
	;            if p * p is in this segment: next[p] = (index of p * p) % 255
	;            else: next[p] = first odd multiple of p in this segment   // first segment only, multiply instead of divide
	;    for p in prm[]:
	;        for x = next[p]; x < 255; x += p:    // odd multiples are 2p apart, so indices are p apart
	;            arr[x] = 0xFF
	;        next[p] = x - 255                    // the next segment carries on from here, no new start point

	// 4. Count what was not crossed out in this segment (count)
	;    if seg == segm:                          // last segment: only up to m
	;        lo = (seg == seg0) ? idx0 : 0
	;        count += number of 0 in arr[lo ~ idxm]   // the 0xFF entries add up to -(number of composites)
	;        return count
	;    count += number of 0 in arr[0 ~ 254]      // numbers below n were crossed out in 2.
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
; For every odd prime p <= 251 whose multiples are being crossed out, prm[]
; holds p and the index of its next multiple. Marking a segment is
;   setf INDF2 / addwf FSR2L (+p) / bnc
; and when FSR2L carries, the value left in it is the index of the next
; multiple in the NEXT segment, so it is saved and reused as is.
; p starts being crossed out in the segment Kp that holds p*p (from p*p).

#include "xc.inc"
GLOBAL _count_primes
EXTRN _count_primes$0, _count_primes$1

PSECT udata_acs
n_lo:   DS 1        ; n (made >= 2)
n_hi:   DS 1
m_lo:   DS 1        ; m
m_hi:   DS 1
cnt_lo: DS 1        ; answer
cnt_hi: DS 1
g_lo:   DS 1        ; input of half_div255
g_hi:   DS 1
seg:    DS 1        ; current segment K
seg0:   DS 1        ; segment of the first odd number >= n
idx0:   DS 1        ; ... and its index in that segment
segm:   DS 1        ; segment of the last odd number <= m
idxm:   DS 1        ; ... and its index in that segment
nact:   DS 1        ; number of primes in prm[]
ctr:    DS 1        ; loop counter
pr:     DS 1        ; scratch: p, c, F_lo, F_hi of the prime being added
pcv:    DS 1
pfl:    DS 1
pfh:    DS 1
t1:     DS 1        ; scratch
t2:     DS 1

PSECT udata_bank1
arr:    DS 256      ; one segment; must fill bank 1 exactly (256-aligned)

PSECT udata_bank2
prm:    DS 106      ; 53 x [p, index of the next multiple of p]

; One row per odd prime p <= 251, in increasing order:
;   Kp, idx : segment and index of p*p  (divmod((p*p-1)/2, 255))
;   c       : 255 mod p
;   F       : ceil(c*65536/p), stored low byte first
; c and F give the start in the first segment without a division (add_prime).
; The last row (Kp = 255) is never reached because K <= 128.
PSECT cp_primes, class=CODE, reloc=2
ptab:
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

_count_primes:
    movff   _count_primes$0, n_lo
    movff   (_count_primes$0+1), n_hi
    movff   _count_primes$1, m_lo
    movff   (_count_primes$1+1), m_hi
    clrf    cnt_lo, a
    clrf    cnt_hi, a
    ; n < 2  ->  n = 2
    movf    n_hi, w, a
    bnz     n_ok
    movlw   2
    cpfslt  n_lo, a             ; skip if n_lo < 2
    bra     n_ok
    movwf   n_lo, a
n_ok:
    ; m < n  ->  0
    movf    n_lo, w, a
    subwf   m_lo, w, a
    movf    n_hi, w, a
    subwfb  m_hi, w, a          ; C = (m >= n)
    bnc     done
    ; 2 is the only even prime: count it here
    movf    n_hi, w, a
    bnz     no_two
    movlw   2
    cpfseq  n_lo, a
    bra     no_two
    incf    cnt_lo, f, a
no_two:
    ; last odd <= m:  g = (m-1)/2  ->  segm, idxm
    movlw   1
    subwf   m_lo, w, a
    movwf   g_lo, a
    movlw   0
    subwfb  m_hi, w, a
    movwf   g_hi, a
    rcall   half_div255
    movff   t1, segm
    movff   t2, idxm
    ; first odd >= n:  g = n/2  ->  seg0, idx0
    movff   n_lo, g_lo
    movff   n_hi, g_hi
    rcall   half_div255
    movff   t1, seg0
    movff   t2, idx0
    ; no odd number in [n, m] (e.g. n = m = 4)  ->  done
    movf    seg0, w, a
    subwf   segm, w, a
    bnc     done
    bnz     have_odd
    movf    idx0, w, a
    subwf   idxm, w, a
    bnc     done
have_odd:
    ; arr = all 00h (maybe prime)
    lfsr    0, arr+1
    movlw   255
    movwf   ctr, a
clear:
    clrf    POSTINC0, a
    decfsz  ctr, f, a
    bra     clear
    ; if the first segment is not also the last, cross out the numbers
    ; below n in it, so the full-segment count below can count all 255
    movf    seg0, w, a
    cpfseq  segm, a
    bra     below_n
    bra     start
below_n:
    movf    idx0, w, a
    bz      start
    movwf   ctr, a
    lfsr    0, arr+1
below_n_loop:
    setf    POSTINC0, a
    decfsz  ctr, f, a
    bra     below_n_loop
start:
    movff   seg0, seg
    clrf    nact, a
    lfsr    2, arr              ; FSR2H stays on arr; only FSR2L moves
    clrf    TBLPTRU, a          ; TBLPTR -> first row of ptab
    movlw   high(ptab)
    movwf   TBLPTRH, a
    movlw   low(ptab)
    movwf   TBLPTRL, a

; ---- one segment per pass ----------------------------------------------
segment:
    ; 1) add the primes whose p*p has been reached (rows with Kp <= seg)
    tblrd*                      ; TABLAT = Kp of the next row (no advance)
    movf    TABLAT, w, a
    subwf   seg, w, a           ; seg - Kp: C = 0 if seg < Kp, Z if equal
    bnc     cross_out
    rcall   add_prime           ; (keeps Z)
    bra     segment

    ; 2) cross out the multiples of every prime in prm[]
cross_out:
    movf    nact, w, a
    bz      count
    movwf   ctr, a
    lfsr    1, prm
next_p:
    movf    POSTINC1, w, a      ; W = p
    movff   INDF1, FSR2L        ; index of the next multiple
    incf    FSR2L, f, a         ; position = index + 1
mark:
    setf    INDF2, a
    addwf   FSR2L, f, a
    bc      mark_end
    setf    INDF2, a
    addwf   FSR2L, f, a
    bnc     mark
mark_end:
    movff   FSR2L, POSTINC1     ; carried value = index in the next segment
    decfsz  ctr, f, a
    bra     next_p

    ; 3) count this segment. The entries are 00h or FFh, so adding them up
    ;    in W gives -(number of composites) mod 256.
count:
    movf    seg, w, a
    cpfseq  segm, a
    bra     count_full
    ; last segment: positions lo+1 .. idxm+1, lo = idx0 if it is also the
    ; first segment, else 0. Nothing to clear afterwards.
    clrf    t1, a
    cpfseq  seg0, a             ; W = seg
    bra     last_lo
    movff   idx0, t1
last_lo:
    lfsr    0, arr+1
    movf    t1, w, a
    addwf   FSR0L, f, a
    subwf   idxm, w, a
    addlw   1
    movwf   t2, a               ; t2 = how many numbers
    movwf   ctr, a
    movlw   0
last_loop:
    addwf   POSTINC0, w, a
    decfsz  ctr, f, a
    bra     last_loop
    addwf   t2, w, a            ; primes = count - composites
    addwf   cnt_lo, f, a
    movlw   0
    addwfc  cnt_hi, f, a
done:
    movff   cnt_lo, _count_primes$0
    movff   cnt_hi, (_count_primes$0+1)
    return

count_full:                     ; all 255 positions, cleared for the next segment
    lfsr    0, arr+1
    movlw   85
    movwf   ctr, a
    movlw   0
full_loop:
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    decfsz  ctr, f, a
    bra     full_loop
    addlw   255                 ; primes = 255 - composites
    addwf   cnt_lo, f, a
    movlw   0
    addwfc  cnt_hi, f, a
    incf    seg, f, a
    bra     segment

; ---- add_prime ------------------------------------------------------------
; Reads the row at TBLPTR (Kp <= seg), appends [p, start] to prm[].
; Z on entry: seg == Kp  ->  start = index of p*p.
; Otherwise seg > Kp, which only happens in the first segment (seg = seg0):
; start = first index i with 2*(255*seg + i) + 1 a multiple of p
;       = (h - r) mod p,   h = (p-1)/2,   r = 255*seg mod p = seg*c mod p
; with q = floor(seg*c/p) = high byte of (seg*F_hi + high(seg*F_lo))
; (exact for seg <= 128) and r = seg*c - q*p (fits in 8 bits).
add_prime:
    tblrd*+                     ; Kp (already used)
    tblrd*+
    movff   TABLAT, pr          ; p
    tblrd*+
    movff   TABLAT, t2          ; index of p*p
    tblrd*+
    movff   TABLAT, pcv         ; c
    tblrd*+
    movff   TABLAT, pfl         ; F_lo
    tblrd*+
    movff   TABLAT, pfh         ; F_hi
    bz      add_it              ; tblrd/movff keep Z: seg == Kp, start at p*p
    movf    pcv, w, a
    mulwf   seg, a
    movff   PRODL, t1           ; t1 = low(seg*c)
    movf    pfl, w, a
    mulwf   seg, a
    movff   PRODH, t2           ; t2 = high(seg*F_lo)
    movf    pfh, w, a
    mulwf   seg, a              ; PROD = seg*F_hi
    movf    t2, w, a
    addwf   PRODL, w, a
    movlw   0
    addwfc  PRODH, w, a         ; W = q
    mulwf   pr, a               ; PRODL = low(q*p)
    movf    PRODL, w, a
    subwf   t1, f, a            ; t1 = r
    bcf     STATUS, 0, a
    rrcf    pr, w, a            ; W = h = (p-1)/2
    movwf   t2, a
    movf    t1, w, a
    subwf   t2, f, a            ; t2 = h - r, C = (h >= r)
    movf    pr, w, a
    btfss   STATUS, 0, a
    addwf   t2, f, a            ; h < r: add p
add_it:
    lfsr    0, prm              ; FSR0 = prm + 2*nact
    bcf     STATUS, 0, a
    rlcf    nact, w, a          ; W = 2*nact
    addwf   FSR0L, f, a
    movlw   0
    addwfc  FSR0H, f, a
    movff   pr, POSTINC0
    movff   t2, INDF0
    incf    nact, f, a
    return

; ---- half_div255 ----------------------------------------------------------
; g = g_hi:g_lo >> 1, then t1 = g / 255, t2 = g mod 255.
; 256*gh + gl = 255*gh + (gh + gl) and gh + gl <= 382: one correction at most.
half_div255:
    bcf     STATUS, 0, a
    rrcf    g_hi, f, a
    rrcf    g_lo, f, a
    movf    g_hi, w, a
    addwf   g_lo, w, a          ; W = gh + gl (low 8 bits), C = carry
    movwf   t2, a
    movff   g_hi, t1
    bc      hd_fix
    incf    t2, w, a            ; gh + gl == 255 ?
    bnz     hd_ok
hd_fix:
    incf    t2, f, a            ; t2 = gh + gl - 255
    incf    t1, f, a
hd_ok:
    return
