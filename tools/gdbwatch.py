#!/usr/bin/env python3
"""Hardware watchpoint sampler: attach gdb, collect N hits (pc + regs + return addrs), detach.

  gdbwatch.py ADDR [--kind rwatch|watch|awatch] [--size 4] [--max 30] [--timeout 20]
"""
import argparse, subprocess, tempfile, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import ngs2mem

ap = argparse.ArgumentParser()
ap.add_argument('addr', type=lambda s: int(s, 0))
ap.add_argument('--kind', default='awatch')
ap.add_argument('--size', type=int, default=4)
ap.add_argument('--max', type=int, default=30)
ap.add_argument('--timeout', type=int, default=20)
ap.add_argument('--uniq', action='store_true', help='print only first hit per pc')
a = ap.parse_args()
pid = ngs2mem.pid()
ctype = {1: 'char', 2: 'short', 4: 'int', 8: 'long long'}[a.size]
script = f'''set pagination off
set confirm off
set height 0
handle SIGUSR1 SIGUSR2 nostop noprint pass
attach {pid}
python
import gdb, struct
TEXT_LO, TEXT_HI = 0x140001000, 0x14179e000
st = {{"n": 0, "seen": set()}}
def cap():
    st["n"] += 1
    def rv(r):
        try: return int(gdb.parse_and_eval("$"+r)) & 0xffffffffffffffff
        except Exception: return 0
    pc = rv("pc")
    if {a.uniq} and pc in st["seen"]:
        pass
    else:
        st["seen"].add(pc)
        regs = " ".join("%s=%#x" % (r, rv(r)) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","r8","r9","r10","r12","r13","r14","r15"))
        rsp = rv("rsp")
        try:
            vals = struct.unpack("<96Q", gdb.selected_inferior().read_memory(rsp, 0x300))
            rets = " ".join("%#x" % v for v in vals if TEXT_LO <= v < TEXT_HI)
        except Exception as e:
            rets = str(e)
        th = gdb.selected_thread()
        print("HIT %d pc=%#x th=%s %s\\n   ret: %s" % (st["n"], pc, th.name, regs, rets[:300]))
    if st["n"] >= {a.max}:
        gdb.execute("detach"); gdb.execute("quit")
gdb.execute("{a.kind} *({ctype}*){a.addr}")
end
commands
silent
python cap()
cont
end
cont
'''
with tempfile.NamedTemporaryFile('w', suffix='.gdb', delete=False) as f:
    f.write(script)
try:
    out = subprocess.run(['timeout', '-s', 'INT', str(a.timeout), 'gdb', '-q', '-batch', '-x', f.name],
                         capture_output=True, text=True)
    for l in out.stdout.splitlines():
        if l.startswith('HIT') or l.startswith('   ret'):
            print(l)
finally:
    os.unlink(f.name)
    # make sure the process is not left stopped
    subprocess.run(['kill', '-CONT', str(pid)])
