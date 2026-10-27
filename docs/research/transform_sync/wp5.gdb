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
A_4BC8 = OBJ + 0x4BC8
MAX = 44
st = {"n": 0}
def rv(r):
    try: return int(gdb.parse_and_eval("$"+r)) & 0xffffffffffffffff
    except Exception: return 0
def rmem(a, n):
    try: return bytes(gdb.selected_inferior().read_memory(a, n))
    except Exception: return b""
def cap(tag):
    st["n"] += 1; n = st["n"]
    pc = rv("pc")
    R = {r: rv(r) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","r8","r9","r10","r11","r12","r13","r14","r15")}
    # decode the instruction just executed: read 16 bytes at pc-16..pc and pc..pc+16
    prev = rmem(pc-16, 16).hex()
    here = rmem(pc, 16).hex()
    print("HIT %2d [%s] pc=%#x  prevbytes=%s h... herebytes=%s" % (n,tag,pc,prev,here))
    print("     rax=%#x rbx=%#x rcx=%#x rdx=%#x rsi=%#x rdi=%#x r8=%#x r9=%#x r12=%#x r13=%#x r14=%#x r15=%#x rbp=%#x"
          % (R["rax"],R["rbx"],R["rcx"],R["rdx"],R["rsi"],R["rdi"],R["r8"],R["r9"],R["r12"],R["r13"],R["r14"],R["r15"],R["rbp"]))
    v4b80 = rmem(A_4B80, 16)
    if len(v4b80)==16:
        print("     [obj+0x4B80]=(%.4f,%.4f,%.4f)  [obj+0x4BC0]=%s" %
              (struct.unpack("<3f", v4b80[:12]) + (struct.unpack("<3f", rmem(OBJ+0x4BC0,12)) if len(rmem(OBJ+0x4BC0,12))==12 else (0,0,0),)))
    try:
        raw = rmem(R["rsp"], 0x220)
        vals = struct.unpack("<%dQ" % (len(raw)//8), raw)
        rets = [(i*8,v) for i,v in enumerate(vals) if TEXT_LO <= v < TEXT_HI]
        print("     stack: " + " ".join("[+%#x]=%#x" % (o,v) for o,v in rets[:16]))
    except Exception as e:
        print("     stackerr", e)
    if n >= MAX:
        print("=== MAX, detaching ==="); gdb.execute("detach"); gdb.execute("quit")
gdb.execute("awatch *(unsigned int*)%d" % A_4B80)
gdb.execute("awatch *(unsigned int*)%d" % A_4BC8)
end
commands 1
silent
python cap("A4B80")
cont
end
commands 2
silent
python cap("A4BC8")
cont
end
cont
