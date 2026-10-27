#!/usr/bin/env python3
"""Phase 11 - offline analysis helper for the runtime section dump.

Operates purely on the files produced by tools/runtime_text_dump.py. It never
touches the game process.

Provides:
  rva2off / off2rva         RVA <-> dump-file offset
  bytes RVA LEN             hexdump a runtime RVA
  dis RVA [LEN]             linear disassembly from an RVA (capstone x86-64)
  func RVA                  .pdata RUNTIME_FUNCTION covering RVA (begin/end/unwind)
  funcs                     dump the whole .pdata table (begin,end,unwind)
  xref RVA                  scan .text for E8/E9 rel32 and RIP-relative refs -> RVA
  callers RVA              like xref but only direct E8 calls, grouped by .pdata func

Usage:
  tools/rt_image.py --dump DIR <command> ...
"""
import argparse
import bisect
import struct
import sys
from pathlib import Path

try:
    from capstone import Cs, CS_ARCH_X86, CS_MODE_64, CS_OP_MEM, x86
    HAVE_CS = True
except ImportError:
    HAVE_CS = False


class Image:
    def __init__(self, dump_dir):
        self.dir = Path(dump_dir)
        man = self.dir / 'dump_manifest.json'
        import json
        self.manifest = json.loads(man.read_text())
        self.base = int(self.manifest['module_base'], 16)
        self.sections = {}
        for s in self.manifest['sections']:
            rva = int(s['rva'], 16)
            vsz = int(s['virtual_size'], 16)
            data = (self.dir / s['file']).read_bytes()
            self.sections[s['name']] = dict(rva=rva, vsize=vsz, data=data)

    def _sec_for_rva(self, rva):
        for name, s in self.sections.items():
            if s['rva'] <= rva < s['rva'] + s['vsize']:
                return name, s
        raise KeyError(f'RVA {rva:#x} not in any dumped section')

    def read(self, rva, n):
        name, s = self._sec_for_rva(rva)
        o = rva - s['rva']
        return s['data'][o:o + n]

    def rva2off(self, rva):
        name, s = self._sec_for_rva(rva)
        return name, rva - s['rva']

    # ---- .pdata ----
    def pdata_table(self):
        s = self.sections['.pdata']
        out = []
        for o in range(0, len(s['data']) - 11, 12):
            b, e, u = struct.unpack_from('<3I', s['data'], o)
            if b == 0 and e == 0 and u == 0:
                continue
            if b >= e:
                continue
            out.append((b, e, u))
        out.sort()
        return out

    def func_covering(self, rva):
        tbl = self.pdata_table()
        starts = [t[0] for t in tbl]
        i = bisect.bisect_right(starts, rva) - 1
        if 0 <= i < len(tbl) and tbl[i][0] <= rva < tbl[i][1]:
            return tbl[i]
        return None


def get_cs():
    md = Cs(CS_ARCH_X86, CS_MODE_64)
    md.detail = True
    return md


def cmd_dis(img, args):
    rva = int(args.rva, 0)
    length = int(args.len, 0) if args.len else 96
    code = img.read(rva, length)
    md = get_cs()
    for ins in md.disasm(code, rva):
        raw = ins.bytes.hex()
        print(f'{ins.address:#010x}  {raw:<24} {ins.mnemonic:<9} {ins.op_str}')


def cmd_bytes(img, args):
    rva = int(args.rva, 0)
    length = int(args.len, 0) if args.len else 64
    data = img.read(rva, length)
    for i in range(0, len(data), 16):
        chunk = data[i:i + 16]
        hexs = ' '.join(f'{b:02x}' for b in chunk)
        asci = ''.join(chr(b) if 32 <= b < 127 else '.' for b in chunk)
        print(f'{rva + i:#010x}  {hexs:<48} {asci}')


def cmd_func(img, args):
    rva = int(args.rva, 0)
    f = img.func_covering(rva)
    if not f:
        print(f'no .pdata RUNTIME_FUNCTION covers {rva:#x}')
        return
    b, e, u = f
    print(f'begin={b:#x} end={e:#x} size={e - b:#x} unwind={u:#x}')


def cmd_funcs(img, args):
    for b, e, u in img.pdata_table():
        print(f'{b:#x} {e:#x} {e - b:#x} {u:#x}')


