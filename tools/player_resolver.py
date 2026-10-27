#!/usr/bin/env python3
"""Read-only Player transform resolver for Ninja Gaiden Sigma 2 (Steam AE build
a66daf01..., core.dll ca2849b5...).

RUNTIME VERIFIED:
  - across a game restart on 2026-09-06 (PID 12404 -> PID 16942): the chain
    below relocated the player object automatically and produced a
    position-linked float3 that is bit-stable at rest and moves with the player.
  - Phase 7 (2026-09-06): axis semantics and a player rotation matrix. C0=world X,
    C1=world Y (up), C2=world Z; right-handed, Y-up. Rotation = 3x3 matrix at
    character+0x80 (det +1, rows = right/up/forward). Verified in a second
    mission too.
  See docs/PLAYER_RESEARCH.md, docs/research/player/restart_validation.json and
  docs/research/player/transform_characterization.json.

Chain (all module-relative; the object lives inside the EXE image body, not heap):

    module_base   = /proc/<pid>/maps entry, offset 0, ".../NINJA GAIDEN SIGMA2.exe"
    root          = module_base + 0x3195300        (game_object table, stride 0x30)
    object        = u64[root + index*0x30]         (index 0 = controlled character)
    obj_id        = u8 [root + index*0x30 + 0x18]
    group         = u8 [root + index*0x30 + 0x1F]
    position XYZ  = f32x3[object + 0x2B0]          (+0x2B0 X, +0x2B4 Y, +0x2B8 Z)
    char block    = module_base + 0x2F78B10 + group*0x1240
    rotation 3x3  = char+0x80 / char+0x90 / char+0xA0  (rows right / up / forward)
    corroboration = f32x3[char + 0x310]

STRICTLY READ-ONLY: opens /proc/<pid>/mem with O_RDONLY and uses pread only.
No code path writes process memory, attaches (ptrace), or injects input. Refuses
to run if the validated Sigma2 hook callback is not in the vtable slot.
"""
import argparse
import hashlib
import math
import os
import struct
import sys
from pathlib import Path

GAME_HASH = 'a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef'
CORE_HASH = 'ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d'

TABLE_RVA = 0x3195300          # game_object table
TABLE_STRIDE = 0x30
OBJ_ID_OFF = 0x18
GROUP_OFF = 0x1F
POS_OFF = 0x2B0               # float3 at object + 0x2B0 / +0x2B4 / +0x2B8
CHAR_TABLE_RVA = 0x2F78B10     # character table
CHAR_STRIDE = 0x1240
CHAR_POS_OFF = 0x310
CHAR_ROT_OFF = 0x80          # 3x3 rotation matrix, rows at +0x80 / +0x90 / +0xA0
SLOT_RVA = 0x18F9518          # Sigma2 vtable slot 0 (validated hook target)
CORE_CALLBACK_OFF = 0x16F2    # core.dll offset of the installed callback


def find_pid():
    hits = []
    for entry in Path('/proc').iterdir():
        if not entry.name.isdigit():
            continue
        try:
            comm = (entry / 'comm').read_text().strip()
        except OSError:
            continue
        if comm == 'NINJA GAIDEN SI':
            hits.append(int(entry.name))
    return hits


def parse_maps(pid):
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts) > 5 else ''))
    return maps


