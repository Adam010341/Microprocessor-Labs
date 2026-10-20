/* 
 * File:   main.c
 * Author: adam
 *
 * Created on October 12, 2026, 12:00 AM
 */

#include <stdio.h>
#include <stdlib.h>

/*
 * 
 */
extern unsigned int evaluate(unsigned int a, char op1, unsigned int b, char op2, unsigned int c, char op3, unsigned int d);
int main(int argc, char** argv) {
    volatile unsigned int ans = evaluate(255, '*', 257, '-', 65535, '+', 7) ;
    while(1);
    return 0;
}