def _scan_refs(img, target_rva):
    """Return (calls, jmps, riprefs) lists of source RVAs whose rel32 / RIP-disp
    resolves to target_rva. Linear byte scan of .text (not instruction-aware for
    the E8/E9 part; RIP part uses capstone over a window)."""
    s = img.sections['.text']
    data = s['data']
    base_rva = s['rva']
    calls, jmps = [], []
    n = len(data)
    for i in range(n - 5):
        op = data[i]
        if op == 0xE8 or op == 0xE9:
            rel = struct.unpack_from('<i', data, i + 1)[0]
            dst = base_rva + i + 5 + rel
            if dst == target_rva:
                (calls if op == 0xE8 else jmps).append(base_rva + i)
    return calls, jmps


def cmd_xref(img, args):
    target = int(args.rva, 0)
    calls, jmps = _scan_refs(img, target)
    print(f'target RVA {target:#x}')
    print(f'  E8 direct calls: {len(calls)}')
    for c in calls:
        f = img.func_covering(c)
        fs = f'{f[0]:#x}' if f else '?'
        print(f'    call site {c:#x}   in func {fs}')
    print(f'  E9 direct jmps : {len(jmps)}')
    for j in jmps:
        f = img.func_covering(j)
        fs = f'{f[0]:#x}' if f else '?'
        print(f'    jmp site  {j:#x}   in func {fs}')


def cmd_scandisp(img, args):
    """Linear-sweep disassemble .text and report every instruction with a memory
    operand whose displacement equals one of the given values. Prints mnemonic,
    operands, base/index regs and the containing .pdata function."""
    targets = set(int(v, 0) for v in args.disps)
    s = img.sections['.text']
    data = s['data']
    base_rva = s['rva']
    md = get_cs()
    md.detail = True
    step = 0x20000
    hits = 0
    # sweep in overlapping windows so instructions across window edges still decode
    pos = 0
    while pos < len(data):
        end = min(pos + step + 0x40, len(data))
        for ins in md.disasm(data[pos:end], base_rva + pos):
            if ins.address >= base_rva + min(pos + step, len(data)):
                break
            for op in ins.operands:
                if op.type != CS_OP_MEM:
                    continue
                disp = op.mem.disp
                if disp in targets:
                    reg_b = ins.reg_name(op.mem.base) if op.mem.base else '-'
                    reg_i = ins.reg_name(op.mem.index) if op.mem.index else '-'
                    is_store = ins.mnemonic.startswith(('mov', 'movups', 'movaps',
                                'movdqa', 'movdqu', 'movlps', 'movsd', 'movss', 'lea'))
                    f = img.func_covering(ins.address)
                    fs = f'{f[0]:#x}' if f else '?'
                    print(f'{ins.address:#010x} func={fs:>10}  {ins.mnemonic:<8} {ins.op_str}'
                          f'   [base={reg_b} idx={reg_i} disp={disp:#x}]')
                    hits += 1
        pos += step
    print(f'--- {hits} hits for disps {[hex(t) for t in targets]}')


def cmd_callers(img, args):
    target = int(args.rva, 0)
    calls, _ = _scan_refs(img, target)
    seen = {}
    for c in calls:
        f = img.func_covering(c)
        key = f[0] if f else None
        seen.setdefault(key, []).append(c)
    print(f'target RVA {target:#x}: {len(calls)} direct callers in {len(seen)} functions')
    for fstart, sites in sorted(seen.items(), key=lambda kv: (kv[0] is None, kv[0])):
        if fstart is None:
            print(f'  (no .pdata func)  sites: {[hex(x) for x in sites]}')
        else:
            f = img.func_covering(fstart)
            print(f'  func {fstart:#x}-{f[1]:#x} ({f[1] - fstart:#x})  '
                  f'sites: {[hex(x) for x in sites]}')


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dump', required=True, help='dump directory from runtime_text_dump.py')
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name in ('dis', 'bytes'):
        p = sub.add_parser(name)
        p.add_argument('rva')
        p.add_argument('len', nargs='?')
    for name in ('func', 'xref', 'callers'):
        p = sub.add_parser(name)
        p.add_argument('rva')
    sub.add_parser('funcs')
    p = sub.add_parser('scandisp')
    p.add_argument('disps', nargs='+')
    a = ap.parse_args()

    if a.cmd in ('dis',) and not HAVE_CS:
        print('ERROR: capstone not importable in this interpreter', file=sys.stderr)
        return 2
    img = Image(a.dump)
    {'dis': cmd_dis, 'bytes': cmd_bytes, 'func': cmd_func, 'funcs': cmd_funcs,
     'xref': cmd_xref, 'callers': cmd_callers, 'scandisp': cmd_scandisp}[a.cmd](img, a)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
