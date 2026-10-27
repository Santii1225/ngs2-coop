#!/usr/bin/env python3
"""Whole-writable-memory snapshots on disk and monotonic filters (value hunts without a known value).
  heapdiff.py snap NAME
  heapdiff.py dec A B C [D]   -> u16/u32/f32 strictly decreasing A>B>C (and C==D if D given)
Snapshots: ~/.cache/ngs2-snaps/NAME.bin + NAME.idx (region list); regions must match between snaps."""
import ngs2mem as n, numpy as np, sys, os, json
D = os.path.expanduser('~/.cache/ngs2-snaps'); os.makedirs(D, exist_ok=True)
def regions(m):
    for line in open(f'/proc/{m.pid}/maps'):
        a, perm = line.split()[:2]
        if 'rw' not in perm: continue
        lo, hi = (int(x, 16) for x in a.split('-'))
        if hi - lo > 1 << 30 or lo >= 1 << 47: continue
        yield lo, hi
cmd = sys.argv[1]
if cmd == 'snap':
    m = n.Mem(); idx = []
    with open(f'{D}/{sys.argv[2]}.bin', 'wb') as f:
        for lo, hi in regions(m):
            try: b = m.read(lo, hi - lo)
            except OSError: continue
            idx.append((lo, len(b), f.tell())); f.write(b)
    json.dump(idx, open(f'{D}/{sys.argv[2]}.idx', 'w')); print(len(idx), 'regions')
elif cmd == 'dec':
    names = sys.argv[2:]
    idxs = [{lo: (ln, off) for lo, ln, off in json.load(open(f'{D}/{x}.idx'))} for x in names]
    files = [open(f'{D}/{x}.bin', 'rb') for x in names]
    out = []
    for lo, (ln, _) in idxs[0].items():
        if not all(lo in ix and ix[lo][0] == ln for ix in idxs): continue
        bufs = []
        for f, ix in zip(files, idxs):
            f.seek(ix[lo][1]); bufs.append(f.read(ln))
        for dt in ('<u2', '<u4', '<f4'):
            w = np.dtype(dt).itemsize; cut = ln // w * w
            v = [np.frombuffer(b[:cut], dtype=dt).astype(np.float64) for b in bufs]
            with np.errstate(all='ignore'):
                d1, d2 = v[0] - v[1], v[1] - v[2]
                ok = (d1 > 0) & (d2 > 0) & (v[0] < 20000) & (v[2] > 0) & np.isfinite(v[0]) & (d1 < 4 * d2) & (d2 < 4 * d1) & (d1 <= v[0] / 2)
                if len(v) > 3: ok &= v[2] == v[3]
            if lo < 0x10000000: continue
            with np.errstate(all="ignore"):
                ok &= (v[0] >= 1) & (v[0] - v[2] >= 1) & (v[0] == np.round(v[0])) if dt == "<f4" else ok
            for k in np.nonzero(ok)[0][:200]:
                out.append((dt, hex(lo + k * w), [float(x[k]) for x in v]))
    print(len(out), 'candidates')
    for o in out[:80]: print(o)
