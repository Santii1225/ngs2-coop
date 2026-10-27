#!/usr/bin/env python3
"""Read-only: game pad slots (connected, held buttons, left stick). padslots.py [seconds]"""
import ngs2mem as n, struct, sys, time
m = n.Mem(); end = time.time() + (float(sys.argv[1]) if len(sys.argv) > 1 else 0)
while True:
    row = []
    for k in range(4):
        b = m.read(0x142235880 + k * 0x38, 0x38)
        held, = struct.unpack_from('<I', b, 0); lx, ly = struct.unpack_from('<ff', b, 0x18)
        row.append(f'[{k}] c={b[0x0e]} held={held:#06x} L=({lx:+.2f},{ly:+.2f})')
    print(f'np={m.u8(0x14211e5cc)} p2slot={m.u8(0x14211e755)} ' + '  '.join(row), flush=True)
    if time.time() >= end: break
    time.sleep(0.05)
