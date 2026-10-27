#!/usr/bin/env python3
"""Read-only snapshots of the game's .data/.bss (0x141c4b000-0x146e94000) for screen/state hunting.
  memsnap.py save NAME            -> /tmp/ngs2coop/snap_NAME.bin
  memsnap.py find SAME=a,b DIFF=c,d [EQ=x:y,...]
     bytes equal within each SAME group, different between groups listed in DIFF... (see below)
  memsnap.py groups g1a,g1b/g2a/g3a,g3b   bytes constant inside every group and different between
                                          every pair of groups; prints address and per-group value"""
import ngs2mem as n, sys, numpy as np
LO, HI = 0x141c4b000, 0x146e94000
D = '/tmp/ngs2coop/snap_%s.bin'
def save(name):
    m = n.Mem(); out = bytearray(HI - LO); step = 0x10000
    for a in range(LO, HI, step):
        try: out[a - LO:a - LO + step] = m.read(a, step)
        except OSError: pass
    open(D % name, 'wb').write(out[:HI - LO])
def load(name): return np.frombuffer(open(D % name, 'rb').read(), dtype=np.uint8)[:HI - LO]
def groups(spec):
    gs = [[load(x) for x in g.split(',')] for g in spec.split('/')]
    ok = np.ones(HI - LO, bool)
    for g in gs:
        for s in g[1:]: ok &= g[0] == s
    for i in range(len(gs)):
        for j in range(i + 1, len(gs)): ok &= gs[i][0] != gs[j][0]
    idx = np.nonzero(ok)[0]
    print(len(idx), 'candidates')
    for k in idx[:80]:
        print(hex(LO + k), [int(g[0][k]) for g in gs])
if sys.argv[1] == 'save': save(sys.argv[2])
elif sys.argv[1] == 'groups': groups(sys.argv[2])
