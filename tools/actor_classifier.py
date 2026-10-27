#!/usr/bin/env python3
"""Phase 8 read-only actor classifier for Ninja Gaiden Sigma 2.

Observes a bounded set of game_object table entries over N samples and provisionally
classifies each spatial actor as LOCAL_PLAYER / AI_PARTNER_CANDIDATE /
ENEMY_CANDIDATE / OTHER_ACTOR_CANDIDATE / UNKNOWN from its motion behaviour
relative to entry 0 (the RUNTIME VERIFIED local-player resolver).

Reads only: the game_object table (160 x 0x30), each non-empty entry's object
block head, and the per-group character rotation/position. O_RDONLY + pread. No
attach, no writes, no input. Refuses to run if the validated Sigma2 hook callback
is not in the vtable slot.

LOCAL_PLAYER_STABLE protocol (see docs/PLAYER_RESEARCH.md / TEAM_MISSION_RESEARCH.md):
  the local player's XYZ stays within a small tolerance across N consecutive
  samples. Other actors (AI partner, enemies) may keep moving - that does NOT
  invalidate the capture. LOCAL_PLAYER_IDLE != GAME_WORLD_IDLE.
"""
import argparse
import hashlib
import json
import math
import os
import struct
import sys
import time
from datetime import datetime
from pathlib import Path

GAME_HASH = 'a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef'
CORE_HASH = 'ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d'

TABLE_RVA = 0x3195300
TABLE_COUNT = 160
TABLE_STRIDE = 0x30
OBJ_ID_OFF = 0x18
META_OFF = 0x18
GROUP_OFF = 0x1F
POS_OFF = 0x2B0
CHAR_TABLE_RVA = 0x2F78B10
CHAR_STRIDE = 0x1240
CHAR_ROT_OFF = 0x80
CHAR_POS_OFF = 0x310
CHAR_DEAD_OFF = 0x210        # legacy: compared with 4 in the corpse routine
CHAR_HDR0_OFF = 0x00         # byte 0: player = 0x00, AI partner / enemies = 0x04
CHAR_HDR4_OFF = 0x04         # bytes [4:6]: player 0000, AI partner 0000/0909,
#                              enemies 9898 / c2c2 / ffff (observed, 2 missions)
ENEMY_HDR4 = {b'\x98\x98', b'\xc2\xc2', b'\xff\xff'}
OBJ_QUAT_OFF = 0x60         # live playable-character object layout: unit quat here,
OBJ_HDR_OFF = 0x90         # a non-zero short-int header here, ...
OBJ_LIVE_BYTES = 0x1000     # bytes of object block to fetch for the liveness probe
SLOT_RVA = 0x18F9518
CORE_CALLBACK_OFF = 0x16F2

# LOCAL_PLAYER_STABLE defaults, justified from prior captures (true rest =
# bit-identical XYZ; the smallest "not really idle" horizontal drift observed
# was ~0.1 units/s). These are ~10x float32 ULP at play-area magnitudes and far
# below any real locomotion / knockback.
DEF_SAMPLES = 10
DEF_INTERVAL = 0.5
DEF_H_TOL = 0.05
DEF_V_TOL = 0.05


def load_maps(pid):
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts) > 5 else ''))
    return maps


def find_pid():
    hits = []
    for entry in Path('/proc').iterdir():
        if entry.name.isdigit():
            try:
                if (entry / 'comm').read_text().strip() == 'NINJA GAIDEN SI':
                    hits.append(int(entry.name))
            except OSError:
                pass
    return hits


def ptp(vals):
    return max(vals) - min(vals)


