import ngs2mem as n, time, subprocess, os, math, json, sys
m=n.Mem(); o,g,c=m.actor(4); o0,g0,c0=m.actor(0)
orig=m.u8(c)
env2=dict(os.environ, VPAD_FIFO='/tmp/ngs2coop/vpad2.fifo')
def pos(a): return m.f3(a+n.O_CANON)
def run(label, bind, p1=None, p2=None, dur=1.2):
    m.write(c, bytes([1 if bind else orig])); time.sleep(0.6)
    a0=pos(o); r0=pos(o0)
    if p1: subprocess.Popen(['python3','vpad.py','stick','L',str(p1[0]),str(p1[1]),str(int(dur*1000))])
    if p2: subprocess.Popen(['python3','vpad.py','stick','L',str(p2[0]),str(p2[1]),str(int(dur*1000))],env=env2)
    time.sleep(dur+0.1)
    a1=pos(o); r1=pos(o0)
    da=[round(a1[i]-a0[i],2) for i in (0,2)]; dr=[round(r1[i]-r0[i],2) for i in (0,2)]
    print(f'{label:38s} partner d(x,z)={da} |{math.dist(a0,a1):5.2f}|  ryu d(x,z)={dr} |{math.dist(r0,r1):5.2f}|  states ryu={m.u8(c0+4):#x} ai={m.u8(c+4):#x}', flush=True)
m.write(0x14211e755, bytes([1]))
for rep in range(int(sys.argv[1]) if len(sys.argv)>1 else 1):
    run('A) AI mode, P2 stick up (expect none)', False, p2=(0,1))
    run('B) bound p1, no input (expect 0/0)', True)
    run('C) bound p1, P1 stick up (Ryu only)', True, p1=(0,1))
    run('D) bound p1, P2 stick up (partner only)', True, p2=(0,1))
    run('E) bound p1, P1 left + P2 right', True, p1=(-1,0), p2=(1,0))
m.write(0x14211e755, b"\x00"); m.write(c,bytes([orig])); print('restored', m.u8(c))
