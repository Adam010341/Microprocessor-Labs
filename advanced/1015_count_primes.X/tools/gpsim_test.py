#!/usr/bin/env python3
"""Run count_primes.S in gpsim (no XC8 / MPLAB needed) and check every call.

The pic-as source is converted to gpasm syntax (absolute addresses: params at
0x10, udata_acs at 0x20, arr at 0x100, udata_bank2 at 0x2A0), wrapped in a
harness that calls count_primes for every (n, m) pair IN ONE RUN, with a
random BSR / FSR0-2 / PRODL before each call and random RAM at start-up, and
compared with a Python sieve. Cycles are counted from the CALL to the RETURN
inclusive.

Needs gputils and gpsim (Ubuntu: apt install gputils gpsim).

usage:
  tools/gpsim_test.py count_primes.S 1,10 2,2 114,514     pairs on the command line
  tools/gpsim_test.py count_primes.S @pairs.txt           one "n m" per line
  tools/gpsim_test.py count_primes.S --handoff            the HANDOFF.md list + full range
  tools/gpsim_test.py count_primes.S --stress             ~110k calls (a few minutes)
env: QUIET=1 prints only failures and the summary.

This converter is only meant for count_primes.S-style sources; it is not a
general pic-as -> gpasm translator. gpasm pads every odd-length DB line, so
consecutive DB lines are merged first (pic-as does not pad).
"""
import os, random, re, subprocess, sys, tempfile

HANDOFF = [(1, 10), (2, 2), (24, 28), (0, 1), (1, 1), (0, 0), (100, 200), (5, 5),
           (4, 4), (114, 514), (256, 1000), (65400, 65535), (65000, 65535),
           (65535, 65535), (1, 5000), (512, 2000), (1, 2000), (1, 65535),
           (0, 65535), (3, 3), (17, 17), (15, 17), (18, 65535), (200, 100)]

PARAM = 0x10                       # _count_primes$0 (2 bytes), $1 (2 bytes)
ALLOC = {'udata_acs': 0x20, 'udata_bank1': 0x100, 'udata_bank2': 0x2A0,
         'udata_bank3': 0x300}
TABLE = 0x2400                     # test table in flash, 8 bytes per call


def ref_count(n, m, _pi=[]):
    if not _pi:
        N = 65536
        s = bytearray([1]) * N
        s[0] = s[1] = 0
        for i in range(2, 256):
            if s[i]:
                s[i * i::i] = bytearray(len(range(i * i, N, i)))
        acc = 0
        _pi.append(0)
        for i in range(N):
            acc += s[i]
            _pi.append(acc)
    return _pi[m + 1] - _pi[n] if m >= n else 0


def convert(src):
    defs, code = [], []
    psect = None
    alloc = dict(ALLOC)
    for line in src.splitlines():
        line = line.rstrip('\r')
        s = line.strip()
        if s.startswith(('#include', 'GLOBAL', 'EXTRN', '//')):
            continue
        m = re.match(r'PSECT\s+(\w+)', s, re.I)
        if m:
            psect = m.group(1)
            continue
        if psect in alloc:
            m = re.match(r'(\w+):\s*DS\s+(\d+)', s, re.I)
            if m:
                defs.append('%s equ 0x%X' % (m.group(1), alloc[psect]))
                alloc[psect] += int(m.group(2))
            elif s.startswith('#define'):
                defs.append(s)
            continue
        line = line.replace('_count_primes$0', 'cp_arg0').replace('_count_primes$1', 'cp_arg1')
        line = re.sub(r'BANKMASK\(([^)]*)\)', r'((\1)&0xFF)', line)
        line = re.sub(r'BANKSEL\(([^)]*)\)', r'banksel \1', line)
        line = re.sub(r'\bTBLRD\*\+', 'tblrd*+', line)
        line = re.sub(r'^\s+(\w+:)', r'\1', line.replace('//', ';'))
        if re.match(r'\s*DB\s', line, re.I) and code and re.match(r'\s*DB\s', code[-1], re.I):
            code[-1] += ', ' + re.sub(r';.*', '', line).strip()[2:].strip()
        else:
            code.append(re.sub(r';.*', '', line) if re.match(r'\s*DB\s', line, re.I) else line)
    return defs, code


def build(src, tests, seed):
    rnd = random.Random(seed)
    defs, code = convert(src)
    assert TABLE + 8 * len(tests) <= 0x8000, 'too many tests for one run'
    h = ['    list p=18f4520, r=dec', '    #include <p18f4520.inc>',
         '    config WDT=OFF, LVP=OFF, XINST=OFF',
         'a equ 0', 'b equ 1', 'w equ 0', 'f equ 1',
         'cp_arg0 equ 0x%X' % PARAM, 'cp_arg1 equ 0x%X' % (PARAM + 2), 'hv equ 0x50'] + defs
    h += ['    org 0', '    goto harness', '    org 0x40',
          'probe:', '    nop', '    return',
          'harness:',
          '    movlw upper(ttab)', '    movwf hv+0, A', '    movlw high(ttab)', '    movwf hv+1, A',
          '    movlw low(ttab)', '    movwf hv+2, A',
          '    movlw %d' % (len(tests) & 255), '    movwf hv+3, A',
          '    movlw %d' % ((len(tests) >> 8) + 1), '    movwf hv+4, A',
          'hloop:',
          '    movff hv+0, TBLPTRU', '    movff hv+1, TBLPTRH', '    movff hv+2, TBLPTRL']
    for dst in ('cp_arg0', 'cp_arg0+1', 'cp_arg1', 'cp_arg1+1', 'FSR0L', 'FSR1L', 'FSR2L', 'BSR'):
        h += ['    tblrd*+', '    movff TABLAT, %s' % dst]
    h += ['    movff TBLPTRU, hv+0', '    movff TBLPTRH, hv+1', '    movff TBLPTRL, hv+2',
          '    movff TABLAT, PRODL', '    movff TABLAT, FSR0H', '    movff TABLAT, FSR1H',
          '    movff TABLAT, FSR2H',
          '    call probe', '    call _count_primes', '    call probe',
          '    decfsz hv+3, F, A', '    bra hloop', '    decfsz hv+4, F, A', '    bra hloop',
          'hdone:', '    bra hdone', '    org 0x100'] + code
    h += ['    org 0x%X' % TABLE, 'ttab:']
    for n, m in tests:
        j = [rnd.randrange(256) for _ in range(3)] + [rnd.randrange(16)]   # FSR0L FSR1L FSR2L BSR
        h.append('    db %d, %d, %d, %d, %d, %d, %d, %d' % (n & 255, n >> 8, m & 255, m >> 8, *j))
    h.append('    end')
    return '\n'.join(h) + '\n'


