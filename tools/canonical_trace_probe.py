#!/usr/bin/env python3
"""Phase 11 - read-only temporal trace of the position fields around the writer.

Static + runtime RE (this session) established the per-frame write path to
object+0x2B0:

  0x1354390 (per-actor loop over game_object[0..0xA0])
    -> 0x1353d00(record, index)
         -> 0x1353e37  movdqa [object+0x60 + 0x250], xmm6   ==> writes object+0x2B0
            (xmm6 = out-param of 0xf8e420, reached via 0xf7bb70)
       0xf7bb70 READS object+0x4B80 and character[group]+0x10E0 as position inputs.

object+0x4B80 is the strongest CANONICAL_POSITION candidate: it feeds the writer,
it is read pervasively for inter-actor distance math, and it is copied out to
character[group]+0x1010. This probe compares, over a short window:

  canonical?   object+0x4B80
  velocity?    object+0x4BC0        (0,0,0,0) at idle for player and partner)
  capsule?     object+0x4BD0        (x,z ~= pos, y ~= pos.y + ~1.1, w=1)
  observable   object+0x2B0
  copy         object+0x2E0
  interpolated object+0x310
  history      object+0x340 / +0x370
  char mirror  character[grp]+0x10E0 / +0x1010

STRICTLY READ-ONLY: /proc/<pid>/mem O_RDONLY + pread. No writes, no ptrace,
no core.dll. Resolves LOCAL_PLAYER (game_object[0]) and AI_PARTNER
(game_object[4]) from scratch each run.
"""
import argparse
import hashlib
import json
import math
import os
import struct
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

GAME_HASH = 'a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef'
CORE_HASH = 'ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d'
TABLE_RVA = 0x3195300
STRIDE = 0x30
GROUP_OFF = 0x1F
OBJID_OFF = 0x18
CHAR_TABLE_RVA = 0x2F78B10
CHAR_STRIDE = 0x1240
SLOT_RVA = 0x18F9518
CORE_CB_OFF = 0x16F2

OBJ_FIELDS = [
    ('canon_4B80', 0x4B80), ('vel_4BC0', 0x4BC0), ('capsule_4BD0', 0x4BD0),
    ('obs_2B0', 0x2B0), ('copy_2E0', 0x2E0), ('interp_310', 0x310),
    ('hist_340', 0x340), ('hist_370', 0x370), ('mirror_1930', 0x1930),
]
CHAR_FIELDS = [('char_10E0', 0x10E0), ('char_1010', 0x1010), ('char_310', 0x310)]


def find_pid():
    hits = []
    for e in Path('/proc').iterdir():
        if e.name.isdigit():
            try:
                if (e / 'comm').read_text().strip() == 'NINJA GAIDEN SI':
                    hits.append(int(e.name))
            except OSError:
                pass
    return hits


def parse_maps(pid):
    out = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        p = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in p[0].split('-'))
        out.append((lo, hi, p[1], int(p[2], 16), p[5] if len(p) > 5 else ''))
    return out


