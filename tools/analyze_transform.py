#!/usr/bin/env python3
"""Offline analysis of player_transform_probe captures. Operates only on the
.bin files already on disk; never touches a process. Prints the position, a
fixed set of rotation candidates, and (optionally) the delta vs a baseline
capture.
"""
import argparse
import json
import math
import struct
from pathlib import Path

POS_OFF = 0x2B0
# rotation candidates discovered in AXIS_TEST_ORIGIN (object block, 4-float groups)
QUAT_CANDS = [0x60, 0xb0, 0x1b0, 0x1d0]
VEC3_CANDS = [0x10, 0xd0]           # small repeated direction-like vec3
# stride-0x30 transform-like table that begins at the position
TABLE_OFFS = [0x2b0, 0x2e0, 0x310, 0x340, 0x370]


def f3(b, o):
    return struct.unpack_from('<3f', b, o)


def f4(b, o):
    return struct.unpack_from('<4f', b, o)


def norm(v):
    return math.sqrt(sum(c * c for c in v))


def load(dir_, sample=0):
    d = Path(dir_)
    info = json.loads((d / 'snapshot.json').read_text())
    obj = (d / f'{sample}_object.bin').read_bytes()
    chs = (d / f'{sample}_character.bin').read_bytes()
    return info, obj, chs


def show(dir_, sample):
    info, obj, chs = load(dir_, sample)
    pos = f3(obj, POS_OFF)
    print(f"== {dir_}  (sample {sample}, {info['captured']}) ==")
    print(f"  object {info['object_addr']}  group {info['group']}")
    print(f"  position +0x2B0/2B4/2B8 : C0={pos[0]:.5f}  Y={pos[1]:.5f}  C2={pos[2]:.5f}")
    print(f"  char[+0x310]            : {tuple(round(x,5) for x in f3(chs, 0x310))}")
    print("  stride-0x30 table:")
    for o in TABLE_OFFS:
        print(f"    obj+0x{o:03x}: {tuple(round(x,5) for x in f3(obj, o))}")
    print("  quaternion candidates (value | norm):")
    for o in QUAT_CANDS:
        q = f4(obj, o)
        print(f"    obj+0x{o:03x}: ({q[0]:+.5f},{q[1]:+.5f},{q[2]:+.5f},{q[3]:+.5f})  |q|={norm(q):.5f}")
    print("  vec3 candidates (value | norm | atan2 yaw-ish):")
    for o in VEC3_CANDS:
        v = f3(obj, o)
        yaw = math.degrees(math.atan2(v[0], v[2])) if (v[0] or v[2]) else 0.0
        print(f"    obj+0x{o:03x}: ({v[0]:+.5f},{v[1]:+.5f},{v[2]:+.5f})  |v|={norm(v):.5f}  atan2(x,z)={yaw:+.2f}deg")
    return info, obj, chs


def diff(base_dir, cur_dir):
    _, b, _ = load(base_dir, 0)
    _, c, _ = load(cur_dir, 0)
    bp, cp = f3(b, POS_OFF), f3(c, POS_OFF)
    d = [cp[i] - bp[i] for i in range(3)]
    print(f"\n== delta  {base_dir} -> {cur_dir} ==")
    print(f"  dC0={d[0]:+.5f}  dY={d[1]:+.5f}  dC2={d[2]:+.5f}   |horiz|={math.hypot(d[0],d[2]):.5f}"
          f"   heading atan2(dC0,dC2)={math.degrees(math.atan2(d[0],d[2])):+.2f}deg")
    print("  quaternion candidate deltas:")
    for o in QUAT_CANDS:
        qb, qc = f4(b, o), f4(c, o)
        dq = [qc[i] - qb[i] for i in range(4)]
        ang = math.degrees(2 * math.acos(max(-1.0, min(1.0, abs(sum(qb[i]*qc[i] for i in range(4)) / (norm(qb)*norm(qc) + 1e-9))))))
        print(f"    obj+0x{o:03x}: d=({dq[0]:+.5f},{dq[1]:+.5f},{dq[2]:+.5f},{dq[3]:+.5f})  angle_between={ang:.2f}deg")
    print("  vec3 candidate deltas:")
    for o in VEC3_CANDS:
        vb, vc = f3(b, o), f3(c, o)
        dv = [vc[i] - vb[i] for i in range(3)]
        yb = math.degrees(math.atan2(vb[0], vb[2]))
        yc = math.degrees(math.atan2(vc[0], vc[2]))
        print(f"    obj+0x{o:03x}: d=({dv[0]:+.5f},{dv[1]:+.5f},{dv[2]:+.5f})  d_atan2(x,z)={yc-yb:+.2f}deg")


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('dirs', nargs='+', help='capture directories')
    ap.add_argument('--sample', type=int, default=0)
    ap.add_argument('--baseline', help='diff every dir against this one')
    a = ap.parse_args()
    for d in a.dirs:
        show(d, a.sample)
        print()
    if a.baseline:
        for d in a.dirs:
            if d != a.baseline:
                diff(a.baseline, d)