def classify(entry, samples, e0_series, h_tol, v_tol, player_group=False):
    """samples: list of (x,y,z) for this entry across the window."""
    xs = [s[0] for s in samples]
    ys = [s[1] for s in samples]
    zs = [s[2] for s in samples]
    h_range = math.hypot(ptp(xs), ptp(zs))
    v_range = ptp(ys)
    disp = math.dist(samples[0], samples[-1])
    # distance to local player (entry 0), averaged
    dists = [math.dist(samples[i], e0_series[i]) for i in range(len(samples))]
    d_mean = sum(dists) / len(dists)
    d_range = ptp(dists)
    near_origin = all(abs(c) < 1e-3 for c in samples[-1])
    same_as_player = d_mean < 0.05 and d_range < 0.05

    stable = h_range <= h_tol and v_range <= v_tol
    moving = h_range > h_tol or v_range > v_tol

    if entry == 0:
        role = 'LOCAL_PLAYER'
    elif near_origin:
        role = 'OTHER_ACTOR_CANDIDATE'      # (0,0,0) -> non-spatial / manager / unplaced
    elif same_as_player:
        role = 'OTHER_ACTOR_CANDIDATE'      # co-located sub-object of the player
    elif not moving and player_group and entry != 0:
        role = 'OTHER_ACTOR_CANDIDATE'      # static player-side marker (spawn / anchor)
    elif moving and d_mean < 25.0:
        role = 'AI_PARTNER_CANDIDATE'       # autonomous character-like motion, near player
    elif moving:
        role = 'ENEMY_CANDIDATE'            # autonomous motion, farther away
    elif not moving and not near_origin:
        role = 'ENEMY_CANDIDATE'            # stationary spatial actor (idle enemy)
    else:
        role = 'UNKNOWN'

    return dict(
        h_range=h_range, v_range=v_range, first_to_last_disp=disp,
        dist_to_player_mean=d_mean, dist_to_player_range=d_range,
        near_origin=near_origin, colocated_with_player=same_as_player,
        stable=stable, moving=moving, role=role,
    )