def run(src, tests, seed=1):
    d = tempfile.mkdtemp()
    open(os.path.join(d, 'h.asm'), 'w').write(build(src, tests, seed))
    r = subprocess.run(['gpasm', '-p', 'p18f4520', 'h.asm'], cwd=d, capture_output=True, text=True)
    if r.returncode != 0 or 'Error' in r.stdout + r.stderr:
        print('\n'.join(l for l in (r.stdout + r.stderr).splitlines() if 'Message[302]' not in l))
        raise SystemExit('assemble failed (%s)' % d)
    rnd = random.Random(seed + 7)
    cmds = ['reg(0x%X)=%d' % (a, rnd.randrange(256)) for a in range(0x60, 0x600)]
    cmds.append('break e probe')
    for _ in tests:
        cmds += ['run', 'cycles', 'run', 'cycles', 'x 0x%X' % PARAM, 'x 0x%X' % (PARAM + 1)]
    cmds.append('quit')
    open(os.path.join(d, 'c.stc'), 'w').write('\n'.join(cmds) + '\n')
    r = subprocess.run(['gpsim', '-p', 'p18f4520', '-s', 'h.cod', '-c', 'c.stc', '-i'],
                       cwd=d, capture_output=True, text=True, timeout=3600)
    cyc = [int(x, 16) for x in re.findall(r'^(?:\*\*gpsim> )*\d+ = (0x[0-9A-Fa-f]+)\s*$', r.stdout, re.M)]
    regs = [int(v, 16) for v in re.findall(r'REG01[01]\[0x1[01]\] = 0x([0-9A-Fa-f]+)', r.stdout)]
    if len(cyc) != 2 * len(tests) or len(regs) != 2 * len(tests):
        raise SystemExit('could not parse gpsim output (%s)' % d)
    res = [regs[2 * i] | regs[2 * i + 1] << 8 for i in range(len(tests))]
    # probe: nop(1) + return(2) before the CALL, call probe(2) after the RETURN
    cycles = [cyc[2 * i + 1] - cyc[2 * i] - 5 for i in range(len(tests))]
    return res, cycles


def stress_tests():
    r = random.Random(42)
    tests = [(n, n) for n in range(65536)]
    pts = set()
    for K in range(130):                       # segment boundaries: odd 510K+1
        pts.update(510 * K + 1 + d for d in range(-4, 5))
    for p in range(2, 256):                    # p*p: where each prime starts
        if all(p % q for q in range(2, int(p ** 0.5) + 1)):
            pts.update(p * p + d for d in range(-3, 4))
    pts = sorted(x for x in pts if 0 <= x <= 65535)
    for x in pts:
        tests += [(x, y) for y in pts if y >= x and r.random() < 0.03]
        tests += [(x, 65535), (0, x), (x, min(65535, x + r.randrange(1, 600)))]
    for _ in range(6000):
        a = r.randrange(65536)
        k = r.randrange(5)
        b = [r.randrange(65536), min(65535, a + r.randrange(50)),
             min(65535, a + r.randrange(2000)), r.randrange(3000),
             r.randrange(60000, 65536)][k]
        if k == 3:
            a = r.randrange(300)
        if k == 4:
            a = r.randrange(60000, 65536)
        tests.append((a, b))
    return tests


def main():
    args = sys.argv[1:]
    if not args:
        raise SystemExit(__doc__)
    src = open(args.pop(0)).read()
    tests = []
    for a in args:
        if a == '--handoff':
            tests += HANDOFF
        elif a == '--stress':
            tests += stress_tests()
        elif a.startswith('@'):
            tests += [tuple(map(int, l.split()[:2])) for l in open(a[1:]) if l.strip()]
        else:
            tests.append(tuple(map(int, a.split(','))))
    quiet = os.environ.get('QUIET') == '1'
    bad = tot = 0
    worst = (0, None)
    for i in range(0, len(tests), 2500):
        batch = tests[i:i + 2500]
        res, cycles = run(src, batch, seed=1 + i)
        for (n, m), got, c in zip(batch, res, cycles):
            exp = ref_count(n, m)
            bad += got != exp
            tot += c
            worst = max(worst, (c, (n, m)))
            if not quiet or got != exp:
                print('count_primes(%5d,%5d) = %5d  expected %5d  %-4s %10d cycles'
                      % (n, m, got, exp, 'OK' if got == exp else 'FAIL', c))
    print('calls %d  failed %d  total cycles %d  slowest %d cycles %s'
          % (len(tests), bad, tot, worst[0], worst[1]))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
