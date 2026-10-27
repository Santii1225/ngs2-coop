set pagination off
set height 0
set width 0
set confirm off
set can-use-hw-watchpoints 1
set logging file /tmp/ngs2coop/wp_dir.log
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
CHAR0 = 0x142f78b10          # character[0]  (Ryu, group 0)
CHAR1 = 0x142f79d50          # character[1]  (Momiji, group 1)
MAX = 44
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
def cap(tag, cbase):
    st["n"] += 1; n = st["n"]
    pc = rv("pc")
    thr = gdb.selected_thread()
    try: tname = thr.name or ""
    except Exception: tname = ""
    lwp = thr.ptid[1] if thr else 0
    R = {r: rv(r) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","r8","r9","r10","r11","r12","r13","r14","r15")}
    prev = rmem(pc-16, 16).hex(); here = rmem(pc, 16).hex()
    d30 = rmem(cbase+0x30, 16); d24 = rmem(cbase+0x24, 4); s04 = rmem(cbase+0x04, 1)
    print("HIT %2d [%s] pc=%#x thr=%s/%s" % (n, tag, pc, lwp, tname))
    print("     prev16=%s  here16=%s" % (prev, here))
    print("     rax=%#x rbx=%#x rcx=%#x rdx=%#x rsi=%#x rdi=%#x rbp=%#x r8=%#x r9=%#x r10=%#x r11=%#x r12=%#x r13=%#x r14=%#x r15=%#x"
          % (R["rax"],R["rbx"],R["rcx"],R["rdx"],R["rsi"],R["rdi"],R["rbp"],R["r8"],R["r9"],R["r10"],R["r11"],R["r12"],R["r13"],R["r14"],R["r15"]))
    print("     xmm0=%s xmm1=%s xmm2=%s xmm6=%s" % (xf("xmm0"),xf("xmm1"),xf("xmm2"),xf("xmm6")))
    if len(d30)==16 and len(d24)==4 and len(s04)==1:
        print("     [char+0x30]=(%.5f,%.5f,%.5f,%.5f)  [char+0x24]=%.5f  [char+0x04]=%#x"
              % (struct.unpack("<4f", d30) + struct.unpack("<f", d24) + (s04[0],)))
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

gdb.execute("watch *(unsigned long long *)%d" % (CHAR0 + 0x30))
pass
gdb.execute("watch *(unsigned long long *)%d" % (CHAR1 + 0x30))
print("=== armed WRITE: Ryu char+0x30(XY), Ryu char+0x24(speed), Momiji char+0x30(XY) ===")
gdb.execute("info watchpoints")
flush()
end
commands 1
silent
python cap("RYU_dir", 0x142f78b10)
cont
end
commands 2
silent
python cap("AI_dir", 0x142f79d50)
cont
end
cont
