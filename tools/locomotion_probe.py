#!/usr/bin/env python3
"""Phase 13 - read-only probe for the locomotion / input -> movement path.

Phase 12/13 static RE established:
  * per-actor locomotion update = 0x14249A0, dispatched by 0x1420F60 per
    game_object index, keyed on a state machine (jump table on character[group]+0x04);
  * it builds a desired movement vector in a stack local, speed-clamps it to
    0x1469F60()*const (a global per-frame max), and applies it via W1 (0x141BB90:
    object+0x4B80 += delta);
  * object+0x4BC0 (velocity) is written separately (0x14218C0 copies a per-actor
    indirected field; 0x14219A0 reads manager+0x7D0) -> it is a *published*
    velocity, not the direct W1 input;
  * character[group]+0x3F0 is a constant (0,1,0) at idle for both actors (an
    angle-check reference, not the move input).

This probe captures, read-only, for LOCAL_PLAYER (game_object[0]) and AI_PARTNER
(game_object[4]):
  - character[group]  full 0x1240 block
  - object            window +0x4B00 .. +0x5C40 (velocity / capsule / gate flags)
  - key scalars burst-sampled: char+0x04 (state code), obj+0x4B80, obj+0x4BC0
  - the control-block globals at .data 0x63F16A0 / 0x63F16A8

--compare A.json B.json  diffs two captures: every 4-byte word that changed in
the character block or the object window, decoded as float / int / bytes, so the
fields that follow the movement direction can be spotted.

STRICTLY READ-ONLY: /proc/<pid>/mem O_RDONLY + pread. No writes, no ptrace, no
core.dll. Nothing about the AI partner is modified.
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

CHAR_LEN = 0x1240
OBJ_WIN_LO = 0x4B00
OBJ_WIN_HI = 0x5C40
CB_GLOBALS = {'g_cur_game_object': 0x63F16A0, 'g_cur_character': 0x63F16A8,
              'g_w1_handle': 0x63F1690}


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
        m = parse_maps(self.pid)
        exe = next(x for x in m if x[3] == 0 and x[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
        core = next((x for x in m if x[3] == 0 and x[4].endswith('/plugin/core.dll')), None)
        if hashlib.sha256(Path(exe[4]).read_bytes()).hexdigest() != GAME_HASH:
            raise RuntimeError('EXE sha mismatch')
        if core is None or hashlib.sha256(Path(core[4]).read_bytes()).hexdigest() != CORE_HASH:
            raise RuntimeError('core.dll sha mismatch')
        self.base = exe[0]
        self.core_base = core[0]
        self.fd = os.open(f'/proc/{self.pid}/mem', os.O_RDONLY)
        slot = struct.unpack('<Q', self.rd(self.base + SLOT_RVA, 8))[0]
        if slot != self.core_base + CORE_CB_OFF:
            raise RuntimeError('Sigma2 hook slot mismatch')

    def rd(self, a, n):
        d = os.pread(self.fd, n, a)
        if len(d) != n:
            raise RuntimeError(f'short read {a:#x}+{n}')
        return d

    def resolve(self, index):
        rec = self.rd(self.base + TABLE_RVA + index * STRIDE, STRIDE)
        obj = struct.unpack_from('<Q', rec, 0)[0]
        grp = rec[GROUP_OFF]
        oid = rec[OBJID_OFF]
        char = self.base + CHAR_TABLE_RVA + grp * CHAR_STRIDE
        return obj, grp, oid, char

    def snap_actor(self, index):
        obj, grp, oid, char = self.resolve(index)
        cblk = self.rd(char, CHAR_LEN)
        oblk = self.rd(obj + OBJ_WIN_LO, OBJ_WIN_HI - OBJ_WIN_LO)
        return dict(index=index, obj_rva=hex(obj - self.base), group=grp, obj_id=oid,
                    char_rva=hex(char - self.base),
                    char_block=cblk.hex(), obj_window=oblk.hex(),
                    obj_window_base=OBJ_WIN_LO)


def burst(ctx, indices, seconds, hz):
    n = int(seconds * hz)
    dt = 1.0 / hz
    rows = []
    t0 = time.time()
    for _ in range(n):
        row = dict(t=round(time.time() - t0, 5))
        for idx in indices:
            obj, grp, oid, char = ctx.resolve(idx)
            row[f'e{idx}'] = dict(
                state04=ctx.rd(char + 4, 1)[0],
                ctrl00=ctx.rd(char + 0, 1)[0],
                pos4B80=list(struct.unpack('<3f', ctx.rd(obj + 0x4B80, 12))),
                vel4BC0=list(struct.unpack('<3f', ctx.rd(obj + 0x4BC0, 12))),
                char3F0=list(struct.unpack('<3f', ctx.rd(char + 0x3F0, 12))),
            )
        rows.append(row)
        time.sleep(dt)
    return rows


def capture(out, tag, indices, seconds, hz):
    ctx = Ctx()
    pre = {idx: ctx.snap_actor(idx) for idx in indices}
    rows = burst(ctx, indices, seconds, hz)
    post = {idx: ctx.snap_actor(idx) for idx in indices}
    gl = {}
    for name, rva in CB_GLOBALS.items():
        v = struct.unpack('<Q', ctx.rd(ctx.base + rva, 8))[0]
        gl[name] = dict(value=hex(v),
                        module_rel=hex(v - ctx.base) if ctx.base <= v < ctx.base + 0x8000000 else None)
    os.close(ctx.fd)
    res = dict(tool='locomotion_probe', tag=tag,
              captured=datetime.now(timezone.utc).astimezone().isoformat(),
              pid=ctx.pid, module_base=hex(ctx.base), indices=indices,
              seconds=seconds, hz=hz, pre=pre, post=post, globals=gl, burst=rows)
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text(json.dumps(res, indent=1) + '\n')
    for idx in indices:
        b = [r[f'e{idx}'] for r in rows]
        s04 = sorted({x['state04'] for x in b})
        vmax = max(max(abs(c) for c in x['vel4BC0']) for x in b)
        pd = math.dist(b[0]['pos4B80'], b[-1]['pos4B80'])
        print(f"entry {idx} ({pre[idx]['obj_rva']} grp {pre[idx]['group']}): "
              f"state04 seen={s04}  ctrl00={b[0]['ctrl00']:#x}  |vel|max={vmax:.4f}  posΔ={pd:.4f}")
    print(f"wrote {out}")


def _words(hexblk):
    raw = bytes.fromhex(hexblk)
    return raw


def _decode(off, a, b):
    fa = struct.unpack('<f', a)[0]
    fb = struct.unpack('<f', b)[0]
    ia = struct.unpack('<i', a)[0]
    ib = struct.unpack('<i', b)[0]
    fdesc = ''
    if all(math.isfinite(v) for v in (fa, fb)) and (abs(fa) < 1e9 and abs(fb) < 1e9):
        fdesc = f'  float {fa:+.5f} -> {fb:+.5f}'
    return f'  +{off:#06x}  {a.hex()} -> {b.hex()}   int {ia} -> {ib}{fdesc}'


def compare(a_path, b_path):
    A = json.loads(Path(a_path).read_text())
    B = json.loads(Path(b_path).read_text())
    for idx in A['indices']:
        if idx not in B['indices']:
            continue
        print(f'\n================ entry {idx} ================')
        for blk, label in (('char_block', 'character[group]'), ('obj_window', 'object window')):
            ra = _words(A['post'][str(idx)][blk])
            rb = _words(B['post'][str(idx)][blk])
            base_off = 0 if blk == 'char_block' else A['post'][str(idx)]['obj_window_base']
            n = min(len(ra), len(rb))
            print(f'--- {label} changed 4-byte words ---')
            hits = 0
            for o in range(0, n - 3, 4):
                wa, wb = ra[o:o + 4], rb[o:o + 4]
                if wa != wb:
                    print(_decode(base_off + o, wa, wb))
                    hits += 1
            if not hits:
                print('  (none)')
        # burst-level: state code range, velocity, char3F0 in each capture
        for cap, nm in ((A, 'A'), (B, 'B')):
            bb = [r[f'e{idx}'] for r in cap['burst']]
            s04 = sorted({x['state04'] for x in bb})
            v = [x['vel4BC0'] for x in bb]
            c3 = [x['char3F0'] for x in bb]
            vmax = max(max(abs(k) for k in q) for q in v)
            print(f'  [{nm}] state04={s04}  |vel4BC0|max={vmax:.4f}  '
                  f'char3F0 first={tuple(round(k,4) for k in c3[0])} last={tuple(round(k,4) for k in c3[-1])}')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out')
    ap.add_argument('--tag', default='cap')
    ap.add_argument('--seconds', type=float, default=3.0)
    ap.add_argument('--hz', type=float, default=60.0)
    ap.add_argument('--indices', type=int, nargs='+', default=[0, 4])
    ap.add_argument('--wait-move', action='store_true',
                    help='poll obj[0]+0x4B80 until it moves >0.3u, then capture')
    ap.add_argument('--wait-timeout', type=float, default=120.0)
    ap.add_argument('--compare', nargs=2, metavar=('A.json', 'B.json'))
    a = ap.parse_args()
    try:
        if a.compare:
            compare(*a.compare)
            return 0
        if a.wait_move:
            c = Ctx()
            o0, _, _, _ = c.resolve(0)
            p0 = struct.unpack('<3f', c.rd(o0 + 0x4B80, 12))
            print(f'waiting for LOCAL_PLAYER to move from {tuple(round(v,2) for v in p0)} ...', flush=True)
            tw = time.time()
            while time.time() - tw < a.wait_timeout:
                o0, _, _, _ = c.resolve(0)
                if math.dist(struct.unpack('<3f', c.rd(o0 + 0x4B80, 12)), p0) > 0.3:
                    print(f'  motion after {time.time()-tw:.1f}s', flush=True)
                    break
                time.sleep(0.05)
            os.close(c.fd)
        out = a.out or ('docs/research/locomotion/LOCO_' +
                        datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '.json')
        capture(out, a.tag, a.indices, a.seconds, a.hz)
        return 0
    except (OSError, RuntimeError) as e:
        print(f'ERROR: {e}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
