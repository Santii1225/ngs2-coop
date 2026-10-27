#!/usr/bin/env python3
"""Focused HP hunt on one enemy: hpfocus.py BODY LOGIC HITS  (P1 is teleported next to BODY and hits once
per round with X; snapshots of body obj, logic obj and the shared character between hits)."""
import ngs2mem as n, numpy as np, subprocess, time, sys, struct
m = n.Mem(); body, logic, hits = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
g = m.group(body)
def snap():
    parts = []
    for base, size in ((m.obj(body), 0x5c00), (m.obj(logic), 0x5c00), (m.char(g), 0x1240)):
        parts.append(np.frombuffer(m.read(base, size), dtype=np.uint8))
    return np.concatenate(parts)
names = [('body', 0x5c00), ('logic', 0x5c00), ('char', 0x1240)]
def where(off):
    for nm, sz in names:
        if off < sz: return f'{nm}+{off:#06x}'
        off -= sz
S = []   # (before, after) per hit
for h in range(hits):
    b0 = snap(); time.sleep(0.4); b1 = snap()
    subprocess.run(['bash', '/tmp/ngs2coop/hitone.sh'], capture_output=True)
    time.sleep(0.6); S.append((b0, b1, snap()))
    print('hit', h + 1, 'body motion', m.u16(m.obj(body) + 0x5b30) if m.obj(body) else 'gone', flush=True)
for dt in ('<u2', '<i4', '<f4'):
    w = np.dtype(dt).itemsize
    V = [[x[:len(x) // w * w].view(dt).astype(np.float64) for x in t] for t in S]
    with np.errstate(all='ignore'):
        stable = np.ones_like(V[0][0], bool); dec = np.zeros_like(V[0][0])
        for b0, b1, a in V:
            stable &= (b0 == b1)
            dec += (a < b1)
        prev_after = None; mono = np.ones_like(stable)
        for b0, b1, a in V:
            if prev_after is not None: mono &= (b0 <= prev_after + 1e-9)
            mono &= (a <= b1); prev_after = a
        ok = stable & mono & (dec >= max(2, hits - 2)) & np.isfinite(V[0][1]) & (np.abs(V[0][1]) < 1e6)
    for k in np.nonzero(ok)[0][:20]:
        print(dt, where(k * w), [round(V[i][1][k], 3) for i in range(hits)], '->', round(V[-1][2][k], 3))
