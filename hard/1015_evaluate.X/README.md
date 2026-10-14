# Lab 5 Hard: evaluate (a op1 b op2 c op3 d, `*` before `+`/`-`)

`unsigned int evaluate(unsigned int a, char op1, unsigned int b, char op2, unsigned int c, char op3, unsigned int d)` in `evaluate.asm`, called from `main.c`; result stored in `ans`.
All values and intermediate results fit in 16 bits, operators are `+ - *`, same-precedence operators go left to right.
Examples: `evaluate(5,'+',3,'-',2,'+',1)=7`, `evaluate(2,'+',3,'*',4,'-',5)=9`, `evaluate(12,'+',34,'*',2,'*',3)=216`.

Files: `evaluate.asm`, `main.c`, MPLAB X project in `nbproject/` (XC8 v4.00, PIC18F4520, `-mdfp` needed as for the basic lab).

Review focus: operator precedence (a term/sum design: `*` only multiplies the current term, `+`/`-` flush it), the 16x16 multiply (low 16 bits only), 16-bit subtract without a negative result, whether the last term is flushed with the right sign, `sum`/`term` initialised on every call, comparing characters with `xorlw` (not `xorwf`), `, a` operands, `RETURN` present, return value in `_evaluate$0` and `_evaluate$0+1`.
