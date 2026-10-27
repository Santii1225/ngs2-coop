set pagination off
set height 0
set width 0
set confirm off
set can-use-hw-watchpoints 1
attach 14042
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
handle SIGPWR  nostop noprint pass
handle SIG33 nostop noprint pass
handle SIG34 nostop noprint pass
handle SIG35 nostop noprint pass
handle SIGPIPE nostop noprint pass
python
import gdb, struct
TEXT_LO, TEXT_HI = 0x140001000, 0x14179e000
OBJ = 0x143197100
A_4B80 = OBJ + 0x4B80
A_10E0 = 0x142f79bf0
MAX = 40
st = {"n": 0}
def rv(r):
    try: return int(gdb.parse_and_eval("$"+r)) & 0xffffffffffffffff
    except Exception: return 0
def xf(name):
    try:
        v = int(gdb.parse_and_eval("$%s.uint128" % name)) & ((1<<128)-1)
        return "(%.5f,%.5f,%.5f,%.5f)" % struct.unpack("<4f", v.to_bytes(16,"little"))
    except Exception: return "?"
def cap(tag):
    st["n"] += 1; n = st["n"]
    pc = rv("pc")
    R = {r: rv(r) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","r8","r9","r10","r11","r12","r13","r14","r15")}
    print("HIT %2d [%s] pc=%#x rax=%#x rbx=%#x rcx=%#x rdx=%#x rsi=%#x rdi=%#x r8=%#x r9=%#x r12=%#x r13=%#x r14=%#x r15=%#x rbp=%#x"
          % (n,tag,pc,R["rax"],R["rbx"],R["rcx"],R["rdx"],R["rsi"],R["rdi"],R["r8"],R["r9"],R["r12"],R["r13"],R["r14"],R["r15"],R["rbp"]))
    print("     xmm0=%s xmm1=%s xmm2=%s xmm6=%s" % (xf("xmm0"),xf("xmm1"),xf("xmm2"),xf("xmm6")))
    try:
        raw = gdb.selected_inferior().read_memory(R["rsp"], 0x280)
        vals = struct.unpack("<80Q", raw)
        rets = [(i*8,v) for i,v in enumerate(vals) if TEXT_LO <= v < TEXT_HI]
        print("     stack: " + " ".join("[+%#x]=%#x" % (o,v) for o,v in rets[:22]))
    except Exception as e:
        print("     stackerr", e)
    if n >= MAX:
        print("=== MAX, detaching ==="); gdb.execute("detach"); gdb.execute("quit")
gdb.execute("awatch *(unsigned int*)%d" % A_4B80)
gdb.execute("awatch *(unsigned int*)%d" % A_10E0)
end
commands 1
silent
python cap("A+0x4B80")
cont
end
commands 2
silent
python cap("Achar+0x10E0")
cont
end
cont
