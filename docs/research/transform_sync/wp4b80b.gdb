set pagination off
set height 0
set width 0
set confirm off
set can-use-hw-watchpoints 1
set logging file /tmp/ngs2coop/wp4b80b.log
set logging overwrite on
set logging redirect on
set logging on
attach 14042
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
handle SIGPWR  nostop noprint pass
handle SIG33 nostop noprint pass
handle SIG34 nostop noprint pass
handle SIG35 nostop noprint pass
handle SIGPIPE nostop noprint pass
python
import gdb, struct, sys
TEXT_LO, TEXT_HI = 0x140001000, 0x14179e000
OBJ = 0x143197100
A_XY = OBJ + 0x4B80
A_Z  = OBJ + 0x4B88
MAX = 40
st = {"n": 0}
def flush():
    try: sys.stdout.flush()
    except Exception: pass
def rv(r):
    try: return int(gdb.parse_and_eval("$"+r)) & 0xffffffffffffffff
    except Exception: return 0
def rmem(a, n):
    try: return bytes(gdb.selected_inferior().read_memory(a, n))
    except Exception: return b""
def xf(name):
    try:
        v = int(gdb.parse_and_eval("$%s.uint128" % name)) & ((1<<128)-1)
        return "(%.4f,%.4f,%.4f,%.4f)" % struct.unpack("<4f", v.to_bytes(16,"little"))
    except Exception: return "?"
def cap(tag):
    st["n"] += 1; n = st["n"]
    pc = rv("pc")
    thr = gdb.selected_thread()
    try: tname = thr.name or ""
    except Exception: tname = ""
    lwp = thr.ptid[1] if thr else 0
    R = {r: rv(r) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","r8","r9","r10","r11","r12","r13","r14","r15")}
    prev = rmem(pc-16, 16).hex(); here = rmem(pc, 16).hex()
    p80 = rmem(OBJ+0x4B80, 12); pc0 = rmem(OBJ+0x4BC0, 12); pd0 = rmem(OBJ+0x4BD0, 12)
    print("HIT %2d [%s] pc=%#x thr=%s/%s" % (n, tag, pc, lwp, tname))
    print("     prev16=%s  here16=%s" % (prev, here))
    print("     rax=%#x rbx=%#x rcx=%#x rdx=%#x rsi=%#x rdi=%#x rbp=%#x r8=%#x r9=%#x r10=%#x r11=%#x r12=%#x r13=%#x r14=%#x r15=%#x"
          % (R["rax"],R["rbx"],R["rcx"],R["rdx"],R["rsi"],R["rdi"],R["rbp"],R["r8"],R["r9"],R["r10"],R["r11"],R["r12"],R["r13"],R["r14"],R["r15"]))
    print("     xmm0=%s xmm1=%s xmm2=%s xmm6=%s" % (xf("xmm0"),xf("xmm1"),xf("xmm2"),xf("xmm6")))
    if len(p80)==12 and len(pc0)==12 and len(pd0)==12:
        print("     [+0x4B80]=(%.4f,%.4f,%.4f) [+0x4BC0]=(%.4f,%.4f,%.4f) [+0x4BD0]=(%.4f,%.4f,%.4f)"
              % (struct.unpack("<3f",p80)+struct.unpack("<3f",pc0)+struct.unpack("<3f",pd0)))
    try:
        raw = rmem(R["rsp"], 0x260)
        vals = struct.unpack("<%dQ" % (len(raw)//8), raw)
        rets = [(i*8,v) for i,v in enumerate(vals) if TEXT_LO <= v < TEXT_HI]
        print("     stack: " + " ".join("[+%#x]=%#x" % (o,v) for o,v in rets[:20]))
    except Exception as e:
        print("     stackerr", e)
    flush()
    if n >= MAX:
        print("=== MAX hits, detaching ==="); flush()
        gdb.execute("detach"); gdb.execute("quit")

gdb.execute("watch *(unsigned long long *)%d" % A_XY)
gdb.execute("watch *(unsigned int *)%d" % A_Z)
print("=== watchpoints armed on object+0x4B80 (X/Y 8B) and +0x4B88 (Z 4B) ===")
gdb.execute("info watchpoints")
flush()
end
commands 1
silent
python cap("W_XY")
cont
end
commands 2
silent
python cap("W_Z")
cont
end
cont
