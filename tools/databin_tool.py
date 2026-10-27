#!/usr/bin/env python3
"""databin_tool.py list|extract OUTDIR [indices...] -- NINJA GAIDEN Σ2 (Master Collection) databin.
Layout: header (0x20 bytes), table section at 0x20: count at +0x00, entry pointers (u32, relative to 0x20) at
+0x10; entry (24 bytes): data offset (i64, relative to 0x441e0 = 0x20 + section size), decompressed size,
compressed size, u32, u16, u8, u8 type. Data: one zlib stream per entry. Mods: plugin loader replaces entry N
with mods/NNNNN.dat (decompressed)."""
import os, struct, sys, zlib, collections
G = os.path.expanduser('~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/databin/databin')

def entries(f):
    f.seek(0x14); section = struct.unpack('<I', f.read(4))[0]
    f.seek(0x20); n = struct.unpack('<I', f.read(4))[0]
    f.seek(0x30); ptrs = struct.unpack('<%dI' % n, f.read(4 * n))
    out = []
    for p in ptrs:
        f.seek(0x20 + p); out.append(struct.unpack('<qIIIHBB', f.read(24)))
    return 0x20 + section, out

def read(f, base, e):
    off, ds, cs = e[0], e[1], e[2]
    f.seek(base + off); c = f.read(cs)
    return zlib.decompress(c) if cs != ds else c

def magic(d):
    m = d[:4]
    s = ''.join(chr(b) if 32 < b < 127 else '' for b in m)
    return s if len(s) >= 3 else 'bin'

if __name__ == '__main__':
    f = open(G, 'rb'); base, E = entries(f)
    if sys.argv[1] == 'list':
        print(len(E), 'entries, decompressed total %.2f GB' % (sum(e[1] for e in E) / 1e9))
    elif sys.argv[1] == 'extract':
        out = sys.argv[2]; os.makedirs(out, exist_ok=True)
        idx = [int(x) for x in sys.argv[3:]] or range(len(E))
        kinds = collections.Counter(); index = open(os.path.join(out, 'index.tsv'), 'w')
        for i in idx:
            e = E[i]
            try: d = read(f, base, e)
            except Exception as ex: index.write(f'{i}\t{e[6]}\terror {ex}\n'); continue
            k = magic(d); kinds[k] += 1
            name = f'{i:05d}.{k}'
            open(os.path.join(out, name), 'wb').write(d)
            index.write(f'{i}\t{e[6]}\t{k}\t{len(d)}\t{name}\n')
        print(kinds.most_common(30))
