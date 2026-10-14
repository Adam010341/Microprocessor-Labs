/* 
 * File:   basic_1015.c
 * Author: adam
 *
 * Created on October 11, 2026, 1:49 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include<stdint.h>
#include <xc.h>

/*
 * 
 */
extern unsigned char gcd(unsigned char a, unsigned char b);
int main(int argc, char** argv) {
    volatile char ans = gcd (17,5);
    while(1);
    return 0;
}

