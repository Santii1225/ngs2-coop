#!/usr/bin/env python3
"""Phase 7 bounded read-only capture around the resolved player object, for
XYZ-semantics and rotation characterization. O_RDONLY/pread only; no attach,
writes, or inputs. Companion to tools/player_resolver.py.

Per invocation it captures, for game_object entry <index>:
  - the object block           object + 0x0000 .. +0x1000   (4 KiB)
  - the character block         char   + 0x0000 .. +0x1240
  - the parsed position float3  object + 0x2B0
It takes two samples <interval> s apart so animation/timer noise can be
filtered, and re-validates module base + the Sigma2 hook slot before reading.
Total per run <= ~11 KiB of process memory. NOT a mass dump.
"""
import argparse
import hashlib
import json
import struct
import os
import time
from datetime import datetime
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
OBJ_WIN = 0x1000


def load_maps(pid):
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts) > 5 else ''))
    return maps


def capture(pid, out, index, interval):
    out = Path(out)
    if out.exists():
        raise RuntimeError('Refusing to overwrite capture directory')
    maps = load_maps(pid)
    exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
    core = next(m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll'))
    for m, expected in [(exe, GAME_HASH), (core, CORE_HASH)]:
        if hashlib.sha256(Path(m[4]).read_bytes()).hexdigest() != expected:
            raise RuntimeError('Unexpected binary identity')
    base = exe[0]
    start_stat = Path(f'/proc/{pid}/stat').read_text()
    fd = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
    total = 0
    try:
        def readable(addr, size):
            end = addr + size
            for lo, hi, perms, *_ in maps:
                if lo <= addr < hi and 'r' in perms:
                    addr = min(end, hi)
                    if addr == end:
                        return True
            return False

        def read(addr, size):
            nonlocal total
            if not readable(addr, size):
                raise RuntimeError(f'Unreadable {addr:#x}+{size:#x}')
            d = os.pread(fd, size, addr)
            if len(d) != size:
                raise RuntimeError('Short read')
            total += size
            return d

        slot = struct.unpack('<Q', read(base + SLOT_RVA, 8))[0]
        if slot != core[0] + CORE_CALLBACK_OFF:
            raise RuntimeError('Validated core callback not in slot')
        rec = read(base + TABLE_RVA + index * TABLE_STRIDE, TABLE_STRIDE)
        obj = struct.unpack_from('<Q', rec, 0)[0]
        group = rec[GROUP_OFF]
        char = base + CHAR_TABLE_RVA + group * CHAR_STRIDE
        if not (obj and readable(obj + OBJ_WIN - 1, 1)):
            raise RuntimeError(f'object pointer not usable: {obj:#x}')

        info = dict(
            tool='player_transform_probe', captured=datetime.now().astimezone().isoformat(),
            pid=pid, module_base=hex(base), core_base=hex(core[0]), slot=hex(slot),
            index=index, object_addr=hex(obj), object_rva=hex(obj - base), group=group,
            char_addr=hex(char), position_addr=hex(obj + POS_OFF),
            interval_s=interval, samples=[],
        )
        out.mkdir(parents=True)
        for s in range(2):
            objblk = read(obj, OBJ_WIN)
            charblk = read(char, CHAR_STRIDE)
            (out / f'{s}_object.bin').write_bytes(objblk)
            (out / f'{s}_character.bin').write_bytes(charblk)
            pos = struct.unpack_from('<3f', objblk, POS_OFF)
            info['samples'].append(dict(
                time=datetime.now().astimezone().isoformat(),
                position=list(pos),
                object_sha256=hashlib.sha256(objblk).hexdigest(),
                character_sha256=hashlib.sha256(charblk).hexdigest(),
            ))
            if s == 0:
                time.sleep(interval)
        end_stat = Path(f'/proc/{pid}/stat').read_text()
        if end_stat.rsplit(')', 1)[1].split()[19] != start_stat.rsplit(')', 1)[1].split()[19]:
            raise RuntimeError('Process changed')
        info['total_bytes_read'] = total
        (out / 'snapshot.json').write_text(json.dumps(info, indent=2) + '\n')
        print(json.dumps({k: info[k] for k in
                          ('pid', 'module_base', 'object_addr', 'group', 'position_addr')} |
                         {'position_s0': info['samples'][0]['position'],
                          'position_s1': info['samples'][1]['position'],
                          'total_bytes_read': total}, indent=2))
    finally:
        os.close(fd)


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('pid', type=int)
    ap.add_argument('output')
    ap.add_argument('--index', type=int, default=0)
    ap.add_argument('--interval', type=float, default=2.0)
    a = ap.parse_args()
    capture(a.pid, a.output, a.index, a.interval)
