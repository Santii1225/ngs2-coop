#!/usr/bin/env python3
"""MVP 2 — first controlled LOCAL_PLAYER position write (world X / object+0x2B0).

Standalone. Independent of core.dll. No hook, no ptrace, no VirtualProtect: one
4-byte pwrite into /proc/<pid>/mem (O_RDWR) at a dynamically-resolved address,
followed by an automatic restore within ~1 s.

FAIL-CLOSED: every gate must pass or nothing is written. Any anomaly after the
write triggers a single restore attempt (same PID / starttime / address only),
then stop. Never a second delta write.

Modes:
  (default)                 dry run: resolve, all gates, LOCAL_PLAYER_STABLE,
                            read + back up the 4 bytes, write pre_write.json.
                            NO memory write.
  --armed --confirm "AUTORIZO WRITE +0.30 X"
                            re-validate everything, then:
                            write X = X0 + 0.30  (one pwrite, 4 bytes)
                            -> immediate readback
                            -> ~0.8 s bounded observation
                            -> automatic restore of the exact original bytes
                            -> restore readback + verify
                            write result.json + restore_x.bin

Only object+0x2B0 is ever written. Never Y (+0x2B4), Z (+0x2B8), rotation, the
visual mirror, the AI partner, or any other actor.
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
OBJ_ID_OFF = 0x18
GROUP_OFF = 0x1F
POS_OFF = 0x2B0                 # world X at +0x2B0, Y at +0x2B4, Z at +0x2B8
CHAR_TABLE_RVA = 0x2F78B10
CHAR_STRIDE = 0x1240
CHAR_POS_OFF = 0x310
CHAR_DEAD_OFF = 0x210
CHAR_HDR0_OFF = 0x00
OBJ_QUAT_OFF = 0x60
OBJ_HDR_OFF = 0x90
SLOT_RVA = 0x18F9518
CORE_CALLBACK_OFF = 0x16F2

DELTA = 0.30
CONFIRM_PHRASE = 'AUTORIZO WRITE +0.30 X'

STABLE_SAMPLES = 10
STABLE_INTERVAL = 0.5
H_TOL = 0.05
V_TOL = 0.05
COORD_ABS_MAX = 1.0e6
CORROB_TOL = 0.5               # object+0x2B0 vs character+0x310

OBS_SAMPLES = 5               # ~0.8 s bounded observation before auto-restore
OBS_INTERVAL = 0.15


class Gate(Exception):
    pass


def now():
    return datetime.now(timezone.utc).astimezone().isoformat()


def find_pids():
    hits = []
    for e in Path('/proc').iterdir():
        if not e.name.isdigit():
            continue
        try:
            if (e / 'comm').read_text().strip() == 'NINJA GAIDEN SI':
                hits.append(int(e.name))
        except OSError:
            pass
    return hits


def read_stat(pid):
    return Path(f'/proc/{pid}/stat').read_text()


def starttime(stat_text):
    return stat_text.rsplit(')', 1)[1].split()[19]


def tracerpid(pid):
    for line in Path(f'/proc/{pid}/status').read_text().splitlines():
        if line.startswith('TracerPid:'):
            return int(line.split()[1])
    raise Gate('no TracerPid line')


def parse_maps(pid):
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts) > 5 else ''))
    return maps


def resolve_and_gate(verbose=True):
    """Run every gate. Return a context dict on success; raise Gate on failure.
    Performs NO memory writes."""
    ctx = {'resolved_at': now()}

    pids = find_pids()
    if len(pids) != 1:
        raise Gate(f'expected exactly one "NINJA GAIDEN SI" process, found {pids}')
    pid = pids[0]
    ctx['pid'] = pid

    if tracerpid(pid) != 0:
        raise Gate('TracerPid != 0 (process is being traced)')

    st0 = read_stat(pid)
    ctx['starttime'] = starttime(st0)

    maps = parse_maps(pid)
    try:
        exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
    except StopIteration:
        raise Gate('game EXE mapping (offset 0) not found')
    core = next((m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll')), None)
    if core is None:
        raise Gate('plugin/core.dll not mapped')

    if hashlib.sha256(Path(exe[4]).read_bytes()).hexdigest() != GAME_HASH:
        raise Gate('EXE sha256 mismatch')
    if hashlib.sha256(Path(core[4]).read_bytes()).hexdigest() != CORE_HASH:
        raise Gate('core.dll sha256 mismatch')

    base = exe[0]
    core_base = core[0]
    ctx['module_base'] = base
    ctx['core_base'] = core_base
    if base == 0:
        raise Gate('module base is 0')

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

        def rd(addr, size):
            if not readable(addr, size):
                raise Gate(f'address not readable: {addr:#x}+{size:#x}')
            d = os.pread(fd, size, addr)
            if len(d) != size:
                raise Gate('short read')
            return d

        # hook continuity
        slot = struct.unpack('<Q', rd(base + SLOT_RVA, 8))[0]
        ctx['slot_value'] = slot
        if slot != core_base + CORE_CALLBACK_OFF:
            raise Gate(f'Sigma2 hook slot mismatch: {slot:#x} != {core_base + CORE_CALLBACK_OFF:#x}')

        # LOCAL_PLAYER resolve: game_object[0]
        rec = rd(base + TABLE_RVA, TABLE_STRIDE)
        obj = struct.unpack_from('<Q', rec, 0)[0]
        obj_id = rec[OBJ_ID_OFF]
        group = rec[GROUP_OFF]
        ctx['index'] = 0
        ctx['object'] = obj
        ctx['object_rva'] = obj - base
        ctx['obj_id'] = obj_id
        ctx['group'] = group
        if not obj:
            raise Gate('game_object[0] pointer is null')
        if not readable(obj + 0x400, 1):
            raise Gate('LOCAL_PLAYER object block not readable for +0x400')

        # structure compatible with a live playable character
        q = struct.unpack('<4f', rd(obj + OBJ_QUAT_OFF, 16))
        qn = math.hypot(math.hypot(q[0], q[1]), math.hypot(q[2], q[3]))
        hdr = rd(obj + OBJ_HDR_OFF, 16)
        ctx['obj_quat_norm'] = qn
        if not (0.9 <= qn <= 1.1):
            raise Gate(f'object+0x60 quaternion norm {qn:.4f} not unit -> not a live character')
        if not any(hdr):
            raise Gate('object+0x90 header all zero -> not a live character')

        # char[group] discriminators
        cbase = base + CHAR_TABLE_RVA + group * CHAR_STRIDE
        hdr0 = rd(cbase + CHAR_HDR0_OFF, 1)[0]
        dead = rd(cbase + CHAR_DEAD_OFF, 1)[0]
        ctx['char_hdr0'] = hdr0
        ctx['char_dead_byte'] = dead
        if group != 0:
            raise Gate(f'LOCAL_PLAYER group expected 0, got {group}')
        if hdr0 != 0x00:
            raise Gate(f'char[group]+0x00 = {hdr0:#x} != 0x00 -> not the local input-controlled player')
        if dead == 4:
            raise Gate('char[group]+0x210 == 4 -> object is dead/dying')

        # NOT the AI partner: AI partner is index != 0 / group != 0 / char[grp]+0x00 == 0x04.
        # We resolved index 0, group 0, char hdr0 0x00 -> this is the local player, not the AI partner.
        ctx['ai_partner_selected'] = False

        # positions
        x, y, z = struct.unpack('<3f', rd(obj + POS_OFF, 12))
        ctx['orig_x'] = x
        ctx['orig_y'] = y
        ctx['orig_z'] = z
        ctx['orig_x_bytes'] = rd(obj + POS_OFF, 4)
        for name, v in (('X', x), ('Y', y), ('Z', z)):
            if not math.isfinite(v):
                raise Gate(f'{name} not finite ({v})')
            if abs(v) >= COORD_ABS_MAX:
                raise Gate(f'|{name}| = {abs(v):.3g} out of range')

        cx, cy, cz = struct.unpack('<3f', rd(cbase + CHAR_POS_OFF, 12))
        ctx['corrob'] = (cx, cy, cz)
        if math.dist((x, y, z), (cx, cy, cz)) > CORROB_TOL:
            raise Gate(f'object pos vs character corroboration disagree by '
                       f'{math.dist((x, y, z), (cx, cy, cz)):.3f} > {CORROB_TOL}')

        # LOCAL_PLAYER_STABLE
        xs, ys, zs = [], [], []
        for i in range(STABLE_SAMPLES):
            sx, sy, sz = struct.unpack('<3f', rd(obj + POS_OFF, 12))
            xs.append(sx); ys.append(sy); zs.append(sz)
            if i != STABLE_SAMPLES - 1:
                time.sleep(STABLE_INTERVAL)
        h_range = math.hypot(max(xs) - min(xs), max(zs) - min(zs))
        v_range = max(ys) - min(ys)
        fl_h = math.hypot(xs[-1] - xs[0], zs[-1] - zs[0])
        fl_v = abs(ys[-1] - ys[0])
        ctx['stable'] = dict(h_range=h_range, v_range=v_range, first_last_h=fl_h, first_last_v=fl_v,
                             x_first=xs[0], x_last=xs[-1])
        if h_range > H_TOL or v_range > V_TOL or fl_h > H_TOL or fl_v > V_TOL:
            raise Gate(f'UNSTABLE_LOCAL_PLAYER: h_range={h_range:.4f} v_range={v_range:.4f} '
                       f'first_last_h={fl_h:.4f} first_last_v={fl_v:.4f} (tol {H_TOL}/{V_TOL})')

        # end-of-checks process identity
        if starttime(read_stat(pid)) != ctx['starttime']:
            raise Gate('process starttime changed during gate checks')

        ctx['ok'] = True
        return ctx
    finally:
        os.close(fd)


def dry_run(evidence_dir):
    ctx = resolve_and_gate()
    d = Path(evidence_dir)
    d.mkdir(parents=True, exist_ok=False)
    (d / 'original_x.bin').write_bytes(ctx['orig_x_bytes'])

    # verify backup == memory (fresh read, read-only)
    fd = os.open(f"/proc/{ctx['pid']}/mem", os.O_RDONLY)
    try:
        fresh = os.pread(fd, 4, ctx['object'] + POS_OFF)
    finally:
        os.close(fd)
    backup_ok = fresh == ctx['orig_x_bytes']

    pre = dict(
        stage='pre_write', captured=now(),
        pid=ctx['pid'], starttime=ctx['starttime'],
        module_base=hex(ctx['module_base']), core_base=hex(ctx['core_base']),
        slot_value=hex(ctx['slot_value']),
        index=ctx['index'], object=hex(ctx['object']), object_rva=hex(ctx['object_rva']),
        obj_id=ctx['obj_id'], group=ctx['group'],
        position_address=hex(ctx['object'] + POS_OFF),
        original_x=ctx['orig_x'], original_y=ctx['orig_y'], original_z=ctx['orig_z'],
        original_x_bytes=ctx['orig_x_bytes'].hex(),
        backup_matches_memory=backup_ok,
        char_hdr0=ctx['char_hdr0'], char_dead_byte=ctx['char_dead_byte'],
        obj_quat_norm=round(ctx['obj_quat_norm'], 5),
        corroboration=list(ctx['corrob']),
        stable=ctx['stable'],
        ai_partner_selected=ctx['ai_partner_selected'],
        proposed_x=ctx['orig_x'] + DELTA, delta=DELTA,
        target='object + 0x2B0 (world X)',
        gates='ALL PASS',
    )
    (d / 'pre_write.json').write_text(json.dumps(pre, indent=2) + '\n')
    if not backup_ok:
        raise Gate('backup 4 bytes do not match memory on re-read')

    print('=== MVP2 WRITE ARMED (dry run) ===')
    print(f"PID:                {ctx['pid']}   starttime {ctx['starttime']}")
    print(f"LOCAL_PLAYER object: {ctx['object']:#x}  (RVA {ctx['object_rva']:#x})  index 0  group {ctx['group']}  obj_id {ctx['obj_id']}")
    print(f"Position address:    {ctx['object'] + POS_OFF:#x}")
    print(f"Original XYZ:         ({ctx['orig_x']:.6f}, {ctx['orig_y']:.6f}, {ctx['orig_z']:.6f})")
    print(f"Target:              object + 0x2B0")
    print(f"Original X:           {ctx['orig_x']:.6f}   bytes {ctx['orig_x_bytes'].hex()}")
    print(f"Proposed X:           {ctx['orig_x'] + DELTA:.6f}  (original + {DELTA})")
    print(f"Delta:               +{DELTA}")
    print(f"Stable gate:         PASS  (h_range {ctx['stable']['h_range']:.4f}, v_range {ctx['stable']['v_range']:.4f})")
    print(f"char[group]+0x00:    {ctx['char_hdr0']:#04x}  (0x00 = local input-controlled player)")
    print(f"AI Partner target:   NO")
    print(f"Rollback bytes saved: YES  ({d / 'original_x.bin'})  matches memory: {backup_ok}")
    print(f"Evidence dir:        {d}")
    return 0


def armed_run(evidence_dir, confirm):
    if confirm != CONFIRM_PHRASE:
        print(f'refused: --confirm must be exactly "{CONFIRM_PHRASE}"', file=sys.stderr)
        return 2

    d = Path(evidence_dir)
    if not (d / 'pre_write.json').exists():
        print(f'refused: no pre_write.json in {d} — run the dry run first', file=sys.stderr)
        return 2
    pre = json.loads((d / 'pre_write.json').read_text())
    saved_bytes = bytes.fromhex(pre['original_x_bytes'])

    # RE-VALIDATE everything from scratch
    ctx = resolve_and_gate()

    # cross-checks against the dry run
    if ctx['pid'] != pre['pid'] or ctx['starttime'] != pre['starttime']:
        raise Gate(f"process changed since dry run (pid {pre['pid']}/{ctx['pid']}, "
                   f"starttime {pre['starttime']}/{ctx['starttime']})")
    if ctx['object'] != int(pre['object'], 16):
        raise Gate(f"LOCAL_PLAYER object changed: {pre['object']} -> {hex(ctx['object'])}")
    if abs(ctx['orig_x'] - pre['original_x']) > H_TOL:
        raise Gate(f"current X {ctx['orig_x']:.5f} drifted from dry-run X {pre['original_x']:.5f} "
                   f"by > {H_TOL} -> not stable")
    if ctx['char_hdr0'] != 0x00 or ctx['group'] != 0 or ctx['ai_partner_selected']:
        raise Gate('local-player identity check failed on re-validation')

    pid = ctx['pid']
    obj = ctx['object']
    addr = obj + POS_OFF
    x0 = ctx['orig_x']
    cur_bytes = ctx['orig_x_bytes']              # freshest pre-write bytes -> restore target
    x_new = x0 + DELTA
    new_bytes = struct.pack('<f', x_new)

    log = [dict(t=now(), ev='revalidated', pid=pid, starttime=ctx['starttime'],
                object=hex(obj), addr=hex(addr), x0=x0,
                cur_bytes=cur_bytes.hex(), dryrun_bytes=saved_bytes.hex(),
                cur_matches_dryrun=(cur_bytes == saved_bytes))]

    result = dict(stage='armed', evidence_dir=str(d), confirm=confirm,
                  pid=pid, starttime=ctx['starttime'], module_base=hex(ctx['module_base']),
                  object=hex(obj), position_address=hex(addr),
                  original_x=x0, original_y=ctx['orig_y'], original_z=ctx['orig_z'],
                  original_x_bytes=cur_bytes.hex(),
                  requested_x=x_new, requested_x_bytes=new_bytes.hex(), delta=DELTA,
                  stable_pre=ctx['stable'])

    fd = os.open(f'/proc/{pid}/mem', os.O_RDWR)
    wrote = False
    try:
        # last-moment identity re-check right before the syscall
        if starttime(read_stat(pid)) != ctx['starttime']:
            raise Gate('starttime changed immediately before write')
        pre_bytes = os.pread(fd, 4, addr)
        if pre_bytes != cur_bytes:
            raise Gate('4 bytes at target changed between gate read and write — aborting')

        t_write = now()
        n = os.pwrite(fd, new_bytes, addr)
        wrote = True
        if n != 4:
            raise Gate(f'short pwrite ({n} of 4) — attempting restore')
        result['write_timestamp'] = t_write
        log.append(dict(t=t_write, ev='write', addr=hex(addr), bytes=new_bytes.hex(), n=n))

        # immediate readback
        rb0 = os.pread(fd, 4, addr)
        rbx0 = struct.unpack('<f', rb0)[0]
        result['immediate_readback_x'] = rbx0
        result['immediate_readback_bytes'] = rb0.hex()
        result['immediate_diff_from_requested'] = rbx0 - x_new
        log.append(dict(t=now(), ev='readback_immediate', x=rbx0, bytes=rb0.hex()))

        # bounded observation (~0.8 s), read-only
        obs = []
        anomaly = None
        for i in range(OBS_SAMPLES):
            time.sleep(OBS_INTERVAL)
            try:
                b = os.pread(fd, 4, addr)
                tri = struct.unpack('<3f', os.pread(fd, 12, addr))
            except OSError as e:
                anomaly = f'read failed during observation: {e}'
                break
            vx, vy, vz = tri
            obs.append(dict(t=now(), x=vx, y=vy, z=vz, bytes=b.hex()))
            if not math.isfinite(vx) or abs(vx) >= COORD_ABS_MAX:
                anomaly = f'X became {vx} during observation'
                break
            if abs(vy - ctx['orig_y']) > 0.1:
                anomaly = f'Y moved {vy - ctx["orig_y"]:+.3f} during observation (vertical side-effect)'
                break
        result['observation'] = obs
        result['anomaly'] = anomaly

        # classify engine response from observation
        xs = [o['x'] for o in obs] or [rbx0]
        held = all(abs(x - x_new) < 0.02 for x in ([rbx0] + xs))
        reverted = abs(xs[-1] - x0) < 0.05 and abs(rbx0 - x_new) < 0.02
        result['engine_response'] = (
            'HELD at requested value' if held else
            'REVERTED toward original (engine overwrote)' if reverted else
            'DRIFTED (see observation)' if abs(xs[-1] - x_new) > 0.02 else
            'INDETERMINATE')

        if starttime(read_stat(pid)) != ctx['starttime']:
            anomaly = (anomaly or '') + '; starttime changed after write'
            result['anomaly'] = anomaly

    except BaseException as e:
        result['error'] = f'{type(e).__name__}: {e}'
        log.append(dict(t=now(), ev='error', detail=result['error']))
    finally:
        # AUTOMATIC RESTORE — single attempt, only if identity still matches
        restore = dict(attempted=False)
        try:
            same = (find_pids() == [pid]
                    and starttime(read_stat(pid)) == ctx['starttime'])
            if wrote and same:
                restore['attempted'] = True
                tr = now()
                n = os.pwrite(fd, cur_bytes, addr)
                restore['n'] = n
                restore['timestamp'] = tr
                rb = os.pread(fd, 4, addr)
                restore['readback_bytes'] = rb.hex()
                restore['readback_x'] = struct.unpack('<f', rb)[0]
                # exact bytes match, or value within tolerance if the game is updating
                restore['exact'] = (rb == cur_bytes)
                restore['within_tol'] = abs(restore['readback_x'] - x0) <= H_TOL
                restore['result'] = ('EXACT' if restore['exact']
                                     else 'WITHIN_TOL' if restore['within_tol']
                                     else 'MISMATCH')
                log.append(dict(t=tr, ev='restore', bytes=cur_bytes.hex(), n=n,
                                readback=rb.hex(), result=restore['result']))
            elif wrote and not same:
                restore['result'] = 'SKIPPED_IDENTITY_CHANGED'
                log.append(dict(t=now(), ev='restore_skipped', reason='pid/starttime changed'))
            else:
                restore['result'] = 'NOT_NEEDED_NO_WRITE'
        except BaseException as e:
            restore['result'] = f'RESTORE_FAILED: {type(e).__name__}: {e}'
            log.append(dict(t=now(), ev='restore_failed', detail=restore['result']))
        result['restoration'] = restore
        try:
            os.close(fd)
        except OSError:
            pass

    # process status
    result['process_alive'] = (find_pids() == [pid])
    try:
        result['process_starttime_now'] = starttime(read_stat(pid))
        result['process_starttime_stable'] = result['process_starttime_now'] == ctx['starttime']
    except OSError:
        result['process_starttime_stable'] = False
    result['ai_partner_affected'] = False
    result['log'] = log
    result['finished'] = now()

    (d / 'restore_x.bin').write_bytes(cur_bytes)
    (d / 'result.json').write_text(json.dumps(result, indent=2) + '\n')

    # verdict
    r = result.get('restoration', {}).get('result', '')
    verdict = 'FAIL'
    if 'error' in result and not wrote:
        verdict = 'FAIL (aborted before write: %s)' % result['error']
    elif result.get('anomaly') or not result['process_alive'] or not result.get('process_starttime_stable'):
        verdict = 'FAIL (anomaly / process unstable)'
    elif r in ('EXACT', 'WITHIN_TOL'):
        if result.get('engine_response', '').startswith('HELD'):
            verdict = 'PASS (write held, restored)'
        elif 'REVERTED' in result.get('engine_response', ''):
            verdict = 'PARTIAL (engine overwrote X quickly, restored cleanly)'
        else:
            verdict = 'PARTIAL (engine response %s, restored)' % result.get('engine_response')
    else:
        verdict = 'FAIL (restore %s)' % r
    result['verdict'] = verdict
    (d / 'result.json').write_text(json.dumps(result, indent=2) + '\n')

    print('=== MVP2 ARMED RUN COMPLETE ===')
    print(f"write:               X {x0:.6f} -> requested {x_new:.6f}  (bytes {cur_bytes.hex()} -> {new_bytes.hex()})")
    print(f"immediate readback:  {result.get('immediate_readback_x')}")
    print(f"engine response:     {result.get('engine_response')}")
    print(f"observation samples: {[round(o['x'],4) for o in result.get('observation', [])]}")
    print(f"anomaly:             {result.get('anomaly')}")
    print(f"restoration:         {restore.get('result')}  readback {restore.get('readback_x')}")
    print(f"process alive:       {result['process_alive']}   starttime stable: {result.get('process_starttime_stable')}")
    print(f"AI partner affected: NO")
    print(f"VERDICT:             {verdict}")
    print(f"evidence:            {d / 'result.json'}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--armed', action='store_true', help='perform the single write + auto restore')
    ap.add_argument('--confirm', default='', help=f'must be exactly "{CONFIRM_PHRASE}" for --armed')
    ap.add_argument('--evidence-dir', help='evidence dir (dry run creates it; armed run reuses it)')
    a = ap.parse_args()

    try:
        if a.armed:
            if not a.evidence_dir:
                print('refused: --armed requires --evidence-dir from the dry run', file=sys.stderr)
                return 2
            return armed_run(a.evidence_dir, a.confirm)
        else:
            ed = a.evidence_dir or ('docs/research/player/MVP2_WRITE_TEST_' +
                                    datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
            print(f'evidence-dir: {ed}')
            return dry_run(ed)
    except Gate as e:
        print(f'GATE FAILED — NO WRITE: {e}', file=sys.stderr)
        return 1
    except (OSError, RuntimeError) as e:
        print(f'ERROR — NO WRITE: {type(e).__name__}: {e}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
