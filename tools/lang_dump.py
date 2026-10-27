#!/usr/bin/env python3
"""lang_dump.py FILE.LANG [OUT.tsv] -- every string of a LANG pack: category, index, text (UTF-16LE).
Layout: LANG header, CTGPACK (categories) at 0x80 with a table of offsets, each category a STRPACK whose
table (at +0x60 from it) lists string offsets relative to the STRPACK; strings are UTF-16LE, NUL ended,
with markup such as @[color:...] and button icons."""
import struct, sys
d = open(sys.argv[1], 'rb').read()
out = open(sys.argv[2], 'w', encoding='utf-8') if len(sys.argv) > 2 else sys.stdout

def hdr(off):
    tag = d[off:off + 8].split(b'\0')[0]
    _, hs, size, n, _, _, toff = struct.unpack_from('<7I', d, off + 8)
    return tag, size, n, toff

tag, size, ncat, toff = hdr(0x80)
cats = struct.unpack_from('<%dI' % ncat, d, 0x80 + toff)
for ci, co in enumerate(cats):
    sp = 0x80 + co
    t, ssize, n, stoff = hdr(sp)
    if t != b'STRPACK': continue
    offs = struct.unpack_from('<%dI' % n, d, sp + stoff)
    for si, so in enumerate(offs):
        a = sp + so
        e = a
        while e + 1 < len(d) and d[e:e + 2] != b'\0\0': e += 2
        s = d[a:e].decode('utf-16-le', 'replace').replace('\n', '\\n').replace('\t', ' ')
        out.write(f'{ci}\t{si}\t{s}\n')
