#!/usr/bin/env python3
"""menu_watch.py OUT.log [SECONDS] -- read only: logs every small-valued byte that changes in the game's state
regions together with the pad buttons held at that moment and the screen byte, to map an in-game menu (which
byte is the row, the cursor, the equipped item...). Ends after SECONDS (default 180) or when OUT.log.STOP exists."""
import os, sys, time, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem

OUT = sys.argv[1]
SECS = float(sys.argv[2]) if len(sys.argv) > 2 else 180
REGIONS = [(0x141e30000, 0x141e70000), (0x142150000, 0x142160000), (0x14211d000, 0x142122000),
           (0x142f78b10, 0x142f78b10 + 0x1240), (0x146ac0000, 0x146ae8000)]
NAMES = {1: 'UP', 2: 'DOWN', 4: 'LEFT', 8: 'RIGHT', 0x10: 'A', 0x20: 'B', 0x40: 'X', 0x80: 'Y', 0x1000: 'LB', 0x2000: 'RB'}
m = ngs2mem.Mem()
prev = {lo: m.read(lo, hi - lo) for lo, hi in REGIONS}
counts = {}
t0 = time.time()
with open(OUT, 'w', buffering=1) as f:
    while time.time() - t0 < SECS and not os.path.exists(OUT + '.STOP'):
        time.sleep(0.05)
        t = time.time() - t0
        held = m.u32(0x142235880)
        screen = m.u8(0x1421544fa)
        btn = '+'.join(n for b, n in NAMES.items() if held & b) or '-'
        for lo, hi in REGIONS:
            cur = m.read(lo, hi - lo)
            old = prev[lo]
            if cur != old:
                for i in range(len(cur)):
                    if cur[i] != old[i] and cur[i] < 0x40 and old[i] < 0x40:
                        a = lo + i
                        counts[a] = counts.get(a, 0) + 1
                        if counts[a] <= 40:  # skip counters that change all the time
                            f.write(f'{t:7.2f} screen {screen:3d} btn {btn:8s} {a:#x}: {old[i]} -> {cur[i]}\n')
            prev[lo] = cur
