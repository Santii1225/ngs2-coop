"""Validate the in-process NGS2Coop.dll: no external binding writes, only virtual pads + reads."""
import ngs2mem as n, time, subprocess, os, math, sys
m = n.Mem()
env2 = dict(os.environ, VPAD_FIFO='/tmp/ngs2coop/vpad2.fifo')
def actors():
    a0, a1 = m.player_actor(0), m.player_actor(1)
    return m.obj(a0), m.obj(a1), m.char(m.group(a0)), m.char(m.group(a1))
def pos(o): return m.f3(o + n.O_CANON)
def run(label, p1=None, p2=None, dur=1.2):
    o0, o1, c0, c1 = actors(); time.sleep(0.5)
    r0, a0 = pos(o0), pos(o1)
    if p1: subprocess.Popen(['python3', 'vpad.py', 'stick', 'L', str(p1[0]), str(p1[1]), str(int(dur*1000))])
    if p2: subprocess.Popen(['python3', 'vpad.py', 'stick', 'L', str(p2[0]), str(p2[1]), str(int(dur*1000))], env=env2)
    time.sleep(dur + 0.1)
    r1, a1 = pos(o0), pos(o1)
    print(f'{label:34s} P1 moved {math.dist(r0, r1):5.2f}   P2(partner) moved {math.dist(a0, a1):5.2f}   '
          f'ports P1={m.u8(c0)} P2={m.u8(c1)} padmap={list(m.read(0x14211e754, 2))} states {m.u8(c0+4):#x}/{m.u8(c1+4):#x}', flush=True)
for rep in range(int(sys.argv[1]) if len(sys.argv) > 1 else 1):
    run('idle')
    run('P1 stick only', p1=(0, 1))
    run('P2 stick only', p2=(0, 1))
    run('P1 left + P2 right', p1=(-1, 0), p2=(1, 0))
