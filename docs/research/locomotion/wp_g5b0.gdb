set pagination off
set height 0
set width 0
set confirm off
set can-use-hw-watchpoints 1
set logging file /tmp/ngs2coop/wp_g5b0.log
set logging overwrite on
set logging redirect on
set logging on
attach 14042
handle SIGUSR1 nostop noprint pass
handle SIGUSR2 nostop noprint pass
handle SIGPWR nostop noprint pass
handle SIG33 nostop noprint pass
handle SIG34 nostop noprint pass
handle SIG35 nostop noprint pass
handle SIGPIPE nostop noprint pass
python
import gdb, struct, sys
TEXT_LO, TEXT_HI = 0x140001000, 0x14179e000
G = 0x1463F16B0
MAX = 46
st={"n":0}
def flush():
    try: sys.stdout.flush()
    except Exception: pass
def rv(r):
    try: return int(gdb.parse_and_eval("$"+r)) & 0xffffffffffffffff
    except Exception: return 0
def rmem(a,n):
    try: return bytes(gdb.selected_inferior().read_memory(a,n))
    except Exception: return b""
def xf(nm):
    try:
        v=int(gdb.parse_and_eval("$%s.uint128"%nm))&((1<<128)-1)
        return "(%.4f,%.4f,%.4f,%.4f)"%struct.unpack("<4f",v.to_bytes(16,"little"))
    except Exception: return "?"
def cap(tag):
    st["n"]+=1;n=st["n"]
    pc=rv("pc");thr=gdb.selected_thread()
    try: tn=thr.name or ""
    except Exception: tn=""
    lwp=thr.ptid[1] if thr else 0
    R={r:rv(r) for r in ("rax","rbx","rcx","rdx","rsi","rdi","rbp","rsp","r8","r9","r10","r11","r12","r13","r14","r15")}
    print("HIT %2d [%s] pc=%#x thr=%s/%s"%(n,tag,pc,lwp,tn))
    print("     prev24=%s here16=%s"%(rmem(pc-24,24).hex(),rmem(pc,16).hex()))
    print("     rax=%#x rbx=%#x rcx=%#x rdx=%#x rsi=%#x rdi=%#x rbp=%#x r8=%#x r9=%#x r10=%#x r11=%#x r12=%#x r13=%#x r14=%#x r15=%#x"%(R["rax"],R["rbx"],R["rcx"],R["rdx"],R["rsi"],R["rdi"],R["rbp"],R["r8"],R["r9"],R["r10"],R["r11"],R["r12"],R["r13"],R["r14"],R["r15"]))
    print("     xmm0=%s xmm1=%s xmm2=%s xmm3=%s xmm6=%s"%(xf("xmm0"),xf("xmm1"),xf("xmm2"),xf("xmm3"),xf("xmm6")))
    g=rmem(G,16)
    if len(g)==16: print("     [g_cmd 0x63F16B0]=(%.5f,%.5f,%.5f,%.5f)"%struct.unpack("<4f",g))
    try:
        raw=rmem(R["rsp"],0x300);vals=struct.unpack("<%dQ"%(len(raw)//8),raw)
        rets=[(i*8,v) for i,v in enumerate(vals) if TEXT_LO<=v<TEXT_HI]
        print("     stack: "+" ".join("[+%#x]=%#x"%(o,v) for o,v in rets[:26]))
    except Exception as e: print("     stackerr",e)
    flush()
    if n>=MAX:
        print("=== MAX, detaching ===");flush();gdb.execute("detach");gdb.execute("quit")
gdb.execute("watch *(unsigned long long *)%d"%G)
gdb.execute("watch *(unsigned long long *)%d"%(G+8))
print("=== armed WRITE: g_cmd 0x63F16B0 (XY,ZW) ===")
gdb.execute("info watchpoints");flush()
end
commands 1
silent
python cap("GCMD_XY")
cont
end
commands 2
silent
python cap("GCMD_ZW")
cont
end
cont
