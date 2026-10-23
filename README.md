# PIC18F4520 Microprocessor Labs

NCKU 115-1 微算機 (Microprocessors) labs, written in MPASM / XC8 for the PIC18F4520. Each `.X` folder is an MPLAB X project.

| Folder | Content |
|---|---|
| `lab01.X` – `lab05.X` | Lab 1–5 solutions (basic / advanced / hard). Lab 5 mixes C and assembly. |
| `lab1_prac.X`, `lab02_prac.X` – `lab04_prac.X` | Practice versions |
| `Midterm.X`, `Midterm2.X`, `Midterm3.X` | Midterm lab exam, assembly only (see below) |
| `mock_exam/` | Mock exam problems written before the midterm (Advanced level, in Chinese) |
| `docs/labN/` | Lab handouts (PDF) |

## Midterm

Each midterm source starts with the same macro library (16-bit add / subtract / multiply / divide, compare, gcd, lcm, fraction arithmetic, bit counting, bubble sort), followed by the exam code under the `main` banner.

| File | What it does |
|---|---|
| `Midterm.X/one_a.asm` | Adds the high and low nibble of a byte |
| `Midterm.X/one_b.asm` | `TRIANGULAR` macro: 1 + 2 + … + n for three inputs |
| `Midterm2.X/two_a.asm` | Splits an array into even and odd arrays with their counts (indirect addressing) |
| `Midterm2.X/two_b.asm` | Sorts an array by value frequency, most frequent group first |
| `Midterm2.X/two_c.asm` | Prime factorisation of a 16-bit number through a `division` subroutine |
| `Midterm3.X/three_a.asm` | 4-digit packed BCD subtraction |
| `Midterm3.X/three_b.asm` | CRC-32 of one byte (reflected polynomial `0xEDB88320`) |

The previous contents of this repo (earlier 0916–1015 exercises and the quicksort project) are kept on the [`old-main`](../../tree/old-main) branch.