class Ctx:
    def __init__(self):
        pids = find_pid()
        if len(pids) != 1:
            raise RuntimeError(f'need one game PID, found {pids}')
        self.pid = pids[0]
        maps = parse_maps(self.pid)
        exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
        core = next((m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll')), None)
        if hashlib.sha256(Path(exe[4]).read_bytes()).hexdigest() != GAME_HASH:
            raise RuntimeError('EXE sha mismatch')
        if core is None or hashlib.sha256(Path(core[4]).read_bytes()).hexdigest() != CORE_HASH:
            raise RuntimeError('core.dll sha mismatch / not mapped')
        self.base = exe[0]
        self.core_base = core[0]
        self.maps = maps
        self.fd = os.open(f'/proc/{self.pid}/mem', os.O_RDONLY)
        slot = struct.unpack('<Q', self.rd(self.base + SLOT_RVA, 8))[0]
        if slot != self.core_base + CORE_CB_OFF:
            raise RuntimeError('Sigma2 hook slot mismatch')

    def rd(self, a, n):
        d = os.pread(self.fd, n, a)
        if len(d) != n:
            raise RuntimeError(f'short read {a:#x}+{n}')
        return d

    def f3(self, a):
        return list(struct.unpack('<3f', self.rd(a, 12)))

    def resolve(self, index):
        rec = self.rd(self.base + TABLE_RVA + index * STRIDE, STRIDE)
        obj = struct.unpack_from('<Q', rec, 0)[0]
        grp = rec[GROUP_OFF]
        oid = rec[OBJID_OFF]
        char = self.base + CHAR_TABLE_RVA + grp * CHAR_STRIDE
        return obj, grp, oid, char

    def snapshot(self, index):
        obj, grp, oid, char = self.resolve(index)
        rec = dict(index=index, obj_rva=hex(obj - self.base), group=grp, obj_id=oid)
        for name, off in OBJ_FIELDS:
            rec[name] = self.f3(obj + off)
        for name, off in CHAR_FIELDS:
            rec[name] = self.f3(char + off)
        return rec


def burst(ctx, indices, seconds, hz):
    n = int(seconds * hz)
    dt = 1.0 / hz
    frames = []
    t0 = time.time()
    for _ in range(n):
        row = dict(t=round(time.time() - t0, 5))
        for idx in indices:
            row[f'e{idx}'] = ctx.snapshot(idx)
        frames.append(row)
        time.sleep(dt)
    return frames


def analyse(frames, idx):
    """per-field: total displacement over the window, and lead/lag vs obs_2B0."""
    key = f'e{idx}'
    seq = [f[key] for f in frames]
    names = [n for n, _ in OBJ_FIELDS] + [n for n, _ in CHAR_FIELDS]
    out = {}
    for nm in names:
        pts = [s[nm] for s in seq]
        disp = math.dist(pts[0], pts[-1])
        rng = max(math.dist(p, pts[0]) for p in pts)
        out[nm] = dict(first=[round(v, 4) for v in pts[0]],
                       last=[round(v, 4) for v in pts[-1]],
                       disp=round(disp, 4), range=round(rng, 4))
    # lead/lag: cross-correlate canon_4B80 vs obs_2B0 X over frames
    cx = [s['canon_4B80'][0] for s in seq]
    ox = [s['obs_2B0'][0] for s in seq]
    best = (0, -1e9)
    for lag in range(-8, 9):
        a, b, num = [], [], 0
        for i in range(len(seq)):
            j = i + lag
            if 0 <= j < len(seq):
                a.append(cx[i]); b.append(ox[j]); num += 1
        if num > 4:
            ma, mb = sum(a) / num, sum(b) / num
            va = sum((x - ma) ** 2 for x in a) ** .5
            vb = sum((x - mb) ** 2 for x in b) ** .5
            if va > 1e-6 and vb > 1e-6:
                r = sum((a[k] - ma) * (b[k] - mb) for k in range(num)) / (va * vb)
                if r > best[1]:
                    best = (lag, r)
    out['_xcorr_canon_vs_obs'] = dict(best_lag=best[0], r=round(best[1], 4),
                                      note='best_lag>0 => canon_4B80 leads obs_2B0')
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', required=True)
    ap.add_argument('--tag', default='trace')
    ap.add_argument('--seconds', type=float, default=6.0)
    ap.add_argument('--hz', type=float, default=60.0)
    ap.add_argument('--indices', type=int, nargs='+', default=[0, 4])
    ap.add_argument('--wait-move', action='store_true',
                    help='poll obs_2B0 of entry 0 until it moves >0.15u, then capture')
    ap.add_argument('--wait-timeout', type=float, default=90.0)
    a = ap.parse_args()
    try:
        ctx = Ctx()
    except (OSError, RuntimeError) as e:
        print(f'ERROR: {e}', file=sys.stderr)
        return 1
    if a.wait_move:
        obj0, _, _, _ = ctx.resolve(0)
        p0 = ctx.f3(obj0 + 0x2B0)
        print(f'waiting for LOCAL_PLAYER to move from {tuple(round(v,3) for v in p0)} ...', flush=True)
        tw = time.time()
        while time.time() - tw < a.wait_timeout:
            obj0, _, _, _ = ctx.resolve(0)
            if math.dist(ctx.f3(obj0 + 0x2B0), p0) > 0.15:
                print(f'  motion detected after {time.time()-tw:.1f}s, capturing {a.seconds}s', flush=True)
                break
            time.sleep(0.05)
        else:
            print('  timeout waiting for motion; capturing anyway', flush=True)
    pre = {idx: ctx.snapshot(idx) for idx in a.indices}
    frames = burst(ctx, a.indices, a.seconds, a.hz)
    post = {idx: ctx.snapshot(idx) for idx in a.indices}
    result = dict(tool='canonical_trace_probe', tag=a.tag,
                  captured=datetime.now(timezone.utc).astimezone().isoformat(),
                  pid=ctx.pid, module_base=hex(ctx.base),
                  seconds=a.seconds, hz=a.hz, indices=a.indices,
                  pre=pre, post=post,
                  analysis={idx: analyse(frames, idx) for idx in a.indices},
                  frames=frames)
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    Path(a.out).write_text(json.dumps(result, indent=1) + '\n')
    os.close(ctx.fd)
    for idx in a.indices:
        an = result['analysis'][idx]
        print(f"\n=== entry {idx} (obj {pre[idx]['obj_rva']} grp {pre[idx]['group']} id {pre[idx]['obj_id']}) ===")
        for nm, _ in OBJ_FIELDS:
            d = an[nm]
            print(f"  {nm:14s} disp={d['disp']:8.4f}  range={d['range']:8.4f}  "
                  f"{tuple(d['first'])} -> {tuple(d['last'])}")
        for nm, _ in CHAR_FIELDS:
            d = an[nm]
            print(f"  {nm:14s} disp={d['disp']:8.4f}  range={d['range']:8.4f}")
        xc = an['_xcorr_canon_vs_obs']
        print(f"  xcorr canon_4B80 vs obs_2B0: best_lag={xc['best_lag']} r={xc['r']}  ({xc['note']})")
    print(f"\nwrote {a.out}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
