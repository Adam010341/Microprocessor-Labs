# Lab 5 Basic: gcd (binary GCD, PIC18 assembly called from C)

`unsigned char gcd(unsigned char a, unsigned char b)` in `gcd.asm`, called from `main.c`; result stored in `ans`.
Inputs are 1 to 255. Judged by looking at `ans` in the Watches window.

Files: `gcd.asm`, `main.c`, MPLAB X project in `nbproject/` (XC8 v4.00, device PIC18F4520, needs `-mdfp=...PIC18Fxxxx_DFP/1.8.178/xc8` because MPLAB X 5.20 does not pass it).

Review focus: correctness for all 1..255 pairs (e.g. `gcd(252,105)=21`, `gcd(17,5)=1`, `gcd(5,10)=5`), the `k` shift count, `unsigned` compare after `subwf` (should use Carry, not N), `, a` operands, no hard-coded addresses, `k` initialised on every call.
