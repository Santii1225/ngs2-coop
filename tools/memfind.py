#!/usr/bin/env python3
"""memfind.py PATTERN [--utf16] [--max N] -- search the game's writable/readable private memory for bytes
(hex) or text (--utf16 / --ascii). Reads region by region in 4 MB chunks (bounded memory)."""
import sys, os, re, argparse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem
ap = argparse.ArgumentParser()
ap.add_argument('pattern'); ap.add_argument('--utf16', action='store_true'); ap.add_argument('--ascii', action='store_true')
ap.add_argument('--max', type=int, default=20)
a = ap.parse_args()
pat = a.pattern.encode('utf-16le') if a.utf16 else a.pattern.encode() if a.ascii else bytes.fromhex(a.pattern)
pid = ngs2mem.pid()
hits = 0
with open(f'/proc/{pid}/maps') as maps, open(f'/proc/{pid}/mem', 'rb', 0) as mem:
    for line in maps:
        rng, perm = line.split()[:2]
        if perm[0] != 'r': continue
        lo, hi = (int(x, 16) for x in rng.split('-'))
        if hi - lo > 1 << 31: continue
        pos = lo
        while pos < hi:
            n = min(4 << 20, hi - pos)
            try:
                mem.seek(pos); buf = mem.read(n + len(pat))
            except OSError:
                break
            i = buf.find(pat)
            while i >= 0 and i < n:
                print(f'{pos + i:#x} {perm} {line.split()[-1] if len(line.split()) > 5 else ""}', flush=True)
                hits += 1
                if hits >= a.max: sys.exit(0)
                i = buf.find(pat, i + 1)
            pos += n
