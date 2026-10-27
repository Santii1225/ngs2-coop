#!/usr/bin/env python3
"""Read-only value hunt over all writable memory of the game (heap included), narrowing by steps.
  heapscan.py new VALUE [u8|u32]   -> every address holding VALUE (candidates saved)
  heapscan.py next VALUE           -> keep candidates that now hold VALUE
  heapscan.py show [N]             -> print candidates and current values
Candidates live in /tmp/ngs2coop/heapscan.npz."""
import ngs2mem as n, numpy as np, sys, os
F = '/tmp/ngs2coop/heapscan.npz'
m = n.Mem()


def regions():
    for line in open(f'/proc/{m.pid}/maps'):
        a, perm = line.split()[:2]
        if 'rw' not in perm: continue
        lo, hi = (int(x, 16) for x in a.split('-'))
        if hi - lo > 1 << 30 or lo >= 1 << 47: continue
        yield lo, hi


def read_vals(addrs, width):
    out = np.zeros(len(addrs), dtype=np.int64)
    order = np.argsort(addrs)
    i = 0
    a_sorted = addrs[order]
    while i < len(a_sorted):           # group nearby addresses into one read
        j = i
        while j + 1 < len(a_sorted) and a_sorted[j + 1] - a_sorted[i] < 0x10000: j += 1
        base = int(a_sorted[i]); size = int(a_sorted[j] - a_sorted[i]) + width
        try:
            buf = np.frombuffer(m.read(base, size), dtype=np.uint8)
            offs = (a_sorted[i:j + 1] - base).astype(np.int64)
            v = buf[offs].astype(np.int64)
            if width == 4:
                for k in (1, 2, 3): v |= buf[offs + k].astype(np.int64) << (8 * k)
            out[order[i:j + 1]] = v
        except OSError:
            out[order[i:j + 1]] = -1
        i = j + 1
    return out


cmd = sys.argv[1]
if cmd == 'new':
    val = int(sys.argv[2]); width = 4 if len(sys.argv) > 3 and sys.argv[3] == 'u32' else 1
    found = []
    for lo, hi in regions():
        step = 1 << 22
        for a in range(lo, hi, step):
            try: buf = m.read(a, min(step, hi - a))
            except OSError: continue
            arr = np.frombuffer(buf, dtype=np.uint8 if width == 1 else np.uint32)
            idx = np.nonzero(arr == val)[0]
            found.append(a + idx.astype(np.int64) * width)
    addrs = np.concatenate(found) if found else np.zeros(0, np.int64)
    np.savez(F, addrs=addrs, width=width)
    print(len(addrs), 'candidates')
elif cmd == 'next':
    d = np.load(F); addrs, width = d['addrs'], int(d['width'])
    vals = read_vals(addrs, width)
    addrs = addrs[vals == int(sys.argv[2])]
    np.savez(F, addrs=addrs, width=width)
    print(len(addrs), 'candidates')
elif cmd == 'show':
    d = np.load(F); addrs, width = d['addrs'], int(d['width'])
    k = int(sys.argv[2]) if len(sys.argv) > 2 else 40
    vals = read_vals(addrs[:k], width)
    for a, v in zip(addrs[:k], vals): print(hex(int(a)), int(v))
