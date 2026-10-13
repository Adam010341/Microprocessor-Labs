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
	;seg0 = first / 255 ; idx0 = first % 255  // cp_half_div255
	;segm = last / 255  ; idxm = last % 255
	;arr[0 ~ 254] = 0                         // 0 = maybe prime, 0xFF = composite
	;if seg0 != segm: arr[0 ~ idx0-1] = 0xFF  // numbers below n in the first segment

	// 3. Sieve one segment at a time (cp_segment / cp_add_prime / cp_cross_out)
	;for seg = seg0 to segm:
	;    for p in {3, 5, 7, 11, ..., 251}:    // one row of cp_ptab per prime
	;        if p * p is in a later segment: break
	;        if p is not in cp_prm[] yet:
	;            if p * p is in this segment: next[p] = (index of p * p) % 255
	;            else: next[p] = first odd multiple of p in this segment   // first segment only, multiply instead of divide
	;    for p in cp_prm[]:
	;        for x = next[p]; x < 255; x += p:    // odd multiples are 2p apart, so indices are p apart
	;            arr[x] = 0xFF
	;        next[p] = x - 255                    // the next segment carries on from here, no new start point

	// 4. Count what was not crossed out in this segment (cp_count)
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
;   segment K         g = 255K .. 255K+254, kept in cp_arr positions 1..255
;                     (position = index in segment + 1, position 0 unused)
;   cp_arr            all 256 bytes of bank 1, so it starts at a multiple of
;                     256 and FSR2L carries out exactly after position 255
;   entry             00h = maybe prime, FFh = composite
; For every odd prime p <= 251 whose multiples are being crossed out, cp_prm[]
; holds p and the index of its next multiple. Marking a segment is
;   setf INDF2 / addwf FSR2L (+p) / bnc
; and when FSR2L carries, the value left in it is the index of the next
; multiple in the NEXT segment, so it is saved and reused as is.
; p starts being crossed out in the segment Kp that holds p*p (from p*p).
; All names start with cp_ so they cannot clash with anything in xc.inc or
; the XC8 runtime.

#include "xc.inc"
GLOBAL _count_primes
EXTRN _count_primes$0, _count_primes$1

PSECT udata_acs
cp_nL:   DS 1       ; n (made >= 2)
cp_nH:   DS 1
cp_mL:   DS 1       ; m
cp_mH:   DS 1
cp_cL:   DS 1       ; answer
cp_cH:   DS 1
cp_seg:  DS 1       ; current segment K
cp_seg0: DS 1       ; segment of the first odd number >= n
cp_idx0: DS 1       ; ... and its index in that segment
cp_segm: DS 1       ; segment of the last odd number <= m
cp_idxm: DS 1       ; ... and its index in that segment
cp_nact: DS 1       ; number of primes in cp_prm[]
cp_ctr:  DS 1       ; loop counter
cp_p:    DS 1       ; the prime being added (cp_add_prime)
cp_t1:   DS 1       ; scratch
cp_t2:   DS 1

PSECT udata_bank1
cp_arr:  DS 256     ; one segment; must fill bank 1 exactly (256-aligned)

PSECT udata_bank2
cp_prm:  DS 106     ; 53 x [p, index of the next multiple of p]

; One row per odd prime p <= 251, in increasing order:
;   Kp, idx : segment and index of p*p  (divmod((p*p-1)/2, 255))
;   c       : 255 mod p
;   F       : ceil(c*65536/p), stored low byte first
; c and F give the start in the first segment without a division
; (cp_add_prime). The last row (Kp = 255) is never reached because K <= 128.
PSECT cp_primes, class=CODE, reloc=2
cp_ptab:
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
    movff   _count_primes$0, cp_nL
    movff   (_count_primes$0+1), cp_nH
    movff   _count_primes$1, cp_mL
    movff   (_count_primes$1+1), cp_mH
    clrf    cp_cL, a
    clrf    cp_cH, a
    ; n < 2  ->  n = 2
    movf    cp_nH, w, a
    bnz     cp_n_ok
    movlw   2
    cpfslt  cp_nL, a            ; skip if nL < 2
    bra     cp_n_ok
    movwf   cp_nL, a
cp_n_ok:
    ; m < n  ->  0
    movf    cp_nL, w, a
    subwf   cp_mL, w, a
    movf    cp_nH, w, a
    subwfb  cp_mH, w, a         ; C = (m >= n)
    bnc     cp_done
    ; 2 is the only even prime: count it here
    movf    cp_nH, w, a
    bnz     cp_no_two
    movlw   2
    cpfseq  cp_nL, a
    bra     cp_no_two
    incf    cp_cL, f, a
