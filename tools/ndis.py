#!/usr/bin/env -S sh -c 'exec "${NGS2_VENV:-$HOME/.cache/ngs2-venv}/bin/python" "$0" "$@"'
"""dis.py ADDR [LEN] -- disassemble live game memory (capstone)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import ngs2mem
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
a = int(sys.argv[1], 0); n = int(sys.argv[2], 0) if len(sys.argv) > 2 else 0x100
m = ngs2mem.Mem()
md = Cs(CS_ARCH_X86, CS_MODE_64)
for i in md.disasm(m.read(a, n), a):
    print(f'{i.address:#x}: {i.mnemonic:8s} {i.op_str}')
