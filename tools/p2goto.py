#!/usr/bin/env python3
"""Lab: closed-loop steering of a player with its virtual pad toward a world point.

  p2goto.py [player=1] [offset_x=2.0] [offset_z=0.0]   target = player-1 position + offset
The stick is camera-relative; the stick->world rotation is estimated online from the
observed velocity heading, so no camera data is needed.
"""
import ngs2mem as n, time, subprocess, os, math, sys

m = n.Mem()
player = int(sys.argv[1]) if len(sys.argv) > 1 else 1
ox = float(sys.argv[2]) if len(sys.argv) > 2 else 2.0
oz = float(sys.argv[3]) if len(sys.argv) > 3 else 0.0
fifo = '/tmp/ngs2coop/vpad2.fifo' if player == 1 else '/tmp/ngs2coop/vpad.fifo'


def axis(x, y):
    with open(fifo, 'w') as f:
        f.write(f'axis L {x:.3f} {y:.3f}\n')


def pos(p):
    v = m.f3(m.obj(m.player_actor(p)) + n.O_CANON)
    return v[0], v[2]


theta = 0.0          # world_angle = stick_angle + theta   (sign flip handled by `flip`)
flip = float(os.environ.get('FLIP', '-1'))
prev = pos(player); prev_t = time.time()
s_ang = 0.0
t_end = time.time() + 25
try:
    while time.time() < t_end:
        me = pos(player)
        ref = pos(0)
        tgt = (ref[0] + ox, ref[1] + oz) if player == 1 else (ox, oz)
        d = (tgt[0] - me[0], tgt[1] - me[1])
        dist = math.hypot(*d)
        if dist < 1.0:
            break
        now = time.time()
        v = (me[0] - prev[0], me[1] - prev[1])
        if math.hypot(*v) > 0.05:
            wo = math.atan2(v[1], v[0])
            est = wo - flip * s_ang
            err = math.atan2(math.sin(est - theta), math.cos(est - theta))
            theta += 0.5 * err
        prev, prev_t = me, now
        w = math.atan2(d[1], d[0])
        s_ang = flip * (w - theta)
        mag = 1.0 if dist > 3 else 0.5
        axis(mag * math.cos(s_ang), mag * math.sin(s_ang))
        time.sleep(0.12)
finally:
    axis(0, 0)
print(f'final dist {math.hypot(tgt[0]-pos(player)[0], tgt[1]-pos(player)[1]):.2f}  theta {math.degrees(theta):.1f} deg')
