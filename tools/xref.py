#!/usr/bin/env -S sh -c 'exec "${NGS2_VENV:-$HOME/.cache/ngs2-venv}/bin/python" "$0" "$@"'
"""xref.py ADDR [ADDR...] -- static RIP-relative references to addresses in the game's executable (on disk).
Prints the instruction and the start of its function (after int3 padding)."""
import sys, os, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
EXE = os.path.expanduser('~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/NINJA GAIDEN SIGMA2.exe')
d = open(EXE, 'rb').read()
pe = struct.unpack_from('<I', d, 0x3c)[0]
nsec = struct.unpack_from('<H', d, pe + 6)[0]
opt = struct.unpack_from('<H', d, pe + 20)[0]
base = 0x140000000
secs = []
for i in range(nsec):
    o = pe + 24 + opt + i * 40
    name = d[o:o + 8].rstrip(b'\0').decode()
    vsz, va, rsz, raw = struct.unpack_from('<IIII', d, o + 8)
    secs.append((name, va, vsz, raw, rsz))
text = [s for s in secs if s[0] == '.text'][0]
_, va, vsz, raw, rsz = text
code = d[raw:raw + rsz]
# The .text on disk is encrypted (Steam DRM, .bind section): use the runtime dump (tools/runtime_text_dump.py).
import glob
dumps = sorted(glob.glob(os.path.join(os.path.dirname(__file__), '../docs/research/runtime_text/*/text_*.bin')))
if dumps:
    code = open(dumps[-1], 'rb').read()
else:
    print('warning: no runtime .text dump; on-disk .text is encrypted', file=sys.stderr)
targets = {int(a, 0): a for a in sys.argv[1:]}
# Light mode in 1 MB chunks: detail mode over the whole .text took >10 GB with the game open (oomd killed the session).
import re
md = Cs(CS_ARCH_X86, CS_MODE_64); md.skipdata = True
rip = re.compile(r'\[rip ([+-]) (0x[0-9a-f]+|\d+)\]')
def func_start(addr):
    off = addr - base - va
    i = off
    while i > 0 and not (code[i - 1] == 0xcc and code[i] != 0xcc): i -= 1
    return base + va + i
CH = 1 << 20
pos = 0
while pos < len(code):
    end = min(pos + CH, len(code))
    last = pos
    for a, size, mn, ops in md.disasm_lite(code[pos:min(end + 16, len(code))], base + va + pos):
        if a - base - va >= end: break
        last = a - base - va + size
        m = rip.search(ops)
        if not m: continue
        disp = int(m.group(2), 0) * (1 if m.group(1) == '+' else -1)
        t = a + size + disp
        for tg in targets:
            if tg <= t < tg + 2:
                w = 'W' if mn.startswith('mov') and ops.startswith(('byte ptr [', 'word ptr [', 'dword ptr [', 'qword ptr [')) else 'R'
                print(f'{w} {a:#x} fn {func_start(a):#x}: {mn} {ops}', flush=True)
    pos = max(last, pos + 1)
