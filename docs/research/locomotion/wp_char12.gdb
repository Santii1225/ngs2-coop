set pagination off
set height 0
set width 0
set confirm off
set can-use-hw-watchpoints 1
set logging file /tmp/ngs2coop/wp_char12.log
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
MB = 0x140000000
TEXT_LO, TEXT_HI = 0x140001000, 0x14179e000
CHAR0 = 0x142f78b10          # RYU  char[0]
CHAR1 = 0x142f79d50          # MOMIJI char[1]
RYU_OBJ = 0x143197100
AI_OBJ  = 0x14319cdb0
MAX = 60
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
def cap(tag, cbase):
    st["n"] += 1; n = st["n"]
    pc = rv("pc"); rva = pc - MB
    thr = gdb.selected_thread()
    try: tname = thr.name or ""
    except Exception: tname = ""
    lwp = thr.ptid[1] if thr else 0
    R = {r: rv(r) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","r8","r9","r10","r11","r12","r13","r14","r15")}
    prev = rmem(pc-32, 32).hex(); here = rmem(pc, 16).hex()
    c10 = rmem(cbase+0x10, 16)
    c00 = rmem(cbase+0x00, 16)
    cF80 = rmem(cbase+0xF80, 16)
    print("HIT %2d [%s] pc=%#x rva=%#x thr=%s/%s" % (n, tag, pc, rva, lwp, tname))
    print("     prev32=%s" % prev)
    print("     here16=%s" % here)
    print("     rax=%#x rbx=%#x rcx=%#x rdx=%#x rsi=%#x rdi=%#x rbp=%#x rsp=%#x" % (R["rax"],R["rbx"],R["rcx"],R["rdx"],R["rsi"],R["rdi"],R["rbp"],R["rsp"]))
    print("     r8=%#x r9=%#x r10=%#x r11=%#x r12=%#x r13=%#x r14=%#x r15=%#x" % (R["r8"],R["r9"],R["r10"],R["r11"],R["r12"],R["r13"],R["r14"],R["r15"]))
    print("     [%s+0x00]=%s" % (tag, c00.hex(' ')))
    print("     [%s+0x10]=%s  (+0x12=%02x +0x13=%02x +0x16=%02x)" % (tag, c10.hex(' '), c10[2], c10[3], c10[6]))
    print("     [%s+0xF80]=%s  (+0xF83=%02x +0xF85=%02x +0xF8A=%02x)" % (tag, cF80.hex(' '), cF80[3], cF80[5], cF80[0xA]))
    # which known char/obj do the regs point at
    tags = []
    for rn in ("rax","rbx","rcx","rdx","rsi","rdi","r8","r9","r10","r11","r12","r13","r14","r15"):
        v = R[rn]
        if v == CHAR0: tags.append(rn+"=CHAR0")
        elif v == CHAR1: tags.append(rn+"=CHAR1")
        elif v == RYU_OBJ: tags.append(rn+"=RYU_OBJ")
        elif v == AI_OBJ: tags.append(rn+"=AI_OBJ")
    print("     regmap: " + (" ".join(tags) if tags else "(none of CHAR0/CHAR1/RYU_OBJ/AI_OBJ)"))
    try:
        raw = rmem(R["rsp"], 0x220)
        vals = struct.unpack("<%dQ" % (len(raw)//8), raw)
        rets = [(i*8,v) for i,v in enumerate(vals) if TEXT_LO <= v < TEXT_HI]
        print("     stack: " + " ".join("[+%#x]=%#x" % (o,v) for o,v in rets[:22]))
    except Exception as e:
        print("     stackerr", e)
    flush()
    if n >= MAX:
        print("=== MAX hits, detaching ==="); flush()
        gdb.execute("detach"); gdb.execute("quit")

gdb.execute("watch *(unsigned long long *)%d" % (CHAR0 + 0x10))
gdb.execute("watch *(unsigned long long *)%d" % (CHAR1 + 0x10))
print("=== armed WRITE watch (observe only): RYU char0+0x10 @ %#x , MOMIJI char1+0x10 @ %#x ===" % (CHAR0+0x10, CHAR1+0x10))
gdb.execute("info watchpoints")
flush()
end
commands 1
silent
python cap("RYU", 0x142f78b10)
cont
end
commands 2
silent
python cap("MOMIJI", 0x142f79d50)
cont
end
cont