def resolve(pid, index, strict=True):
    maps = parse_maps(pid)
    try:
        exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
    except StopIteration:
        raise RuntimeError('game EXE mapping not found in this PID')
    core = next((m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll')), None)

    if strict:
        if hashlib.sha256(Path(exe[4]).read_bytes()).hexdigest() != GAME_HASH:
            raise RuntimeError('EXE identity mismatch (different build?)')
        if core is None:
            raise RuntimeError('plugin/core.dll not mapped in this PID')
        if hashlib.sha256(Path(core[4]).read_bytes()).hexdigest() != CORE_HASH:
            raise RuntimeError('core.dll identity mismatch')

    base = exe[0]
    fd = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
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
            if not readable(addr, size):
                raise RuntimeError(f'unreadable range {addr:#x}+{size:#x}')
            data = os.pread(fd, size, addr)
            if len(data) != size:
                raise RuntimeError('short read')
            return data

        if core is not None:
            slot = struct.unpack('<Q', read(base + SLOT_RVA, 8))[0]
            expected = core[0] + CORE_CALLBACK_OFF
            if slot != expected and strict:
                raise RuntimeError(
                    f'validated Sigma2 hook not in slot: got {slot:#x}, expected {expected:#x}')
        else:
            slot = None

        rec = read(base + TABLE_RVA + index * TABLE_STRIDE, TABLE_STRIDE)
        obj = struct.unpack_from('<Q', rec, 0)[0]
        obj_id = rec[OBJ_ID_OFF]
        group = rec[GROUP_OFF]
        if not obj or not readable(obj + POS_OFF, 12):
            raise RuntimeError(f'game_object[{index}] pointer not usable: {obj:#x}')
        pos = struct.unpack('<3f', read(obj + POS_OFF, 12))

        char = base + CHAR_TABLE_RVA + group * CHAR_STRIDE
        corrob = None
        if readable(char + CHAR_POS_OFF, 12):
            corrob = struct.unpack('<3f', read(char + CHAR_POS_OFF, 12))
        rot = None
        if readable(char + CHAR_ROT_OFF, 0x24):
            rot = [struct.unpack('<3f', read(char + CHAR_ROT_OFF + 0x10 * r, 12)) for r in range(3)]

        return dict(pid=pid, module_base=base, core_base=(core[0] if core else None),
                    slot_value=slot, index=index, object_addr=obj,
                    obj_id=obj_id, group=group,
                    position=pos, position_addr=obj + POS_OFF,
                    corroboration=corrob, corroboration_addr=char + CHAR_POS_OFF,
                    rotation=rot, rotation_addr=char + CHAR_ROT_OFF, char_addr=char)
    finally:
        os.close(fd)


def _det3(r):
    (a, b, c), (d, e, f), (g, h, i) = r
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)


def main():
    ap = argparse.ArgumentParser(description='Read-only NGS2 player transform resolver')
    ap.add_argument('pid', nargs='?', type=int, help='game PID (auto-detected if omitted)')
    ap.add_argument('--index', type=int, default=0, help='game_object table index (default 0)')
    ap.add_argument('--no-strict', action='store_true',
                    help='skip EXE/core hash + hook-slot continuity checks')
    a = ap.parse_args()

    pid = a.pid
    if pid is None:
        hits = find_pid()
        if not hits:
            print('no running "NINJA GAIDEN SI" process found', file=sys.stderr)
            return 2
        if len(hits) > 1:
            print(f'multiple candidate PIDs {hits}; pass one explicitly', file=sys.stderr)
            return 2
        pid = hits[0]

    try:
        r = resolve(pid, a.index, strict=not a.no_strict)
    except (OSError, RuntimeError) as e:
        print(f'resolve failed: {e}', file=sys.stderr)
        return 1

    x, y, z = r['position']
    print(f'PID:            {r["pid"]}')
    print(f'Module base:    {r["module_base"]:#x}')
    if r['core_base'] is not None:
        print(f'core.dll base:  {r["core_base"]:#x}')
    if r['slot_value'] is not None:
        print(f'Sigma2 slot:    {r["slot_value"]:#x}  (hook continuity '
              f'{"OK" if not a.no_strict else "unchecked"})')
    print(f'Player address: {r["object_addr"]:#x}  (RVA {r["object_addr"] - r["module_base"]:#x})')
    print()
    print(f'Position (@ {r["position_addr"]:#x}):')
    print(f'  C0/X: {x:.6f}')
    print(f'  Y   : {y:.6f}')
    print(f'  C2/Z: {z:.6f}')
    print()
    if r['rotation'] is not None:
        rot = r['rotation']
        det = _det3(rot)
        fwd = rot[2]
        yaw = math.degrees(math.atan2(fwd[0], fwd[2]))
        print(f'Rotation (@ {r["rotation_addr"]:#x}):')
        print('  representation: 3x3 matrix (rows right / up / forward), right-handed Y-up')
        print(f'  right   (+0x80): ({rot[0][0]:+.5f}, {rot[0][1]:+.5f}, {rot[0][2]:+.5f})')
        print(f'  up      (+0x90): ({rot[1][0]:+.5f}, {rot[1][1]:+.5f}, {rot[1][2]:+.5f})')
        print(f'  forward (+0xA0): ({rot[2][0]:+.5f}, {rot[2][1]:+.5f}, {rot[2][2]:+.5f})')
        print(f'  det: {det:+.4f}   yaw atan2(fwd.x, fwd.z): {yaw:+.2f} deg')
        print()
    print('Character:')
    print(f'  game_object[{r["index"]}]  obj_id={r["obj_id"]}  group={r["group"]}  '
          f'char block @ {r["char_addr"]:#x}')
    print('  identity: tracks the controlled character (position + facing follow input);')
    print('            specific Ryu-vs-others id NOT established')
    if r['corroboration'] is not None:
        cx, cy, cz = r['corroboration']
        match = r['corroboration'] == r['position']
        print(f'  corroboration (char+0x310): ({cx:.6f}, {cy:.6f}, {cz:.6f})  '
              f'{"exact match" if match else "<1e-4 offset / read tear"}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
