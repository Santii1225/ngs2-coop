#!/usr/bin/env python3
"""Enemy HP hunt: poll every live actor's character struct while P1 fights; report fields that only go
down (in steps), for actors that end up dead/removed.  hpfind.py [seconds]"""
import ngs2mem as n, numpy as np, time, sys
m = n.Mem(); dur = float(sys.argv[1]) if len(sys.argv) > 1 else 40
hist = {}   # (index, obj) -> list of char bytes
t0 = time.time()
while time.time() - t0 < dur:
    pa = set(m.read(0x14211e760, 2))
    for i in range(0xa0):
        o = m.obj(i)
        if not o or i in pa: continue
        g = m.group(i)
        if g >= 0x20: continue
        try: hist.setdefault((i, o), []).append(np.frombuffer(m.read(o, 0x5c00), dtype=np.uint8).copy())
        except OSError: pass
    time.sleep(0.05)
score = {}
for key, h in hist.items():
    if len(h) < 20: continue
    a = np.stack(h)
    for name, view in (('u16', '<u2'), ('i32', '<i4'), ('f32', '<f4')):
        v = a.view(view).astype(np.float64)
        d = np.diff(v, axis=0)
        with np.errstate(all='ignore'):
            ok = (v[0] > 10) & (v[0] < 1e5) & (d <= 0).all(0) & ((d < 0).sum(0) >= 2) & ((d < 0).sum(0) <= 40)
        for k in np.nonzero(ok)[0]:
            off = k * np.dtype(view).itemsize
            score.setdefault((name, off), []).append((key[0], v[0, k], v[-1, k]))
for (name, off), lst in sorted(score.items(), key=lambda x: -len(x[1]))[:15]:
    print(f"{name} obj+{off:#06x}: {len(lst)} actors", [(i, round(a), round(b)) for i, a, b in lst[:6]])