cp_no_two:
    ; last odd <= m:  g = (m-1)/2  ->  segm, idxm
    movlw   1
    subwf   cp_mL, w, a
    movwf   cp_t1, a
    movlw   0
    subwfb  cp_mH, w, a
    movwf   cp_t2, a
    rcall   cp_half_div255
    movff   cp_t2, cp_segm
    movff   cp_t1, cp_idxm
    ; first odd >= n:  g = n/2  ->  seg0, idx0
    movff   cp_nL, cp_t1
    movff   cp_nH, cp_t2
    rcall   cp_half_div255
    movff   cp_t2, cp_seg0
    movff   cp_t1, cp_idx0
    ; no odd number in [n, m] (e.g. n = m = 4)  ->  done
    movf    cp_seg0, w, a
    subwf   cp_segm, w, a
    bnc     cp_done
    bnz     cp_have_odd
    movf    cp_idx0, w, a
    subwf   cp_idxm, w, a
    bnc     cp_done
cp_have_odd:
    ; cp_arr = all 00h (maybe prime)
    lfsr    0, cp_arr+1
    movlw   255
    movwf   cp_ctr, a
cp_clear:
    clrf    POSTINC0, a
    decfsz  cp_ctr, f, a
    bra     cp_clear
    ; if the first segment is not also the last, cross out the numbers
    ; below n in it, so the full-segment count below can count all 255
    movf    cp_seg0, w, a
    cpfseq  cp_segm, a
    bra     cp_below_n
    bra     cp_start
cp_below_n:
    movf    cp_idx0, w, a
    bz      cp_start
    movwf   cp_ctr, a
    lfsr    0, cp_arr+1
cp_below_n_loop:
    setf    POSTINC0, a
    decfsz  cp_ctr, f, a
    bra     cp_below_n_loop
cp_start:
    movff   cp_seg0, cp_seg
    clrf    cp_nact, a
    lfsr    2, cp_arr           ; FSR2H stays on cp_arr; only FSR2L moves
    clrf    TBLPTRU, a          ; TBLPTR -> first row of cp_ptab
    movlw   high(cp_ptab)
    movwf   TBLPTRH, a
    movlw   low(cp_ptab)
    movwf   TBLPTRL, a

; ---- one segment per pass ----------------------------------------------
cp_segment:
    ; 1) add the primes whose p*p has been reached (rows with Kp <= seg)
    tblrd*                      ; TABLAT = Kp of the next row (no advance)
    movf    TABLAT, w, a
    subwf   cp_seg, w, a        ; seg - Kp: C = 0 if seg < Kp, Z if equal
    bnc     cp_cross_out
    rcall   cp_add_prime        ; (keeps Z)
    bra     cp_segment

    ; 2) cross out the multiples of every prime in cp_prm[]
cp_cross_out:
    movf    cp_nact, w, a
    bz      cp_count
    movwf   cp_ctr, a
    lfsr    1, cp_prm
cp_next_p:
    movf    POSTINC1, w, a      ; W = p
    movff   INDF1, FSR2L        ; index of the next multiple
    incf    FSR2L, f, a         ; position = index + 1
cp_mark:
    setf    INDF2, a
    addwf   FSR2L, f, a
    bc      cp_mark_end
    setf    INDF2, a
    addwf   FSR2L, f, a
    bnc     cp_mark
cp_mark_end:
    movff   FSR2L, POSTINC1     ; carried value = index in the next segment
    decfsz  cp_ctr, f, a
    bra     cp_next_p

    ; 3) count this segment. The entries are 00h or FFh, so adding them up
    ;    in W gives -(number of composites) mod 256.
cp_count:
    movf    cp_seg, w, a
    cpfseq  cp_segm, a
    bra     cp_count_full
    ; last segment: positions lo+1 .. idxm+1, lo = idx0 if it is also the
    ; first segment, else 0. Nothing to clear afterwards.
    clrf    cp_t1, a
    cpfseq  cp_seg0, a          ; W = seg
    bra     cp_last_lo
    movff   cp_idx0, cp_t1
cp_last_lo:
    lfsr    0, cp_arr+1
    movf    cp_t1, w, a
    addwf   FSR0L, f, a
    subwf   cp_idxm, w, a
    addlw   1
    movwf   cp_t2, a            ; t2 = how many numbers
    movwf   cp_ctr, a
    movlw   0
