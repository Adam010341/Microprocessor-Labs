#!/bin/bash
# Build count_primes.S with a generated main.c that calls count_primes once per
# "n m" pair IN ONE RUN (the judge does the same), run it in the MPLAB simulator
# (mdb), and compare every result with a Python reference.
#
# usage: tools/multitest.sh path/to/count_primes.S "1 10" "2 2" "114 514" ...
# env:   XC8, DFP, MDB    tool paths (defaults below)
#        WAIT_MS          how long mdb waits for the breakpoint (default 60000)
#
# Note: write the calls out one per line. A C for-loop around the call breaks:
# XC8 puts the loop counter in the same compiled-stack slot as
# _count_primes$1, so passing m overwrites the counter.
set -u
XC8=${XC8:-/opt/microchip/xc8/v4.00/bin/xc8-cc}
DFP=${DFP:-$HOME/.mchp_packs/Microchip/PIC18Fxxxx_DFP/1.8.178/xc8}
MDB=${MDB:-$HOME/mplab_platform/bin/mdb.sh}
SRC=$(realpath "$1"); shift
W=$(mktemp -d); cp "$SRC" "$W/count_primes.S"; cd "$W"
A=(); B=(); for p in "$@"; do set -- $p; A+=("$1"); B+=("$2"); done
N=${#A[@]}
{ echo "extern unsigned int count_primes(unsigned int a, unsigned int b);"
  echo "volatile unsigned int res[$N];"
  echo "int main(void){"
  for ((i=0;i<N;i++)); do echo "    res[$i] = count_primes(${A[$i]}, ${B[$i]});"; done
  echo "    while(1)"
  echo "        ;"
  echo "    return 0;"
  echo "}"; } > main.c
BL=$((N+4))   # line number of while(1)
F="-mcpu=18F4520 -mdfp=$DFP -D__DEBUG=1 -O0 -xassembler-with-cpp -std=c99 -gdwarf-3 -mwarn=-3 -mstack=compiled:auto:auto:auto -mno-keep-startup -mno-download -mdefault-config-bits -Wl,--data-init"
"$XC8" $F main.c count_primes.S -o r.elf > build.log 2>&1 || { echo "BUILD FAIL"; grep -v 1311 build.log | head; exit 1; }
# break on both lines of the while(1) loop: XC8 may map the loop to either one
printf 'Device PIC18F4520\nHwtool Sim\nProgram r.elf\nBreak main.c:%s\nBreak main.c:%s\nRun\nWait %s\nPrint /d res\nQuit\n' "$BL" "$((BL+1))" "${WAIT_MS:-60000}" > c.txt
out=$(timeout 900 "$MDB" c.txt 2>&1 | sed -n '/^res=/,/}/p' | tr -d '\n')
got=($(echo "$out" | grep -o '[0-9]\+'))
for ((i=0;i<N;i++)); do
  e=$(python3 -c "
a,b=${A[$i]},${B[$i]}
print(sum(1 for x in range(max(a,2),b+1) if all(x%d for d in range(2,int(x**.5)+1))))")
  r=FAIL; [ "$e" == "${got[$i]:-}" ] && r=OK
  echo "call $((i+1)) count_primes(${A[$i]},${B[$i]}): expected $e got ${got[$i]:-none} $r"
done
