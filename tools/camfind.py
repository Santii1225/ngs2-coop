#!/usr/bin/env python3
"""Camera hunt in .data/.bss: snapshots while P1 walks; keep float triples that follow P1's motion at
camera distance.  camfind.py  (needs the game in a mission, P1 pad = vpad.fifo)"""
import ngs2mem as n, numpy as np, subprocess, time, os
LO, HI = 0x141c4b000, 0x146e94000
m = n.Mem()
def snap():
    out = bytearray(HI - LO); step = 0x10000
    for a in range(LO, HI, step):
        try: b = m.read(a, min(step, HI - a)); out[a - LO:a - LO + len(b)] = b
        except OSError: pass
    return np.frombuffer(bytes(out[:(HI - LO) // 4 * 4]), dtype=np.float32).astype(np.float64)
o0 = m.actor(m.player_actor(0))[0]
pos = lambda: np.array(m.f3(o0 + n.O_CANON))
P, S = [pos()], [snap()]
for d in ((0, 1), (1, 0), (0, -1)):
    subprocess.run([os.path.join(os.path.dirname(__file__), 'pad.sh'), 'p1', 'stick', 'L', str(d[0]), str(d[1]), '900'])
    time.sleep(1.4); P.append(pos()); S.append(snap())
with np.errstate(all='ignore'):
    N = len(S[0]) - 2
    ok = np.ones(N, bool)
    for i in range(len(S)):
        v = np.stack([S[i][0:N], S[i][1:N + 1], S[i][2:N + 2]], 1)
        dist = np.linalg.norm(v - P[i], axis=1)
        ok &= np.isfinite(dist) & (dist > 2.5) & (dist < 20)
        if i:
            dv = v - np.stack([S[i - 1][0:N], S[i - 1][1:N + 1], S[i - 1][2:N + 2]], 1)
            dp = P[i] - P[i - 1]
            ok &= np.linalg.norm(dv - dp, axis=1) < 0.6 * np.linalg.norm(dp) + 0.05
            ok &= np.linalg.norm(dp) > 0.5
print('P1 moves', [round(float(np.linalg.norm(P[i] - P[i - 1])), 2) for i in range(1, len(P))])
idx = np.nonzero(ok)[0]
print(len(idx), 'candidates')
for k in idx[:60]:
    v = S[-1][k:k + 3]
    print(hex(LO + 4 * k), np.round(v, 2), 'dist', round(float(np.linalg.norm(v - P[-1])), 2), 'dy', round(float(v[1] - P[-1][1]), 2))
