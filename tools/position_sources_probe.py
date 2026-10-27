#!/usr/bin/env python3
"""Phase 10 — map the position copies that feed / mirror object+0x2B0.

Read-only. /proc/<pid>/mem O_RDONLY + pread. No writes, no ptrace, no core.dll.
Resolves LOCAL_PLAYER (game_object[0]) from scratch and:
  - lists every float3 in a bounded object / character window that equals or is
    close to the current XYZ (position-copy candidates);
  - lists float3 that look like a velocity (small magnitude, not the position);
  - optional high-frequency burst of the known copy offsets to expose per-offset
    lag / jitter during a transition;
  - --compare A.json B.json prints the per-offset delta base->moved so the
    copies that follow the player exactly can be told from the laggy / stale
    ones.

NOTHING is written. This never touches the AI partner beyond listing it.
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
TABLE_STRIDE = 0x30
GROUP_OFF = 0x1F
POS_OFF = 0x2B0
CHAR_TABLE_RVA = 0x2F78B10
CHAR_STRIDE = 0x1240
SLOT_RVA = 0x18F9518
CORE_CALLBACK_OFF = 0x16F2

OBJ_WIN = 0x2000
CHAR_WIN = 0x1240
POS_TOL = 3.0          # |float3 - current XYZ| to call it a position copy

# known position-copy offsets (Phase 7-10). object-relative and character-relative.
OBJ_COPY_OFFS = [0x2B0, 0x2E0, 0x310, 0x340, 0x370, 0xAF0, 0xB20, 0x1330, 0x1360, 0x1930]
CHAR_COPY_OFFS = [0x310, 0xFE0, 0x1010, 0x10E0, 0x1120, 0x1160, 0x1170]


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
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts) > 5 else ''))
    return maps


def open_ctx():
    pids = find_pid()
    if len(pids) != 1:
        raise RuntimeError(f'need exactly one game PID, found {pids}')
    pid = pids[0]
    maps = parse_maps(pid)
    exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
    core = next((m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll')), None)
    if hashlib.sha256(Path(exe[4]).read_bytes()).hexdigest() != GAME_HASH:
        raise RuntimeError('EXE sha256 mismatch')
    if core is None or hashlib.sha256(Path(core[4]).read_bytes()).hexdigest() != CORE_HASH:
        raise RuntimeError('core.dll sha256 mismatch / not mapped')
    base = exe[0]
    fd = os.open(f'/proc/{pid}/mem', os.O_RDONLY)

    def readable(a, sz):
        end = a + sz
        for lo, hi, perms, *_ in maps:
            if lo <= a < hi and 'r' in perms:
                a = min(end, hi)
                if a == end:
                    return True
        return False

    def rd(a, sz):
        if not readable(a, sz):
            raise RuntimeError(f'unreadable {a:#x}+{sz:#x}')
        d = os.pread(fd, sz, a)
        if len(d) != sz:
            raise RuntimeError('short read')
        return d

    slot = struct.unpack('<Q', rd(base + SLOT_RVA, 8))[0]
    if slot != core[0] + CORE_CALLBACK_OFF:
        raise RuntimeError('Sigma2 hook slot mismatch')
    rec = rd(base + TABLE_RVA, TABLE_STRIDE)
    obj = struct.unpack_from('<Q', rec, 0)[0]
    group = rec[GROUP_OFF]
    char = base + CHAR_TABLE_RVA + group * CHAR_STRIDE
    return dict(pid=pid, base=base, core_base=core[0], obj=obj, group=group, char=char,
               rd=rd, readable=readable, fd=fd)


def scan_triples(blk, cur, tol, align=4):
    out = []
    for o in range(0, len(blk) - 12, align):
        t = struct.unpack_from('<3f', blk, o)
        if all(math.isfinite(v) for v in t):
            d = math.dist(t, cur)
            if d < tol:
                out.append((o, list(t), d))
    return out


def scan_velocity(blk, align=4):
    """float3 with every |comp| < 8 and not all ~0 and not obviously a unit vector."""
    out = []
    for o in range(0, len(blk) - 12, align):
        t = struct.unpack_from('<3f', blk, o)
        if not all(math.isfinite(v) for v in t):
            continue
        m = max(abs(v) for v in t)
        if 1e-4 < m < 8.0:
            n = math.sqrt(sum(v * v for v in t))
            if abs(n - 1.0) > 0.05:      # skip unit vectors (rotation rows)
                out.append((o, [round(v, 5) for v in t], round(n, 5)))
    return out


def capture(out_path, tag):
    c = open_ctx()
    rd = c['rd']
    obj, char, base = c['obj'], c['char'], c['base']
    x, y, z = struct.unpack('<3f', rd(obj + POS_OFF, 12))
    cur = (x, y, z)

    objblk = rd(obj, OBJ_WIN)
    charblk = rd(char, CHAR_WIN)

    pos_obj = scan_triples(objblk, cur, POS_TOL)
    pos_chr = scan_triples(charblk, cur, POS_TOL)

    # burst: 120 reads over ~2 s of every known copy offset, exact-match tracking
    burst = {f'obj+{o:#x}': [] for o in OBJ_COPY_OFFS}
    burst.update({f'char+{o:#x}': [] for o in CHAR_COPY_OFFS})
    t0 = time.time()
    stamps = []
    for _ in range(120):
        stamps.append(time.time() - t0)
        ob = rd(obj, OBJ_WIN)
        cb = rd(char, CHAR_WIN)
        for o in OBJ_COPY_OFFS:
            burst[f'obj+{o:#x}'].append(list(struct.unpack_from('<3f', ob, o)))
        for o in CHAR_COPY_OFFS:
            burst[f'char+{o:#x}'].append(list(struct.unpack_from('<3f', cb, o)))
        time.sleep(1 / 60)

    def summarize(seq):
        xs = [p[0] for p in seq]; ys = [p[1] for p in seq]; zs = [p[2] for p in seq]
        return dict(first=seq[0], last=seq[-1],
                    ptp=[round(max(xs) - min(xs), 6), round(max(ys) - min(ys), 6),
                         round(max(zs) - min(zs), 6)],
                    distinct=len({tuple(p) for p in seq}))

    vel_obj = scan_velocity(objblk)
    vel_chr = scan_velocity(charblk)

    info = dict(
        tool='position_sources_probe', tag=tag, captured=datetime.now(timezone.utc).astimezone().isoformat(),
        pid=c['pid'], module_base=hex(base), object=hex(obj), object_rva=hex(obj - base),
        group=c['group'], char=hex(char),
        current_xyz=list(cur),
        position_copies_object=[dict(off=hex(o), xyz=t, dist=round(d, 6)) for o, t, d in pos_obj],
        position_copies_character=[dict(off=hex(o), xyz=t, dist=round(d, 6)) for o, t, d in pos_chr],
        burst_interval_s=round((time.time() - t0) / len(stamps), 5),
        burst_summary={k: summarize(v) for k, v in burst.items()},
        velocity_candidates_object=[dict(off=hex(o), v=v, norm=n) for o, v, n in vel_obj][:40],
        velocity_candidates_character=[dict(off=hex(o), v=v, norm=n) for o, v, n in vel_chr][:40],
    )
    os.close(c['fd'])
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    Path(out_path).write_text(json.dumps(info, indent=2) + '\n')
    print(f"tag={tag} pid={c['pid']} object={hex(obj)} XYZ=({x:.5f},{y:.5f},{z:.5f})")
    print(f"object position-copies: {[p['off'] for p in info['position_copies_object']]}")
    print(f"character position-copies: {[p['off'] for p in info['position_copies_character']]}")
    print(f"burst distinct-value counts (>1 means it changed during the 2s window):")
    for k, s in info['burst_summary'].items():
        flag = '  <-- moved' if s['distinct'] > 1 else ''
        print(f"  {k:14s} ptp={s['ptp']} distinct={s['distinct']}{flag}")
    print(f"wrote {out_path}")


def compare(a_path, b_path):
    A = json.loads(Path(a_path).read_text())
    B = json.loads(Path(b_path).read_text())
    ax = A['current_xyz']; bx = B['current_xyz']
    dmove = math.dist(ax, bx)
    print(f"LOCAL_PLAYER current_xyz  A={tuple(round(v,3) for v in ax)}  B={tuple(round(v,3) for v in bx)}")
    print(f"player moved A->B: {dmove:.4f} u\n")
    keys = sorted(set(A['burst_summary']) | set(B['burst_summary']))
    print(f"{'offset':16s} {'A last (x,y,z)':30s} {'B last (x,y,z)':30s} {'move|xyz|':>10} {'follows?':>9}")
    for k in keys:
        a = A['burst_summary'].get(k, {}).get('last')
        b = B['burst_summary'].get(k, {}).get('last')
        if not a or not b:
            continue
        d = math.dist(a, b)
        # 'follows' if this copy moved by ~ the same amount as the player
        follows = 'EXACT' if abs(d - dmove) < 0.05 else ('CLOSE' if abs(d - dmove) < 1.0 else
                  'STALE' if d < 0.5 else 'DIFFERS')
        print(f"{k:16s} ({a[0]:8.2f},{a[1]:6.2f},{a[2]:8.2f})    "
              f"({b[0]:8.2f},{b[1]:6.2f},{b[2]:8.2f})   {d:10.4f} {follows:>9}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out', help='write capture JSON here')
    ap.add_argument('--tag', default='capture')
    ap.add_argument('--compare', nargs=2, metavar=('A.json', 'B.json'))
    a = ap.parse_args()
    try:
        if a.compare:
            compare(*a.compare)
            return 0
        out = a.out or ('docs/research/player/POS_SOURCES_' +
                        datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '.json')
        capture(out, a.tag)
        return 0
    except (OSError, RuntimeError) as e:
        print(f'ERROR: {e}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
