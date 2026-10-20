/* 
 * File:   main.c
 * Author: adam
 *
 * Created on October 11, 2026, 4:45 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include <xc.h>

/*
 * 
 */
extern volatile unsigned int n;
extern volatile unsigned int m;
volatile unsigned int snap_n, snap_m;

extern volatile unsigned int lo;
extern volatile unsigned int hi;
volatile unsigned int snap_lo, snap_hi;

extern unsigned int count_primes(unsigned int a, unsigned int b);
int main(int argc, char** argv) {
    volatile unsigned int ans = count_primes(1,65535);
    while(1);
    return 0;
}

