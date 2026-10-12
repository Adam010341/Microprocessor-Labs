/*
 * Local test driver for count_primes (not submitted to the judge).
 * The judge calls count_primes many times in one run, so this does too.
 * Set a breakpoint on the while(1) line and look at res[] in Watches.
 */
#include <xc.h>

extern unsigned int count_primes(unsigned int n, unsigned int m);

volatile unsigned int res[4];

int main(void)
{
    res[0] = count_primes(1, 10);      /* 4 */
    res[1] = count_primes(2, 2);       /* 1 */
    res[2] = count_primes(24, 28);     /* 0 */
    res[3] = count_primes(114, 514);   /* 67 */
    while (1)
        ;
    return 0;
}
