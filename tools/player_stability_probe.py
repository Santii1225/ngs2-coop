#!/usr/bin/env python3
"""Tiny bounded read-only stability probe for the Player position candidate.
O_RDONLY/pread only. No attach, writes, inputs. Re-derives base and re-checks
the validated Sigma2 slot before each read. Total memory read is a few hundred
bytes. NOT a general resolver; companion to tools/player_snapshot.py.
"""
import argparse, hashlib, json, os, struct, time
from pathlib import Path
from datetime import datetime

GAME_HASH = 'a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef'
CORE_HASH = 'ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d'


def load_maps(pid):
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts) > 5 else ''))
    return maps


def probe(pid, out_path, count, interval):
    out_path = Path(out_path)
    if out_path.exists():
        raise RuntimeError('Refusing to overwrite probe output')
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
    samples = []
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

        for i in range(count):
            slot = struct.unpack('<Q', read(base + 0x18f9518, 8))[0]
            if slot != core[0] + 0x16f2:
                raise RuntimeError('Validated core callback not in slot')
            rec = read(base + 0x3195300, 0x30)               # game_object entry 0
            obj = struct.unpack_from('<Q', rec, 0)[0]
            group = rec[0x1f]
            obj_tri = struct.unpack('<3f', read(obj + 0x2b0, 12))
            char = base + 0x2f78b10 + group * 0x1240
            char_tri = struct.unpack('<3f', read(char + 0x310, 12))
            samples.append(dict(
                i=i, time=datetime.now().astimezone().isoformat(),
                slot=hex(slot), entry0_ptr=hex(obj), group=group,
                object_triple=list(obj_tri), object_triple_addr=hex(obj + 0x2b0),
                character_triple=list(char_tri), character_triple_addr=hex(char + 0x310),
                object_eq_character=list(obj_tri) == list(char_tri),
            ))
            if i != count - 1:
                time.sleep(interval)
        end_stat = Path(f'/proc/{pid}/stat').read_text()
        if end_stat.rsplit(')', 1)[1].split()[19] != start_stat.rsplit(')', 1)[1].split()[19]:
            raise RuntimeError('Process changed')
    finally:
        os.close(fd)
    info = dict(
        tool='player_stability_probe', pid=pid, module_base=hex(base),
        core_base=hex(core[0]), root_address=hex(base + 0x3195300),
        interval_s=interval, count=count, total_bytes_read=total,
        started=start_stat, samples=samples,
    )
    out_path.write_text(json.dumps(info, indent=2) + '\n')
    print(json.dumps(info, indent=2))


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('pid', type=int)
    ap.add_argument('output')
    ap.add_argument('--count', type=int, default=6)
    ap.add_argument('--interval', type=float, default=1.0)
    a = ap.parse_args()
    probe(a.pid, a.output, a.count, a.interval)
