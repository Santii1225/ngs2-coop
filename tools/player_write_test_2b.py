#!/usr/bin/env python3
"""MVP 2B — controlled write to the CANONICAL player position (object + 0x4B80).

Phase 12 established object+0x4B80 = CANONICAL_POSITION_RUNTIME_VERIFIED: it is
integrated by the locomotion writer W1 (0x141BB90: pos += delta) and re-committed
by the transform writer W2 (0x14208DD); object+0x2B0 (the observable render copy)
is re-derived from it every frame. W2's matrix source (character[group]+0x1010) is
itself a per-frame copy of object+0x4B80 (0xF33D97), so an external write can be
reverted by W2 for at most ~1 frame, not permanently (unlike object+0x2B0 in
MVP 2). See docs/CANONICAL_WRITER_TRACE.md.

This tool: one 4-byte pwrite of X = X0 + 0.30 into object+0x4B80, a bounded ~3 s
observation of object+0x4B80 / object+0x2B0 / object+0x4BC0 / Y, then an automatic
exact restore. Standalone: no core.dll, no hook, no ptrace, no VirtualProtect.

FAIL-CLOSED: every gate must pass or nothing is written. Extra guards vs MVP 2:
  - object+0x4BC0 (velocity) magnitude < 0.05 on every stability sample
  - object+0x4B80 == object+0x2B0 to < 1e-3 (chain coherence)

Only object+0x4B80 (world X, 4 bytes) is ever written. Never Y (+0x4B84),
Z (+0x4B88), velocity (+0x4BC0), capsule (+0x4BD0), object+0x2B0, rotation, the
AI partner, or any other actor.

Modes:
  (default)   dry run: resolve, all gates, LOCAL_PLAYER_STABLE + velocity gate,
              read + back up the 4 bytes -> pre_write.json. NO memory write.
  --armed --confirm "AUTORIZO MVP 2B: WRITE +0.30 X en object+0x4B80"
              re-validate everything, one pwrite, immediate readback, ~3 s
              bounded observation, automatic exact restore, verify.
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
CANON_OFF = 0x4B80             # CANONICAL world X at +0x4B80, Y +0x4B84, Z +0x4B88
VEL_OFF = 0x4BC0              # velocity / movement vector
CAPS_OFF = 0x4BD0             # collision capsule center
OBS_OFF = 0x2B0              # observable render copy (read-only, for propagation check)
CHAR_TABLE_RVA = 0x2F78B10
CHAR_STRIDE = 0x1240
CHAR_POS_OFF = 0x310
CHAR_DEAD_OFF = 0x210
CHAR_HDR0_OFF = 0x00
OBJ_QUAT_OFF = 0x60
OBJ_HDR_OFF = 0x90
SLOT_RVA = 0x18F9518
CORE_CALLBACK_OFF = 0x16F2

DELTA = 0.30                   # default; override with --delta
CONFIRM_PREFIX = 'AUTORIZO MVP 2B: WRITE +'
CONFIRM_SUFFIX = ' X en object+0x4B80'


def confirm_matches(confirm, delta):
    """--confirm must be 'AUTORIZO MVP 2B: WRITE +<delta> X en object+0x4B80'
    where <delta> parses to the same float as --delta."""
    if not (confirm.startswith(CONFIRM_PREFIX) and confirm.endswith(CONFIRM_SUFFIX)):
        return False
    mid = confirm[len(CONFIRM_PREFIX):-len(CONFIRM_SUFFIX)].strip()
    try:
        return abs(float(mid) - delta) < 1e-6
    except ValueError:
        return False

STABLE_SAMPLES = 10
STABLE_INTERVAL = 0.5
H_TOL = 0.05
V_TOL = 0.05
VEL_TOL = 0.05                # per-component |object+0x4BC0|
CHAIN_TOL = 1.0e-3           # object+0x4B80 vs object+0x2B0
COORD_ABS_MAX = 1.0e6
CORROB_TOL = 0.5

OBS_SAMPLES = 6              # ~3 s bounded observation before auto-restore
OBS_INTERVAL = 0.5
MAX_WINDOW_S = 30.0


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


def resolve_and_gate():
    """Every gate. Return a context dict on success; raise Gate on failure. No writes."""
    ctx = {'resolved_at': now()}

    pids = find_pids()
    if len(pids) != 1:
        raise Gate(f'expected exactly one "NINJA GAIDEN SI" process, found {pids}')
    pid = pids[0]
    ctx['pid'] = pid
    if tracerpid(pid) != 0:
        raise Gate('TracerPid != 0 (process is being traced)')
    ctx['starttime'] = starttime(read_stat(pid))

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

        slot = struct.unpack('<Q', rd(base + SLOT_RVA, 8))[0]
        ctx['slot_value'] = slot
        if slot != core_base + CORE_CALLBACK_OFF:
            raise Gate(f'Sigma2 hook slot mismatch: {slot:#x} != {core_base + CORE_CALLBACK_OFF:#x}')

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
        if not readable(obj + CANON_OFF + 0x100, 1):
            raise Gate('LOCAL_PLAYER object block not readable through +0x4C80')

        q = struct.unpack('<4f', rd(obj + OBJ_QUAT_OFF, 16))
        qn = math.hypot(math.hypot(q[0], q[1]), math.hypot(q[2], q[3]))
        hdr = rd(obj + OBJ_HDR_OFF, 16)
        ctx['obj_quat_norm'] = qn
        if not (0.9 <= qn <= 1.1):
            raise Gate(f'object+0x60 quaternion norm {qn:.4f} not unit -> not a live character')
        if not any(hdr):
            raise Gate('object+0x90 header all zero -> not a live character')

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
        ctx['ai_partner_selected'] = False

        # canonical position + chain coherence with the observable copy
        x, y, z = struct.unpack('<3f', rd(obj + CANON_OFF, 12))
        ox, oy, oz = struct.unpack('<3f', rd(obj + OBS_OFF, 12))
        ctx['orig_x'] = x
        ctx['orig_y'] = y
        ctx['orig_z'] = z
        ctx['orig_x_bytes'] = rd(obj + CANON_OFF, 4)
        ctx['obs_xyz'] = (ox, oy, oz)
        for name, v in (('X', x), ('Y', y), ('Z', z)):
            if not math.isfinite(v):
                raise Gate(f'{name} not finite ({v})')
            if abs(v) >= COORD_ABS_MAX:
                raise Gate(f'|{name}| = {abs(v):.3g} out of range')
        chain_d = math.dist((x, y, z), (ox, oy, oz))
        ctx['chain_dist'] = chain_d
        if chain_d > CHAIN_TOL:
            raise Gate(f'object+0x4B80 vs object+0x2B0 disagree by {chain_d:.5f} > {CHAIN_TOL} '
                       f'-> chain not coherent, refuse')

        cx, cy, cz = struct.unpack('<3f', rd(cbase + CHAR_POS_OFF, 12))
        ctx['corrob'] = (cx, cy, cz)
        if math.dist((x, y, z), (cx, cy, cz)) > CORROB_TOL:
            raise Gate(f'canonical pos vs character corroboration disagree by '
                       f'{math.dist((x, y, z), (cx, cy, cz)):.3f} > {CORROB_TOL}')

        # LOCAL_PLAYER_STABLE + velocity gate on the same samples
        xs, ys, zs, vmax = [], [], [], 0.0
        for i in range(STABLE_SAMPLES):
            sx, sy, sz = struct.unpack('<3f', rd(obj + CANON_OFF, 12))
            vx, vy, vz = struct.unpack('<3f', rd(obj + VEL_OFF, 12))
            xs.append(sx); ys.append(sy); zs.append(sz)
            vmax = max(vmax, abs(vx), abs(vy), abs(vz))
            if i != STABLE_SAMPLES - 1:
                time.sleep(STABLE_INTERVAL)
        h_range = math.hypot(max(xs) - min(xs), max(zs) - min(zs))
        v_range = max(ys) - min(ys)
        fl_h = math.hypot(xs[-1] - xs[0], zs[-1] - zs[0])
        fl_v = abs(ys[-1] - ys[0])
        ctx['stable'] = dict(h_range=h_range, v_range=v_range, first_last_h=fl_h,
                             first_last_v=fl_v, vel_max=vmax, x_first=xs[0], x_last=xs[-1])
        if h_range > H_TOL or v_range > V_TOL or fl_h > H_TOL or fl_v > V_TOL:
            raise Gate(f'UNSTABLE_LOCAL_PLAYER: h_range={h_range:.4f} v_range={v_range:.4f} '
                       f'first_last_h={fl_h:.4f} first_last_v={fl_v:.4f} (tol {H_TOL}/{V_TOL})')
        if vmax > VEL_TOL:
            raise Gate(f'velocity object+0x4BC0 max |comp| {vmax:.4f} > {VEL_TOL} -> player still moving')

        if starttime(read_stat(pid)) != ctx['starttime']:
            raise Gate('process starttime changed during gate checks')

        ctx['ok'] = True
        return ctx
    finally:
        os.close(fd)


def _fmt_stable(s):
    return (f"h_range {s['h_range']:.4f}  v_range {s['v_range']:.4f}  "
            f"vel_max {s['vel_max']:.4f}")


def dry_run(evidence_dir, delta):
    ctx = resolve_and_gate()
    d = Path(evidence_dir)
    d.mkdir(parents=True, exist_ok=False)
    (d / 'original_x.bin').write_bytes(ctx['orig_x_bytes'])

    fd = os.open(f"/proc/{ctx['pid']}/mem", os.O_RDONLY)
    try:
        fresh = os.pread(fd, 4, ctx['object'] + CANON_OFF)
    finally:
        os.close(fd)
    backup_ok = fresh == ctx['orig_x_bytes']

    pre = dict(
        stage='pre_write', mvp='2B', captured=now(),
        pid=ctx['pid'], starttime=ctx['starttime'],
        module_base=hex(ctx['module_base']), core_base=hex(ctx['core_base']),
        slot_value=hex(ctx['slot_value']),
        index=ctx['index'], object=hex(ctx['object']), object_rva=hex(ctx['object_rva']),
        obj_id=ctx['obj_id'], group=ctx['group'],
        target='object + 0x4B80 (CANONICAL world X)',
        canonical_address=hex(ctx['object'] + CANON_OFF),
        observable_address=hex(ctx['object'] + OBS_OFF),
        original_x=ctx['orig_x'], original_y=ctx['orig_y'], original_z=ctx['orig_z'],
        original_x_bytes=ctx['orig_x_bytes'].hex(),
        observable_xyz=list(ctx['obs_xyz']),
        chain_dist_4B80_vs_2B0=ctx['chain_dist'],
        backup_matches_memory=backup_ok,
        char_hdr0=ctx['char_hdr0'], char_dead_byte=ctx['char_dead_byte'],
        obj_quat_norm=round(ctx['obj_quat_norm'], 5),
        corroboration=list(ctx['corrob']),
        stable=ctx['stable'],
        ai_partner_selected=ctx['ai_partner_selected'],
        proposed_x=ctx['orig_x'] + delta, delta=delta,
        gates='ALL PASS',
    )
    (d / 'pre_write.json').write_text(json.dumps(pre, indent=2) + '\n')
    if not backup_ok:
        raise Gate('backup 4 bytes do not match memory on re-read')

    print('=== MVP 2B WRITE ARMED (dry run) ===')
    print(f"PID:                 {ctx['pid']}   starttime {ctx['starttime']}")
    print(f"LOCAL_PLAYER object:  {ctx['object']:#x}  (RVA {ctx['object_rva']:#x})  index 0  group {ctx['group']}  obj_id {ctx['obj_id']}")
    print(f"Target:              object + 0x4B80 (CANONICAL world X)")
    print(f"Canonical address:   {ctx['object'] + CANON_OFF:#x}")
    print(f"Original X (canon):   {ctx['orig_x']:.6f}   bytes {ctx['orig_x_bytes'].hex()}")
    print(f"Original XYZ:         ({ctx['orig_x']:.6f}, {ctx['orig_y']:.6f}, {ctx['orig_z']:.6f})")
    print(f"Observable +0x2B0:    ({ctx['obs_xyz'][0]:.6f}, {ctx['obs_xyz'][1]:.6f}, {ctx['obs_xyz'][2]:.6f})   chain dist {ctx['chain_dist']:.2e}")
    print(f"Proposed X:           {ctx['orig_x'] + delta:.6f}  (original + {delta})")
    print(f"Stable gate:         PASS  ({_fmt_stable(ctx['stable'])})")
    print(f"Velocity gate:       PASS  (|+0x4BC0| max {ctx['stable']['vel_max']:.4f} < {VEL_TOL})")
    print(f"char[group]+0x00:    {ctx['char_hdr0']:#04x}  (0x00 = local input-controlled player)")
    print(f"AI Partner target:   NO")
    print(f"Rollback bytes saved: YES  ({d / 'original_x.bin'})  matches memory: {backup_ok}")
    print(f"Evidence dir:        {d}")
    return 0


def armed_run(evidence_dir, confirm, delta):
    if not confirm_matches(confirm, delta):
        want = f'{CONFIRM_PREFIX}{delta:g} X en object+0x4B80'
        print(f'refused: --confirm must be "{want}" (matching --delta {delta})', file=sys.stderr)
        return 2
    if abs(delta) > 25.0:
        print(f'refused: |delta| {delta} > 25 u -- too large for a bounded reversible test', file=sys.stderr)
        return 2

    d = Path(evidence_dir)
    if not (d / 'pre_write.json').exists():
        print(f'refused: no pre_write.json in {d} — run the dry run first', file=sys.stderr)
        return 2
    pre = json.loads((d / 'pre_write.json').read_text())
    saved_bytes = bytes.fromhex(pre['original_x_bytes'])

    ctx = resolve_and_gate()

    if ctx['pid'] != pre['pid'] or ctx['starttime'] != pre['starttime']:
        raise Gate(f"process changed since dry run (pid {pre['pid']}/{ctx['pid']}, "
                   f"starttime {pre['starttime']}/{ctx['starttime']})")
    if ctx['object'] != int(pre['object'], 16):
        raise Gate(f"LOCAL_PLAYER object changed: {pre['object']} -> {hex(ctx['object'])}")
    if abs(ctx['orig_x'] - pre['original_x']) > H_TOL:
        raise Gate(f"current X {ctx['orig_x']:.5f} drifted from dry-run X {pre['original_x']:.5f} > {H_TOL}")
    if ctx['char_hdr0'] != 0x00 or ctx['group'] != 0 or ctx['ai_partner_selected']:
        raise Gate('local-player identity check failed on re-validation')
    if ctx['chain_dist'] > CHAIN_TOL:
        raise Gate('object+0x4B80 vs object+0x2B0 chain not coherent on re-validation')
    if ctx['stable']['vel_max'] > VEL_TOL:
        raise Gate('velocity gate failed on re-validation')

    pid = ctx['pid']
    obj = ctx['object']
    addr = obj + CANON_OFF
    obs_addr = obj + OBS_OFF
    vel_addr = obj + VEL_OFF
    x0 = ctx['orig_x']
    cur_bytes = ctx['orig_x_bytes']
    x_new = x0 + delta
    new_bytes = struct.pack('<f', x_new)

    log = [dict(t=now(), ev='revalidated', pid=pid, starttime=ctx['starttime'],
                object=hex(obj), addr=hex(addr), x0=x0,
                cur_bytes=cur_bytes.hex(), dryrun_bytes=saved_bytes.hex(),
                cur_matches_dryrun=(cur_bytes == saved_bytes))]

    result = dict(stage='armed', mvp='2B', evidence_dir=str(d), confirm=confirm,
                  pid=pid, starttime=ctx['starttime'], module_base=hex(ctx['module_base']),
                  object=hex(obj), canonical_address=hex(addr), observable_address=hex(obs_addr),
                  original_x=x0, original_y=ctx['orig_y'], original_z=ctx['orig_z'],
                  original_x_bytes=cur_bytes.hex(),
                  requested_x=x_new, requested_x_bytes=new_bytes.hex(), delta=delta,
                  stable_pre=ctx['stable'], chain_dist_pre=ctx['chain_dist'])

    fd = os.open(f'/proc/{pid}/mem', os.O_RDWR)
    wrote = False
    t0 = time.monotonic()
    try:
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

        rb0 = os.pread(fd, 4, addr)
        rbx0 = struct.unpack('<f', rb0)[0]
        obs0 = struct.unpack('<3f', os.pread(fd, 12, obs_addr))
        result['immediate_readback_x'] = rbx0
        result['immediate_readback_bytes'] = rb0.hex()
        result['immediate_obs_2B0'] = list(obs0)
        result['immediate_diff_from_requested'] = rbx0 - x_new
        log.append(dict(t=now(), ev='readback_immediate', canon_x=rbx0, canon_bytes=rb0.hex(),
                        obs_2B0=list(obs0)))

        obs = []
        anomaly = None
        for i in range(OBS_SAMPLES):
            time.sleep(OBS_INTERVAL)
            if time.monotonic() - t0 > MAX_WINDOW_S:
                anomaly = 'observation exceeded MAX_WINDOW_S'
                break
            try:
                cb = os.pread(fd, 4, addr)
                ctri = struct.unpack('<3f', os.pread(fd, 12, addr))
                otri = struct.unpack('<3f', os.pread(fd, 12, obs_addr))
                vtri = struct.unpack('<3f', os.pread(fd, 12, vel_addr))
            except OSError as e:
                anomaly = f'read failed during observation: {e}'
                break
            cxv, cyv, czv = ctri
            obs.append(dict(t=now(), canon=[cxv, cyv, czv], obs_2B0=list(otri),
                            vel_4BC0=list(vtri), canon_bytes=cb.hex()))
            if not math.isfinite(cxv) or abs(cxv) >= COORD_ABS_MAX:
                anomaly = f'canonical X became {cxv} during observation'
                break
            if abs(cyv - ctx['orig_y']) > 0.1:
                anomaly = f'canonical Y moved {cyv - ctx["orig_y"]:+.3f} (vertical side-effect)'
                break
        result['observation'] = obs
        result['anomaly'] = anomaly

        # classify: did the canonical write hold?  did +0x2B0 converge to it?
        canon_xs = [o['canon'][0] for o in obs] or [rbx0]
        obs_xs = [o['obs_2B0'][0] for o in obs] or [obs0[0]]
        canon_held = all(abs(v - x_new) < 0.02 for v in ([rbx0] + canon_xs))
        canon_reverted = abs(canon_xs[-1] - x0) < 0.03
        obs_converged = abs(obs_xs[-1] - x_new) < 0.05
        obs_stale = abs(obs_xs[-1] - x0) < 0.03
        result['canon_held'] = canon_held
        result['canon_reverted'] = canon_reverted
        result['obs_converged'] = obs_converged
        if canon_held and obs_converged:
            eng = 'CANONICAL CONFIRMED: +0x4B80 held AND +0x2B0 converged to the new value'
        elif canon_held and obs_stale:
            eng = 'HELD, NO PROPAGATION: +0x4B80 held but +0x2B0 did not follow'
        elif canon_reverted:
            eng = 'REVERTED: engine overwrote +0x4B80 back toward original'
        else:
            eng = 'INDETERMINATE (see observation)'
        result['engine_response'] = eng

        if starttime(read_stat(pid)) != ctx['starttime']:
            result['anomaly'] = (result.get('anomaly') or '') + '; starttime changed after write'

    except BaseException as e:
        result['error'] = f'{type(e).__name__}: {e}'
        log.append(dict(t=now(), ev='error', detail=result['error']))
    finally:
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
                restore['exact'] = (rb == cur_bytes)
                restore['within_tol'] = abs(restore['readback_x'] - x0) <= H_TOL
                restore['result'] = ('EXACT' if restore['exact']
                                     else 'WITHIN_TOL' if restore['within_tol']
                                     else 'MISMATCH')
                log.append(dict(t=tr, ev='restore', bytes=cur_bytes.hex(), n=n,
                                readback=rb.hex(), result=restore['result']))
                # second attempt only if the first left a mismatch and we are still in window
                if restore['result'] == 'MISMATCH' and time.monotonic() - t0 < MAX_WINDOW_S:
                    os.pwrite(fd, cur_bytes, addr)
                    rb2 = os.pread(fd, 4, addr)
                    restore['second_attempt_bytes'] = rb2.hex()
                    restore['second_attempt_x'] = struct.unpack('<f', rb2)[0]
                    restore['result'] = ('EXACT' if rb2 == cur_bytes
                                         else 'WITHIN_TOL' if abs(struct.unpack('<f', rb2)[0] - x0) <= H_TOL
                                         else 'RESTORE_FAILED')
                    log.append(dict(t=now(), ev='restore_retry', readback=rb2.hex(),
                                    result=restore['result']))
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

    result['process_alive'] = (find_pids() == [pid])
    try:
        result['process_starttime_now'] = starttime(read_stat(pid))
        result['process_starttime_stable'] = result['process_starttime_now'] == ctx['starttime']
    except OSError:
        result['process_starttime_stable'] = False

    # post-test resolver corroboration (read-only)
    try:
        fd2 = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
        try:
            post_canon = struct.unpack('<3f', os.pread(fd2, 12, addr))
            post_obs = struct.unpack('<3f', os.pread(fd2, 12, obs_addr))
            cbase = ctx['module_base'] + CHAR_TABLE_RVA + ctx['group'] * CHAR_STRIDE
            post_char = struct.unpack('<3f', os.pread(fd2, 12, cbase + CHAR_POS_OFF))
        finally:
            os.close(fd2)
        result['post_test'] = dict(canon_4B80=list(post_canon), obs_2B0=list(post_obs),
                                   char_310=list(post_char))
    except OSError as e:
        result['post_test'] = dict(error=str(e))

    result['ai_partner_affected'] = False
    result['log'] = log
    result['finished'] = now()

    (d / 'restore_x.bin').write_bytes(cur_bytes)

    r = result.get('restoration', {}).get('result', '')
    if 'error' in result and not wrote:
        verdict = 'FAIL (aborted before write: %s)' % result['error']
    elif result.get('anomaly') or not result['process_alive'] or not result.get('process_starttime_stable'):
        verdict = 'FAIL (anomaly / process unstable) — restore %s' % r
    elif r in ('EXACT', 'WITHIN_TOL'):
        er = result.get('engine_response', '')
        if er.startswith('CANONICAL CONFIRMED'):
            verdict = 'PASS (canonical write held AND propagated to +0x2B0; restored)'
        elif er.startswith('HELD'):
            verdict = 'PARTIAL (write held but did not propagate to +0x2B0; restored)'
        elif er.startswith('REVERTED'):
            verdict = 'PARTIAL (engine overwrote +0x4B80; restored cleanly)'
        else:
            verdict = 'PARTIAL (engine response %s; restored)' % er
    else:
        verdict = 'FAIL (restore %s)' % r
    result['verdict'] = verdict
    (d / 'result.json').write_text(json.dumps(result, indent=2) + '\n')

    print('=== MVP 2B ARMED RUN COMPLETE ===')
    print(f"write:               X {x0:.6f} -> requested {x_new:.6f}  (bytes {cur_bytes.hex()} -> {new_bytes.hex()})")
    print(f"immediate readback:  +0x4B80 X = {result.get('immediate_readback_x')}")
    print(f"                     +0x2B0  = {result.get('immediate_obs_2B0')}")
    for o in result.get('observation', []):
        print(f"  obs  +0x4B80=({o['canon'][0]:.4f},{o['canon'][1]:.4f},{o['canon'][2]:.4f})  "
              f"+0x2B0.x={o['obs_2B0'][0]:.4f}  |vel|={max(abs(v) for v in o['vel_4BC0']):.4f}")
    print(f"engine response:     {result.get('engine_response')}")
    print(f"anomaly:             {result.get('anomaly')}")
    print(f"restoration:         {result['restoration'].get('result')}  readback {result['restoration'].get('readback_x')}")
    print(f"post-test:           {result.get('post_test')}")
    print(f"process alive:       {result['process_alive']}   starttime stable: {result.get('process_starttime_stable')}")
    print(f"AI partner affected: NO")
    print(f"VERDICT:             {verdict}")
    print(f"evidence:            {d / 'result.json'}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--armed', action='store_true', help='perform the single write + auto restore')
    ap.add_argument('--confirm', default='', help='"AUTORIZO MVP 2B: WRITE +<delta> X en object+0x4B80" matching --delta')
    ap.add_argument('--delta', type=float, default=DELTA, help='X delta in world units (default 0.30)')
    ap.add_argument('--evidence-dir', help='evidence dir (dry run creates it; armed run reuses it)')
    a = ap.parse_args()

    try:
        if a.armed:
            if not a.evidence_dir:
                print('refused: --armed requires --evidence-dir from the dry run', file=sys.stderr)
                return 2
            return armed_run(a.evidence_dir, a.confirm, a.delta)
        ed = a.evidence_dir or ('docs/research/player/MVP2B_WRITE_TEST_' +
                                datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
        print(f'evidence-dir: {ed}')
        return dry_run(ed, a.delta)
    except Gate as e:
        print(f'GATE FAILED — NO WRITE: {e}', file=sys.stderr)
        return 1
    except (OSError, RuntimeError) as e:
        print(f'ERROR — NO WRITE: {type(e).__name__}: {e}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