def run(pid, out, samples_n, interval, h_tol, v_tol, strict):
    maps = load_maps(pid)
    exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
    core = next((m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll')), None)
    if strict:
        if hashlib.sha256(Path(exe[4]).read_bytes()).hexdigest() != GAME_HASH:
            raise RuntimeError('EXE identity mismatch')
        if core is None or hashlib.sha256(Path(core[4]).read_bytes()).hexdigest() != CORE_HASH:
            raise RuntimeError('core.dll identity mismatch / not mapped')
    base = exe[0]
    start_stat = Path(f'/proc/{pid}/stat').read_text()
    fd = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
    total = 0
    try:
        def readable(a, sz):
            e = a + sz
            for lo, hi, perms, *_ in maps:
                if lo <= a < hi and 'r' in perms:
                    a = min(e, hi)
                    if a == e:
                        return True
            return False

        def rd(a, sz):
            nonlocal total
            if not readable(a, sz):
                raise RuntimeError(f'unreadable {a:#x}+{sz:#x}')
            d = os.pread(fd, sz, a)
            if len(d) != sz:
                raise RuntimeError('short read')
            total += sz
            return d

        slot = struct.unpack('<Q', rd(base + SLOT_RVA, 8))[0]
        if core is not None and slot != core[0] + CORE_CALLBACK_OFF and strict:
            raise RuntimeError('validated Sigma2 hook not in slot')

        # one table read to enumerate entries (pointers can move; re-read each sample)
        tbl = rd(base + TABLE_RVA, TABLE_COUNT * TABLE_STRIDE)
        entries = []
        for i in range(TABLE_COUNT):
            rec = tbl[i * TABLE_STRIDE:(i + 1) * TABLE_STRIDE]
            p = struct.unpack_from('<Q', rec, 0)[0]
            if not p:
                continue
            entries.append(dict(index=i, obj=p, obj_rva=p - base,
                                obj_id=rec[OBJ_ID_OFF], group=rec[GROUP_OFF],
                                meta=rec[META_OFF:META_OFF + 8].hex()))

        series = {e['index']: [] for e in entries}
        rot_series = {}
        obj_live = {}          # index -> live-playable-character-layout probe (last sample)
        stamps = []
        for s in range(samples_n):
            stamps.append(datetime.now().astimezone().isoformat())
            tbl = rd(base + TABLE_RVA, TABLE_COUNT * TABLE_STRIDE)
            for e in entries:
                rec = tbl[e['index'] * TABLE_STRIDE:(e['index'] + 1) * TABLE_STRIDE]
                p = struct.unpack_from('<Q', rec, 0)[0]
                pos = (float('nan'),) * 3
                if p and readable(p + POS_OFF, 12):
                    pos = struct.unpack('<3f', rd(p + POS_OFF, 12))
                series[e['index']].append(pos)
                grp = rec[GROUP_OFF]
                cbase = base + CHAR_TABLE_RVA + grp * CHAR_STRIDE
                if grp not in rot_series and readable(cbase + CHAR_ROT_OFF, 0x24):
                    rows = [struct.unpack('<3f', rd(cbase + CHAR_ROT_OFF + 0x10 * r, 12)) for r in range(3)]
                    cpos = struct.unpack('<3f', rd(cbase + CHAR_POS_OFF, 12))
                    dead = rd(cbase + CHAR_DEAD_OFF, 1)
                    hdr0 = rd(cbase + CHAR_HDR0_OFF, 1)
                    hdr4 = rd(cbase + CHAR_HDR4_OFF, 2)
                    rot_series[grp] = dict(rows=rows, char_pos=cpos,
                                           dead_byte=(dead[0] if dead else None),
                                           hdr0=(hdr0[0] if hdr0 else None),
                                           hdr4=(hdr4.hex() if hdr4 else None),
                                           enemy_hdr=(hdr4 in ENEMY_HDR4 if hdr4 else None))
            if s == samples_n - 1:
                # object-block liveness probe on the last sample only
                for e in entries:
                    rec = tbl[e['index'] * TABLE_STRIDE:(e['index'] + 1) * TABLE_STRIDE]
                    p = struct.unpack_from('<Q', rec, 0)[0]
                    if not (p and readable(p + OBJ_HDR_OFF + 16, 1)):
                        continue
                    q = struct.unpack('<4f', rd(p + OBJ_QUAT_OFF, 16))
                    qn = math.sqrt(sum(c * c for c in q))
                    hdr = rd(p + OBJ_HDR_OFF, 16)
                    hdr_nz = any(hdr)
                    obj_live[e['index']] = dict(
                        quat_norm=round(qn, 4),
                        quat_unit=(0.9 < qn < 1.1),
                        quat_zeroed=(qn < 0.1),
                        hdr_nonzero=hdr_nz,
                        # live playable-character layout: unit quat AND a populated header
                        live_character=(0.9 < qn < 1.1 and hdr_nz),
                    )
            if s != samples_n - 1:
                time.sleep(interval)

        end_stat = Path(f'/proc/{pid}/stat').read_text()
        if end_stat.rsplit(')', 1)[1].split()[19] != start_stat.rsplit(')', 1)[1].split()[19]:
            raise RuntimeError('process changed')

        e0_series = series[0]
        actors = []
        for e in entries:
            ss = series[e['index']]
            if any(any(math.isnan(c) for c in p) for p in ss):
                actors.append(dict(**e, position_last=None, classification='UNKNOWN',
                                   note='position unreadable in >=1 sample'))
                continue
            c = classify(e['index'], ss, e0_series, h_tol, v_tol,
                         player_group=(e['group'] == entries[0]['group']))
            grp = e['group']
            yaw = dead_byte = hdr0 = hdr4 = None
            enemy_hdr = False
            if grp in rot_series:
                fwd = rot_series[grp]['rows'][2]
                yaw = math.degrees(math.atan2(fwd[0], fwd[2]))
                dead_byte = rot_series[grp]['dead_byte']
                hdr0 = rot_series[grp]['hdr0']
                hdr4 = rot_series[grp]['hdr4']
                enemy_hdr = bool(rot_series[grp]['enemy_hdr'])
            live = obj_live.get(e['index'], {})
            role = c['role']
            # char+0x210 == 4 -> dead/dying (legacy corpse routine): a "moving"
            # actor that is dead is a settling ragdoll, not the AI partner.
            if dead_byte == 4 and role == 'AI_PARTNER_CANDIDATE':
                role = 'ENEMY_CANDIDATE'
            # AI partner heuristic (cross-validated over 2 Team Missions): a live
            # playable-character object layout (unit quat @ obj+0x60 + populated
            # header @ obj+0x90), group != player group, alive, NOT the enemy
            # char[grp][4:6] signature, near the player. game_object index 4 held
            # the partner in both missions (index 0 = local player).
            partner_like = (e['index'] != 0 and e['group'] != entries[0]['group']
                            and dead_byte != 4 and not enemy_hdr
                            and live.get('live_character') and not c['near_origin']
                            and c['dist_to_player_mean'] < 30.0)
            if partner_like or (e['index'] == 4 and live.get('live_character')
                                and e['group'] != entries[0]['group'] and dead_byte != 4):
                role = 'AI_PARTNER_CANDIDATE'
            elif (e['index'] != 0 and dead_byte != 4 and not c['near_origin']
                  and (not live.get('live_character') or enemy_hdr)
                  and role == 'AI_PARTNER_CANDIDATE'):
                role = 'ENEMY_CANDIDATE'
            actors.append(dict(
                **e, position_first=[round(x, 4) for x in ss[0]],
                position_last=[round(x, 4) for x in ss[-1]],
                movement_h_range=round(c['h_range'], 5),
                movement_v_range=round(c['v_range'], 5),
                first_to_last_disp=round(c['first_to_last_disp'], 4),
                dist_to_player_mean=round(c['dist_to_player_mean'], 3),
                dist_to_player_range=round(c['dist_to_player_range'], 3),
                group_yaw_deg=(round(yaw, 2) if yaw is not None else None),
                char_dead_byte=dead_byte, char_hdr0=hdr0, char_hdr4=hdr4,
                char_enemy_hdr=enemy_hdr,
                obj_quat_norm=live.get('quat_norm'),
                obj_live_character=live.get('live_character'),
                stable=c['stable'], moving=c['moving'],
                near_origin=c['near_origin'], colocated_with_player=c['colocated_with_player'],
                classification=role,
            ))

        lp = next(a for a in actors if a['index'] == 0)
        lp_stable = lp.get('stable', False)
        info = dict(
            tool='actor_classifier', captured=datetime.now().astimezone().isoformat(),
            pid=pid, module_base=hex(base), core_base=hex(core[0]) if core else None,
            slot_ok=(core is not None and slot == core[0] + CORE_CALLBACK_OFF),
            protocol=dict(sample_count=samples_n, sample_interval_s=interval,
                          horizontal_tolerance=h_tol, vertical_tolerance=v_tol),
            LOCAL_PLAYER_STABLE=lp_stable,
            local_player=dict(index=0, obj_rva=hex(lp['obj_rva']), group=lp['group'],
                              obj_id=lp['obj_id'],
                              position=lp.get('position_last'),
                              h_range=lp.get('movement_h_range'),
                              v_range=lp.get('movement_v_range')),
            total_bytes_read=total, sample_times=stamps,
            actors=actors,
        )
        if out:
            outp = Path(out)
            outp.parent.mkdir(parents=True, exist_ok=True)
            outp.write_text(json.dumps(info, indent=2) + '\n')
        return info
    finally:
        os.close(fd)


def compare(paths):
    caps = [json.loads(Path(p).read_text()) for p in paths]
    tags = [Path(p).stem for p in paths]
    by = [{a['index']: a for a in c['actors']} for c in caps]
    idxs = sorted(set().union(*[set(b) for b in by]))
    print('per-entry position across captures ' + ' / '.join(tags))
    print(f"{'idx':>3} {'grp':>3} {'id':>4}  " +
          '  '.join(f'{t[:16]:>26}' for t in tags) + '   moved(x,y,z)')
    for i in idxs:
        cells = []
        first = last = None
        for b in by:
            a = b.get(i)
            if a and a.get('position_last'):
                p = a['position_last']
                cells.append(f'({p[0]:8.2f},{p[1]:6.2f},{p[2]:8.2f})')
                if first is None:
                    first = p
                last = p
            else:
                cells.append(f'{"--":>26}')
        moved = ''
        if first and last:
            d = [last[k] - first[k] for k in range(3)]
            moved = f'({d[0]:+.2f},{d[1]:+.2f},{d[2]:+.2f})  |{math.hypot(d[0], d[2]):.2f}|'
        grp = next((b[i]['group'] for b in by if i in b), '?')
        oid = next((b[i]['obj_id'] for b in by if i in b), '?')
        print(f"{i:3d} {grp:3} {oid:4}  " + '  '.join(cells) + '   ' + moved)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('pid', nargs='?', type=int)
    ap.add_argument('-o', '--out', help='write full JSON here')
    ap.add_argument('--samples', type=int, default=DEF_SAMPLES)
    ap.add_argument('--interval', type=float, default=DEF_INTERVAL)
    ap.add_argument('--h-tol', type=float, default=DEF_H_TOL)
    ap.add_argument('--v-tol', type=float, default=DEF_V_TOL)
    ap.add_argument('--no-strict', action='store_true')
    ap.add_argument('--compare', nargs='+', metavar='JSON',
                    help='compare 2+ saved capture JSONs instead of sampling')
    ap.add_argument('--roles', action='store_true',
                    help='also print a LOCAL_PLAYER / AI_PARTNER / ENEMY roles summary')
    a = ap.parse_args()

    if a.compare:
        compare(a.compare)
        return 0

    pid = a.pid
    if pid is None:
        hits = find_pid()
        if len(hits) != 1:
            print(f'need exactly one game PID, found {hits}', file=sys.stderr)
            return 2
        pid = hits[0]

    try:
        info = run(pid, a.out, a.samples, a.interval, a.h_tol, a.v_tol, not a.no_strict)
    except (OSError, RuntimeError) as e:
        print(f'failed: {e}', file=sys.stderr)
        return 1

    p = info['protocol']
    print(f"PID {info['pid']}  module_base {info['module_base']}  slot_ok {info['slot_ok']}")
    print(f"protocol: {p['sample_count']} samples @ {p['sample_interval_s']}s  "
          f"h_tol {p['horizontal_tolerance']}  v_tol {p['vertical_tolerance']}")
    print(f"LOCAL_PLAYER_STABLE: {info['LOCAL_PLAYER_STABLE']}   "
          f"(entry 0 h_range {info['local_player']['h_range']}  v_range {info['local_player']['v_range']})")
    print()
    hdr = f"{'idx':>3} {'obj_rva':>9} {'grp':>3} {'id':>4} {'pos (x,y,z)':>28} " \
          f"{'h_rng':>7} {'v_rng':>7} {'dispFL':>7} {'dPl':>7} {'yaw':>7} {'dead':>4} {'h0':>4} {'live':>4}  class"
    print(hdr)
    print('-' * len(hdr))
    for act in info['actors']:
        if act['position_last'] is None:
            print(f"{act['index']:3d} {act['obj_rva']:#9x} {act['group']:3d} {act['obj_id']:4d} "
                  f"{'(unreadable)':>28}  {act['classification']}")
            continue
        x, y, z = act['position_last']
        db = act.get('char_dead_byte')
        h0 = act.get('char_hdr0')
        lv = act.get('obj_live_character')
        print(f"{act['index']:3d} {act['obj_rva']:#9x} {act['group']:3d} {act['obj_id']:4d} "
              f"({x:8.2f},{y:7.2f},{z:9.2f}) "
              f"{act['movement_h_range']:7.3f} {act['movement_v_range']:7.3f} "
              f"{act['first_to_last_disp']:7.2f} {act['dist_to_player_mean']:7.2f} "
              f"{str(act['group_yaw_deg']):>7} {('' if db is None else db):>4} {('' if h0 is None else h0):>4} "
              f"{('Y' if lv else ('n' if lv is not None else '')):>4}  "
              f"{act['classification']}")

    if a.roles:
        print()
        print('=== ROLES ===')
        order = {'LOCAL_PLAYER': 0, 'AI_PARTNER_CANDIDATE': 1, 'ENEMY_CANDIDATE': 2,
                 'OTHER_ACTOR_CANDIDATE': 3, 'UNKNOWN': 4}
        for act in sorted(info['actors'], key=lambda x: order.get(x['classification'], 9)):
            if act['classification'] == 'OTHER_ACTOR_CANDIDATE' or act['position_last'] is None:
                continue
            x, y, z = act['position_last']
            rot = act.get('group_yaw_deg')
            h0 = act.get('char_hdr0')
            ctrl = ('local-controlled (char[group]+0x00 == 0x00)' if h0 == 0
                    else 'not local-controlled (char[group]+0x00 == 0x%02x)' % h0 if h0 is not None
                    else 'n/a')
            print(f"{act['classification']}")
            print(f"  entry:  {act['index']}   (enemy slots recycle within a mission; "
                  f"indices 0 and 4 held player/partner across 3 Team Missions + a restart)")
            print(f"  object: {act['obj_rva']:#x} (RVA)   obj_id: {act['obj_id']}   group: {act['group']}")
            print(f"  position (object+0x2B0): ({x:.4f}, {y:.4f}, {z:.4f})")
            print(f"  rotation (char[group]+0x80): yaw {rot} deg" if rot is not None else "  rotation: n/a")
            print(f"  control discriminator candidate: {ctrl}")
            print(f"  dist_to_player: {act['dist_to_player_mean']}   "
                  f"live_char_layout: {act.get('obj_live_character')}   "
                  f"char_dead_byte: {act.get('char_dead_byte')}   "
                  f"char[grp][4:6]: {act.get('char_hdr4')} (enemy_hdr={act.get('char_enemy_hdr')})")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
