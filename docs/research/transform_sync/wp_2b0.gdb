set pagination off
set height 0
set width 0
set confirm off
attach 14042
python
import gdb, struct
TEXT_LO, TEXT_HI = 0x140001000, 0x14179e000
ADDR = 0x1431973b0
MAX = 30
state = {"n": 0}

def cap():
    state["n"] += 1
    n = state["n"]
    def rv(r):
        try:
            return int(gdb.parse_and_eval("$"+r)) & 0xffffffffffffffff
        except Exception:
            return 0
    pc = rv("pc")
    rcx, rdx, r8, r9 = rv("rcx"), rv("rdx"), rv("r8"), rv("r9")
    rsi, rdi, rbx, rbp, rsp, rax = rv("rsi"), rv("rdi"), rv("rbx"), rv("rbp"), rv("rsp"), rv("rax")
    print("HIT %2d pc=%#012x rcx=%#x rdx=%#x r8=%#x r9=%#x rsi=%#x rdi=%#x rbx=%#x rbp=%#x rax=%#x rsp=%#x"
          % (n, pc, rcx, rdx, r8, r9, rsi, rdi, rbx, rbp, rax, rsp))
    try:
        raw = gdb.selected_inferior().read_memory(rsp, 0x200)
        vals = struct.unpack("<64Q", raw)
        rets = [(i*8, v) for i, v in enumerate(vals) if TEXT_LO <= v < TEXT_HI]
        print("   stack retaddrs: " + " ".join("[+%#x]=%#x" % (o, v) for o, v in rets[:16]))
    except Exception as e:
        print("   stackerr", e)
    if n >= MAX:
        print("=== MAX hits reached, detaching ===")
        gdb.execute("detach")
        gdb.execute("quit")

gdb.execute("awatch *(unsigned int*)%d" % ADDR)
# attach commands to the last breakpoint
bp = gdb.breakpoints()[-1]
class H(gdb.Command):
    pass
gdb.execute("echo watchpoint set\\n")
end
commands
silent
python cap()
cont
end
cont