cp_last_loop:
    addwf   POSTINC0, w, a
    decfsz  cp_ctr, f, a
    bra     cp_last_loop
    addwf   cp_t2, w, a         ; primes = count - composites
    addwf   cp_cL, f, a
    movlw   0
    addwfc  cp_cH, f, a
cp_done:
    movff   cp_cL, _count_primes$0
    movff   cp_cH, (_count_primes$0+1)
    return

cp_count_full:                  ; all 255 positions, cleared for the next segment
    lfsr    0, cp_arr+1
    movlw   85
    movwf   cp_ctr, a
    movlw   0
cp_full_loop:
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    addwf   INDF0, w, a
    clrf    POSTINC0, a
    decfsz  cp_ctr, f, a
    bra     cp_full_loop
    addlw   255                 ; primes = 255 - composites
    addwf   cp_cL, f, a
    movlw   0
    addwfc  cp_cH, f, a
    incf    cp_seg, f, a
    bra     cp_segment

; ---- cp_add_prime -----------------------------------------------------------
; Reads the row at TBLPTR (Kp <= seg), appends [p, start] to cp_prm[].
; Z on entry: seg == Kp  ->  start = index of p*p.
; Otherwise seg > Kp, which only happens in the first segment (seg = seg0):
; start = first index i with 2*(255*seg + i) + 1 a multiple of p
;       = (h - r) mod p,   h = (p-1)/2,   r = 255*seg mod p = seg*c mod p
; with q = floor(seg*c/p) = high byte of (seg*F_hi + high(seg*F_lo))
; (exact for seg <= 128) and r = seg*c - q*p (fits in 8 bits).
cp_add_prime:
    tblrd*+                     ; Kp (already used)
    tblrd*+
    movff   TABLAT, cp_p        ; p
    tblrd*+
    movff   TABLAT, cp_t2       ; index of p*p
    bnz     cp_from_mul         ; tblrd/movff keep Z
    tblrd*+                     ; seg == Kp: start at p*p, skip c, F_lo, F_hi
    tblrd*+
    tblrd*+
    bra     cp_add_it
cp_from_mul:
    tblrd*+
    movf    TABLAT, w, a        ; c
    mulwf   cp_seg, a
    movff   PRODL, cp_t1        ; t1 = low(seg*c)
    tblrd*+
    movf    TABLAT, w, a        ; F_lo
    mulwf   cp_seg, a
    movff   PRODH, cp_t2        ; t2 = high(seg*F_lo)
    tblrd*+
    movf    TABLAT, w, a        ; F_hi
    mulwf   cp_seg, a           ; PROD = seg*F_hi
    movf    cp_t2, w, a
    addwf   PRODL, w, a
    movlw   0
    addwfc  PRODH, w, a         ; W = q
    mulwf   cp_p, a             ; PRODL = low(q*p)
    movf    PRODL, w, a
    subwf   cp_t1, f, a         ; t1 = r
    bcf     STATUS, 0, a
    rrcf    cp_p, w, a          ; W = h = (p-1)/2
    movwf   cp_t2, a
    movf    cp_t1, w, a
    subwf   cp_t2, f, a         ; t2 = h - r, C = (h >= r)
    movf    cp_p, w, a
    btfss   STATUS, 0, a
    addwf   cp_t2, f, a         ; h < r: add p
cp_add_it:
    lfsr    0, cp_prm           ; FSR0 = cp_prm + 2*nact
    bcf     STATUS, 0, a
    rlcf    cp_nact, w, a       ; W = 2*nact
    addwf   FSR0L, f, a
    movlw   0
    addwfc  FSR0H, f, a
    movff   cp_p, POSTINC0
    movff   cp_t2, INDF0
    incf    cp_nact, f, a
    return

; ---- cp_half_div255 -------------------------------------------------------
; in:  cp_t2:cp_t1 = g (high:low)
; out: cp_t2 = (g >> 1) / 255, cp_t1 = (g >> 1) mod 255
; 256*hi + lo = 255*hi + (hi + lo) and hi + lo <= 382: one correction at most.
cp_half_div255:
    bcf     STATUS, 0, a
    rrcf    cp_t2, f, a
    rrcf    cp_t1, f, a
    movf    cp_t2, w, a
    addwf   cp_t1, f, a         ; t1 = hi + lo (low 8 bits), C = carry
    bc      cp_hd_fix
    incf    cp_t1, w, a         ; hi + lo == 255 ?
    bnz     cp_hd_ok
cp_hd_fix:
    incf    cp_t1, f, a         ; t1 = hi + lo - 255
    incf    cp_t2, f, a
cp_hd_ok:
    return
