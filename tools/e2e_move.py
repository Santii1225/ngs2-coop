#!/usr/bin/env python3
"""Read-only end-to-end check: push a stick on a pad FIFO and measure how far P1 (actor 0) and the partner
(actor 4) move.  e2e_move.py p1|r x y [ms]"""
import ngs2mem as n, time, subprocess, math, sys, os
m = n.Mem(); o, g, c = m.actor(m.player_actor(1)); o0, g0, c0 = m.actor(m.player_actor(0))
pos = lambda a: m.f3(a + n.O_CANON)
pad, x, y = sys.argv[1], sys.argv[2], sys.argv[3]; ms = int(sys.argv[4]) if len(sys.argv) > 4 else 1200
a0, r0 = pos(o), pos(o0)
subprocess.run([os.path.join(os.path.dirname(__file__), 'pad.sh'), pad, 'stick', 'L', x, y, str(ms)])
time.sleep(ms / 1000 + 0.5)
a1, r1 = pos(o), pos(o0)
print(f'{pad} stick ({x},{y}) {ms}ms: P1 moved {math.dist(r0, r1):5.2f}  partner moved {math.dist(a0, a1):5.2f}  '
      f'partner port={m.u8(c)} slotmap={m.u8(0x14211e754)},{m.u8(0x14211e755)}', flush=True)
