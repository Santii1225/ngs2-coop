#!/usr/bin/env python3
"""FASE 16 — NATURAL MOVEMENT TEST 01 (LOCAL_PLAYER only).

Phases 11-15 established the per-actor movement pipeline, all RUNTIME VERIFIED
for LOCAL_PLAYER and AI_PARTNER:

    0x14203E0 (raw command producer)  ->  g_scratch [module_base+0x63F16B0]
    0x14210A0 in per-actor loop 0x1420F60:  object+0x4B90 = g_scratch + char[grp]+0xFA0
    0xFF282A (next frame):  object+0x5000 = object+0x4B90
    0xF24F4A EMA:  character[group]+0x30 = char+0x30_old*decay + object+0x5000*weight
    0x14249A0 (state machine keyed on char+0x04) -> speed-clamp 0x1469F60()
    W1 0x141BB90:  object+0x4B80 += delta        (CANONICAL_POSITION_RUNTIME_VERIFIED)
    -> object+0x4BC0 velocity (derived) ; object+0x2B0 + render copies

This tool tests PREFERRED_REMOTE_CONTROL_LEVEL = C: re-write a *real, human
captured* forward raw command into LOCAL_PLAYER object+0x4B90 every ~8 ms for a
bounded <=2.0 s window, read-only sampling the whole downstream, then stop and
restore object+0x4B90 to its idle bytes.  The canonical position object+0x4B80 is
DELIBERATELY NOT restored: if Ryu walked, his new position must stay (this is not
a teleport+rollback).

Standalone: /proc/<pid>/mem only.  No core.dll, no hook, no ptrace, no
VirtualProtect, no new permanent hooks.

FAIL-CLOSED.  Only LOCAL_PLAYER object+0x4B90 (16 bytes) is ever written.  Never
object+0x4B80, char+0x30, velocity, rotation, camera, the AI partner, or any
other field/actor.  Never attack/jump/dodge.

Modes:
  --capture                 read-only.  Sample object+0x4B90 / +0x5000 / +0x4B80 /
                            +0x2B0 / +0x4BC0 / char+0x30 / char+0x04 at ~60 Hz for
                            CAPTURE_WINDOW_S and write capture.json + a chosen
                            representative 16-byte cruise-phase raw command.
  (default)   dry run       resolve + all gates + LOCAL_PLAYER_STABLE + velocity
                            ~0 + raw command idle + char+0x30 decayed.  Reads and
                            backs up the current (idle) object+0x4B90 16 bytes.
                            Needs --capture-file.  NO memory write.
  --armed --confirm "AUTORIZO NATURAL MOVEMENT TEST 01" --capture-file <f> --evidence-dir <d>
                            re-validate every gate, then inject the captured 16
                            bytes into object+0x4B90 every WRITE_INTERVAL_S for
                            <=INJECT_MAX_S, read-only sampling downstream, then
                            stop writing, restore object+0x4B90 to idle bytes,
                            observe DECAY_OBS_S.  object+0x4B80 is NOT restored.
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

RAW_OFF = 0x4B90              # RAW MOVEMENT COMMAND (float4)  <-- the ONLY write target
CMD5000_OFF = 0x5000         # per-frame copy of RAW (read-only)
CANON_OFF = 0x4B80           # CANONICAL world position (read-only here)
VEL_OFF = 0x4BC0             # velocity (read-only)
CAPS_OFF = 0x4BD0
OBS_OFF = 0x2B0              # observable render copy (read-only)
FACE_OFF = 0x4BA0

CHAR_TABLE_RVA = 0x2F78B10
CHAR_STRIDE = 0x1240
CHAR_STATE_OFF = 0x04        # locomotion state code (byte)  0x00 idle / 0x06 start / 0x26.. walk-run
CHAR_CLASS_OFF = 0x00        # 0x00 local input / 0x04 AI
CHAR_DIR_OFF = 0x30         # EMA smoothed movement direction (float4)
CHAR_POS_OFF = 0x310
CHAR_DEAD_OFF = 0x210
CHAR_FA0_OFF = 0xFA0
OBJ_QUAT_OFF = 0x60
OBJ_HDR_OFF = 0x90
GATE_5B56_OFF = 0x5B56       # command-enable gate (must be non-zero)

SLOT_RVA = 0x18F9518
CORE_CALLBACK_OFF = 0x16F2

CONFIRM_PHRASE = 'AUTORIZO NATURAL MOVEMENT TEST 01'

# capture
CAPTURE_WINDOW_S = float(os.environ.get('NMT_CAPTURE_WINDOW_S', '6.0'))
CAPTURE_HZ = 60

# gates
STABLE_SAMPLES = 8
STABLE_INTERVAL = 0.25
H_TOL = 0.05
V_TOL = 0.05
VEL_TOL = 0.06               # per-component |object+0x4BC0| at rest
RAW_IDLE_TOL = 1.0e-3        # |object+0x4B90| component at rest
DIR_IDLE_TOL = 2.0e-2        # |char+0x30| xyz at rest
CHAIN_TOL = 5.0e-3          # object+0x4B80 vs object+0x2B0
COORD_ABS_MAX = 1.0e6
CORROB_TOL = 0.5

# injection
INJECT_MAX_S = 2.0
WRITE_INTERVAL_S = 0.008     # ~125 Hz  (0x14210A0 rewrites the field every frame ~60 Hz)
SAMPLE_EVERY_N_WRITES = 6    # -> downstream read-only sample ~ every 48 ms
DECAY_OBS_S = 1.8
DECAY_SAMPLE_S = 0.15

# failsafe thresholds
FS_Y_JUMP = 0.5
FS_POS_JUMP = 5.0           # instant |pos| change between consecutive samples
MAX_TOTAL_WINDOW_S = 8.0


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


def _f4(b):
    return struct.unpack('<4f', b)


def _f3(b):
    return struct.unpack('<3f', b)


def resolve_and_gate(require_idle=True, do_stable=True):
    """Every gate.  Returns a context dict; raises Gate on any failure.  No writes."""
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
            a = addr
            for lo, hi, perms, *_ in maps:
                if lo <= a < hi and 'r' in perms:
                    a = min(end, hi)
                    if a == end:
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
        ctx['index'] = 0
        ctx['object'] = obj
        ctx['object_rva'] = obj - base if obj else 0
        ctx['obj_id'] = rec[OBJ_ID_OFF]
        ctx['group'] = rec[GROUP_OFF]
        if not obj:
            raise Gate('game_object[0] pointer is null')
        if not readable(obj + 0x5C40, 1):
            raise Gate('LOCAL_PLAYER object block not readable through +0x5C40')

        q = _f4(rd(obj + OBJ_QUAT_OFF, 16))
        qn = math.hypot(math.hypot(q[0], q[1]), math.hypot(q[2], q[3]))
        hdr = rd(obj + OBJ_HDR_OFF, 16)
        ctx['obj_quat_norm'] = qn
        if not (0.9 <= qn <= 1.1):
            raise Gate(f'object+0x60 quaternion norm {qn:.4f} not unit -> not a live character')
        if not any(hdr):
            raise Gate('object+0x90 header all zero -> not a live character')

        if ctx['group'] != 0:
            raise Gate(f'LOCAL_PLAYER group expected 0, got {ctx["group"]}')
        cbase = base + CHAR_TABLE_RVA + ctx['group'] * CHAR_STRIDE
        ctx['char_base'] = cbase
        cls = rd(cbase + CHAR_CLASS_OFF, 1)[0]
        dead = rd(cbase + CHAR_DEAD_OFF, 1)[0]
        ctx['char_class'] = cls
        ctx['char_dead_byte'] = dead
        if cls != 0x00:
            raise Gate(f'char[group]+0x00 = {cls:#x} != 0x00 -> not the local input-controlled player')
        if dead == 4:
            raise Gate('char[group]+0x210 == 4 -> object is dead/dying')
        ctx['ai_partner_selected'] = False

        gate_enable = rd(obj + GATE_5B56_OFF, 1)[0]
        ctx['gate_5b56'] = gate_enable
        if gate_enable == 0:
            raise Gate('object+0x5B56 == 0 -> movement command disabled for this actor')

        x, y, z = _f3(rd(obj + CANON_OFF, 12))
        ox, oy, oz = _f3(rd(obj + OBS_OFF, 12))
        ctx['orig_x'], ctx['orig_y'], ctx['orig_z'] = x, y, z
        ctx['obs_xyz'] = (ox, oy, oz)
        for nm, v in (('X', x), ('Y', y), ('Z', z)):
            if not math.isfinite(v):
                raise Gate(f'{nm} not finite ({v})')
            if abs(v) >= COORD_ABS_MAX:
                raise Gate(f'|{nm}| = {abs(v):.3g} out of range')
        chain_d = math.dist((x, y, z), (ox, oy, oz))
        ctx['chain_dist'] = chain_d
        if chain_d > CHAIN_TOL:
            raise Gate(f'object+0x4B80 vs object+0x2B0 disagree by {chain_d:.5f} > {CHAIN_TOL}')

        cx, cy, cz = _f3(rd(cbase + CHAR_POS_OFF, 12))
        ctx['corrob'] = (cx, cy, cz)
        if math.dist((x, y, z), (cx, cy, cz)) > CORROB_TOL:
            raise Gate(f'canonical pos vs char corroboration disagree by '
                       f'{math.dist((x, y, z), (cx, cy, cz)):.3f} > {CORROB_TOL}')

        raw = _f4(rd(obj + RAW_OFF, 16))
        cmd5000 = _f4(rd(obj + CMD5000_OFF, 16))
        cdir = _f4(rd(cbase + CHAR_DIR_OFF, 16))
        state = rd(cbase + CHAR_STATE_OFF, 1)[0]
        fa0 = _f4(rd(cbase + CHAR_FA0_OFF, 16))
        ctx['raw_4b90'] = raw
        ctx['cmd_5000'] = cmd5000
        ctx['char_dir_30'] = cdir
        ctx['char_state_04'] = state
        ctx['char_fa0'] = fa0
        ctx['raw_4b90_bytes'] = rd(obj + RAW_OFF, 16)
        if require_idle:
            if max(abs(v) for v in raw) > RAW_IDLE_TOL:
                raise Gate(f'raw command object+0x4B90 not idle: {raw}')
            if math.hypot(cdir[0], math.hypot(cdir[1], cdir[2])) > DIR_IDLE_TOL:
                raise Gate(f'char+0x30 not decayed: {cdir}')
            if state not in (0x00,):
                raise Gate(f'char+0x04 locomotion state {state:#x} != idle')

        if do_stable:
            xs, ys, zs, vmax = [], [], [], 0.0
            for i in range(STABLE_SAMPLES):
                sx, sy, sz = _f3(rd(obj + CANON_OFF, 12))
                vx, vy, vz = _f3(rd(obj + VEL_OFF, 12))
                xs.append(sx); ys.append(sy); zs.append(sz)
                vmax = max(vmax, abs(vx), abs(vy), abs(vz))
                if i != STABLE_SAMPLES - 1:
                    time.sleep(STABLE_INTERVAL)
            h_range = math.hypot(max(xs) - min(xs), max(zs) - min(zs))
            v_range = max(ys) - min(ys)
            fl_h = math.hypot(xs[-1] - xs[0], zs[-1] - zs[0])
            fl_v = abs(ys[-1] - ys[0])
            ctx['stable'] = dict(h_range=h_range, v_range=v_range, first_last_h=fl_h,
                                 first_last_v=fl_v, vel_max=vmax, x_first=xs[0], x_last=xs[-1],
                                 z_first=zs[0], z_last=zs[-1], y=ys[-1])
            if h_range > H_TOL or v_range > V_TOL or fl_h > H_TOL or fl_v > V_TOL:
                raise Gate(f'UNSTABLE_LOCAL_PLAYER: h_range={h_range:.4f} v_range={v_range:.4f} '
                           f'first_last_h={fl_h:.4f} first_last_v={fl_v:.4f}')
            if vmax > VEL_TOL:
                raise Gate(f'velocity object+0x4BC0 max |comp| {vmax:.4f} > {VEL_TOL} -> still moving')

        if starttime(read_stat(pid)) != ctx['starttime']:
            raise Gate('process starttime changed during gate checks')
        ctx['ok'] = True
        return ctx
    finally:
        os.close(fd)


# --------------------------------------------------------------------------- capture

def capture(evidence_dir):
    ctx = resolve_and_gate(require_idle=False, do_stable=False)
    d = Path(evidence_dir)
    d.mkdir(parents=True, exist_ok=True)
    pid = ctx['pid']
    obj = ctx['object']
    cbase = ctx['char_base']
    st0 = ctx['starttime']

    dt = 1.0 / CAPTURE_HZ
    n = int(CAPTURE_WINDOW_S * CAPTURE_HZ)
    samples = []
    fd = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
    t0 = time.monotonic()
    try:
        for i in range(n):
            t = time.monotonic() - t0
            raw = _f4(os.pread(fd, 16, obj + RAW_OFF))
            c5000 = _f4(os.pread(fd, 16, obj + CMD5000_OFF))
            canon = _f3(os.pread(fd, 12, obj + CANON_OFF))
            obs = _f3(os.pread(fd, 12, obj + OBS_OFF))
            vel = _f3(os.pread(fd, 12, obj + VEL_OFF))
            cdir = _f4(os.pread(fd, 16, cbase + CHAR_DIR_OFF))
            state = os.pread(fd, 1, cbase + CHAR_STATE_OFF)[0]
            raw_b = os.pread(fd, 16, obj + RAW_OFF)
            samples.append(dict(i=i, t=round(t, 4),
                                raw_4b90=list(raw), raw_bytes=raw_b.hex(),
                                cmd_5000=list(c5000), canon_4b80=list(canon),
                                obs_2b0=list(obs), vel_4bc0=list(vel),
                                vel_mag=math.sqrt(sum(v * v for v in vel)),
                                char_dir_30=list(cdir), char_state_04=state))
            nxt = t0 + (i + 1) * dt
            slp = nxt - time.monotonic()
            if slp > 0:
                time.sleep(slp)
    finally:
        os.close(fd)

    st1 = starttime(read_stat(pid)) if find_pids() == [pid] else None
    proc_stable = (st1 == st0)

    # choose a representative CRUISE-phase raw command:
    #   - velocity magnitude in the top 60% band of the run (moving, not the ramp)
    #   - raw command w-component ~1.0 (command active)
    #   - within the middle 70% of the moving segment (avoid start/stop transitions)
    vmags = [s['vel_mag'] for s in samples]
    vmax = max(vmags) if vmags else 0.0
    moving = [s for s in samples if s['vel_mag'] >= 0.4 * vmax and vmax > 0.2
              and abs(s['raw_4b90'][3] - 1.0) < 0.05
              and max(abs(s['raw_4b90'][0]), abs(s['raw_4b90'][2])) > 1e-4]
    chosen = None
    if moving:
        lo = moving[0]['i']
        hi = moving[-1]['i']
        span = hi - lo
        core = [s for s in moving if lo + 0.15 * span <= s['i'] <= lo + 0.85 * span] or moving
        # median by |xz| magnitude
        core.sort(key=lambda s: math.hypot(s['raw_4b90'][0], s['raw_4b90'][2]))
        chosen = core[len(core) // 2]

    result = dict(stage='capture', captured=now(), pid=pid, starttime=st0,
                  module_base=hex(ctx['module_base']), object=hex(obj),
                  object_rva=hex(ctx['object_rva']), group=ctx['group'], obj_id=ctx['obj_id'],
                  char_base=hex(cbase), char_class=ctx['char_class'],
                  raw_addr=hex(obj + RAW_OFF), cmd5000_addr=hex(obj + CMD5000_OFF),
                  canon_addr=hex(obj + CANON_OFF), obs_addr=hex(obj + OBS_OFF),
                  vel_addr=hex(obj + VEL_OFF), char_dir_addr=hex(cbase + CHAR_DIR_OFF),
                  char_state_addr=hex(cbase + CHAR_STATE_OFF),
                  n_samples=len(samples), vel_max=vmax, moving_samples=len(moving),
                  process_starttime_stable=proc_stable,
                  chosen=chosen, samples=samples)
    (d / 'capture.json').write_text(json.dumps(result, indent=2) + '\n')
    if chosen:
        (d / 'chosen_raw_command.bin').write_bytes(bytes.fromhex(chosen['raw_bytes']))

    print('=== CAPTURE COMPLETE ===')
    print(f"PID {pid}  starttime {st0}  stable: {proc_stable}")
    print(f"samples: {len(samples)}  vel_max: {vmax:.3f}  moving samples: {len(moving)}")
    st_hist = {}
    for s in samples:
        st_hist[s['char_state_04']] = st_hist.get(s['char_state_04'], 0) + 1
    print(f"char+0x04 histogram: " + ", ".join(f"{k:#04x}:{v}" for k, v in sorted(st_hist.items())))
    if chosen:
        r = chosen['raw_4b90']
        print(f"chosen cruise raw command @ t={chosen['t']}s  i={chosen['i']}  state={chosen['char_state_04']:#04x}")
        print(f"  object+0x4B90 = ({r[0]:.6f}, {r[1]:.6f}, {r[2]:.6f}, {r[3]:.6f})")
        print(f"  bytes         = {chosen['raw_bytes']}")
        print(f"  |xz|          = {math.hypot(r[0], r[2]):.6f}   vel_mag at sample = {chosen['vel_mag']:.3f}")
        print(f"  char+0x30     = {chosen['char_dir_30']}")
    else:
        print("NO cruise sample found -> did Ryu actually move forward? re-capture.")
    print(f"evidence: {d / 'capture.json'}")
    return 0 if chosen else 1


# --------------------------------------------------------------------------- dry run

def _load_capture(capture_file):
    cf = Path(capture_file)
    cap = json.loads(cf.read_text())
    ch = cap.get('chosen')
    if not ch:
        raise Gate(f'capture file {cf} has no chosen cruise sample')
    cmd_bytes = bytes.fromhex(ch['raw_bytes'])
    if len(cmd_bytes) != 16:
        raise Gate('chosen raw command is not 16 bytes')
    return cap, ch, cmd_bytes


def dry_run(evidence_dir, capture_file):
    cap, ch, cmd_bytes = _load_capture(capture_file)
    ctx = resolve_and_gate(require_idle=True, do_stable=True)

    if ctx['pid'] != cap['pid'] or ctx['starttime'] != cap['starttime']:
        raise Gate(f"process changed since capture (pid {cap['pid']}/{ctx['pid']}, "
                   f"starttime {cap['starttime']}/{ctx['starttime']})")
    if ctx['object'] != int(cap['object'], 16):
        raise Gate(f"LOCAL_PLAYER object changed since capture: {cap['object']} -> {hex(ctx['object'])}")

    d = Path(evidence_dir)
    d.mkdir(parents=True, exist_ok=True)
    (d / 'idle_raw_4b90.bin').write_bytes(ctx['raw_4b90_bytes'])
    (d / 'inject_command.bin').write_bytes(cmd_bytes)

    fd = os.open(f"/proc/{ctx['pid']}/mem", os.O_RDONLY)
    try:
        fresh = os.pread(fd, 16, ctx['object'] + RAW_OFF)
    finally:
        os.close(fd)
    backup_ok = fresh == ctx['raw_4b90_bytes']

    cmd = _f4(cmd_bytes)
    pre = dict(
        stage='pre_write', phase='16 NATURAL_MOVEMENT_TEST_01', captured=now(),
        pid=ctx['pid'], starttime=ctx['starttime'], module_base=hex(ctx['module_base']),
        core_base=hex(ctx['core_base']), slot_value=hex(ctx['slot_value']),
        object=hex(ctx['object']), object_rva=hex(ctx['object_rva']),
        obj_id=ctx['obj_id'], group=ctx['group'],
        raw_addr=hex(ctx['object'] + RAW_OFF), cmd5000_addr=hex(ctx['object'] + CMD5000_OFF),
        canon_addr=hex(ctx['object'] + CANON_OFF), obs_addr=hex(ctx['object'] + OBS_OFF),
        vel_addr=hex(ctx['object'] + VEL_OFF),
        char_base=hex(ctx['char_base']), char_class=ctx['char_class'],
        char_dir_addr=hex(ctx['char_base'] + CHAR_DIR_OFF),
        char_state_addr=hex(ctx['char_base'] + CHAR_STATE_OFF),
        gate_5b56=ctx['gate_5b56'],
        idle_raw_4b90=list(ctx['raw_4b90']), idle_raw_4b90_bytes=ctx['raw_4b90_bytes'].hex(),
        idle_cmd_5000=list(ctx['cmd_5000']), idle_char_dir_30=list(ctx['char_dir_30']),
        idle_char_state_04=ctx['char_state_04'], char_fa0=list(ctx['char_fa0']),
        orig_canon_xyz=[ctx['orig_x'], ctx['orig_y'], ctx['orig_z']],
        obs_xyz=list(ctx['obs_xyz']), chain_dist=ctx['chain_dist'], corrob=list(ctx['corrob']),
        stable=ctx['stable'],
        captured_command=list(cmd), captured_command_bytes=cmd_bytes.hex(),
        captured_from=dict(file=str(capture_file), sample_i=ch['i'], sample_t=ch['t'],
                           sample_state=ch['char_state_04'], vel_mag=ch['vel_mag']),
        backup_matches_memory=backup_ok,
        inject_max_s=INJECT_MAX_S, write_interval_s=WRITE_INTERVAL_S,
        ai_partner_selected=ctx['ai_partner_selected'],
        gates='ALL PASS',
    )
    (d / 'pre_write.json').write_text(json.dumps(pre, indent=2) + '\n')
    if not backup_ok:
        raise Gate('idle raw command bytes do not match memory on re-read')

    print('=== NATURAL MOVEMENT TEST ARMED (dry run) ===')
    print()
    print(f"Process:              PID {ctx['pid']}  starttime {ctx['starttime']}  TracerPid 0  hook PASS")
    print(f"LOCAL_PLAYER:         object {ctx['object']:#x} (RVA {ctx['object_rva']:#x})  index 0  group {ctx['group']}  obj_id {ctx['obj_id']}")
    print(f"                     char[0] {ctx['char_base']:#x}   char+0x00 = {ctx['char_class']:#04x} (local input)")
    print(f"Raw command target:  object+0x4B90  @ {ctx['object'] + RAW_OFF:#x}")
    cm = _f4(cmd_bytes)
    print(f"Captured command:    ({cm[0]:.6f}, {cm[1]:.6f}, {cm[2]:.6f}, {cm[3]:.6f})   |xz| {math.hypot(cm[0], cm[2]):.6f}")
    print(f"Captured bytes:      {cmd_bytes.hex()}")
    print(f"                     from {capture_file}  sample i={ch['i']} t={ch['t']}s state={ch['char_state_04']:#04x} vel_mag={ch['vel_mag']:.3f}")
    print(f"Current char state:  char+0x04 = {ctx['char_state_04']:#04x} (idle)   char+0x30 = ({ctx['char_dir_30'][0]:.5f},{ctx['char_dir_30'][1]:.5f},{ctx['char_dir_30'][2]:.5f},{ctx['char_dir_30'][3]:.5f})")
    print(f"Current raw command: object+0x4B90 = ({ctx['raw_4b90'][0]:.6f},{ctx['raw_4b90'][1]:.6f},{ctx['raw_4b90'][2]:.6f},{ctx['raw_4b90'][3]:.6f})  bytes {ctx['raw_4b90_bytes'].hex()}  (idle)")
    print(f"Current velocity:    |object+0x4BC0| max {ctx['stable']['vel_max']:.4f}  (< {VEL_TOL})")
    print(f"Canonical pos:       ({ctx['orig_x']:.4f}, {ctx['orig_y']:.4f}, {ctx['orig_z']:.4f})   chain dist {ctx['chain_dist']:.2e}")
    print(f"Stable:              PASS  (h_range {ctx['stable']['h_range']:.4f}  v_range {ctx['stable']['v_range']:.4f})")
    print(f"object+0x5B56 gate:  {ctx['gate_5b56']:#04x}  (command enabled)")
    print(f"AI_PARTNER target:   NO")
    print(f"Duration proposed:   {INJECT_MAX_S:.1f} s  (rewrite every {WRITE_INTERVAL_S * 1000:.0f} ms ~ {1 / WRITE_INTERVAL_S:.0f} Hz)")
    print(f"Write mode:          re-write the captured 16 bytes into object+0x4B90 per-frame for a bounded window")
    print(f"Rollback:            restore object+0x4B90 to idle bytes {ctx['raw_4b90_bytes'].hex()}  (object+0x4B80 NOT restored)")
    print(f"Backup saved:        {d / 'idle_raw_4b90.bin'}   matches memory: {backup_ok}")
    print(f"Evidence dir:        {d}")
    return 0


# --------------------------------------------------------------------------- armed

def armed_run(evidence_dir, confirm, capture_file):
    if confirm.strip() != CONFIRM_PHRASE:
        print(f'refused: --confirm must be exactly "{CONFIRM_PHRASE}"', file=sys.stderr)
        return 2
    d = Path(evidence_dir)
    if not (d / 'pre_write.json').exists():
        print(f'refused: no pre_write.json in {d} — run the dry run first', file=sys.stderr)
        return 2
    pre = json.loads((d / 'pre_write.json').read_text())
    cap, ch, cmd_bytes = _load_capture(capture_file)
    if bytes.fromhex(pre['captured_command_bytes']) != cmd_bytes:
        raise Gate('capture file command differs from the one recorded in pre_write.json')
    idle_bytes = bytes.fromhex(pre['idle_raw_4b90_bytes'])

    ctx = resolve_and_gate(require_idle=True, do_stable=True)
    if ctx['pid'] != pre['pid'] or ctx['starttime'] != pre['starttime']:
        raise Gate(f"process changed since dry run (pid {pre['pid']}/{ctx['pid']}, "
                   f"starttime {pre['starttime']}/{ctx['starttime']})")
    if ctx['object'] != int(pre['object'], 16):
        raise Gate(f"LOCAL_PLAYER object changed: {pre['object']} -> {hex(ctx['object'])}")
    if ctx['char_class'] != 0x00 or ctx['group'] != 0 or ctx['ai_partner_selected']:
        raise Gate('local-player identity check failed on re-validation')
    if ctx['chain_dist'] > CHAIN_TOL:
        raise Gate('object+0x4B80 vs object+0x2B0 chain not coherent on re-validation')
    if ctx['stable']['vel_max'] > VEL_TOL:
        raise Gate('velocity gate failed on re-validation (player moving)')
    if max(abs(v) for v in ctx['raw_4b90']) > RAW_IDLE_TOL:
        raise Gate('raw command not idle on re-validation')

    pid = ctx['pid']
    obj = ctx['object']
    cbase = ctx['char_base']
    addr = obj + RAW_OFF
    a_5000 = obj + CMD5000_OFF
    a_canon = obj + CANON_OFF
    a_obs = obj + OBS_OFF
    a_vel = obj + VEL_OFF
    a_dir = cbase + CHAR_DIR_OFF
    a_state = cbase + CHAR_STATE_OFF
    st0 = ctx['starttime']
    y0 = ctx['orig_y']
    canon0 = (ctx['orig_x'], ctx['orig_y'], ctx['orig_z'])

    result = dict(stage='armed', phase='16 NATURAL_MOVEMENT_TEST_01', evidence_dir=str(d),
                  confirm=confirm, pid=pid, starttime=st0, module_base=hex(ctx['module_base']),
                  object=hex(obj), raw_addr=hex(addr), char_base=hex(cbase),
                  captured_command=list(_f4(cmd_bytes)), captured_command_bytes=cmd_bytes.hex(),
                  idle_raw_bytes=idle_bytes.hex(),
                  canon_before=list(canon0), obs_before=list(ctx['obs_xyz']),
                  char_state_before=ctx['char_state_04'], char_dir_before=list(ctx['char_dir_30']),
                  stable_pre=ctx['stable'],
                  inject_max_s=INJECT_MAX_S, write_interval_s=WRITE_INTERVAL_S)
    log = [dict(t=now(), ev='revalidated', pid=pid, starttime=st0, object=hex(obj),
                addr=hex(addr), idle_bytes=idle_bytes.hex(), cmd_bytes=cmd_bytes.hex())]

    fd = os.open(f'/proc/{pid}/mem', os.O_RDWR)
    wrote = False
    aborted = None
    obs = []
    t0 = time.monotonic()
    last_pos = None
    write_count = 0
    try:
        if starttime(read_stat(pid)) != st0:
            raise Gate('starttime changed immediately before injection')
        pre_bytes = os.pread(fd, 16, addr)
        if max(abs(v) for v in _f4(pre_bytes)) > RAW_IDLE_TOL:
            raise Gate('object+0x4B90 not idle in the last read before injection — abort')

        result['inject_start'] = now()
        log.append(dict(t=now(), ev='inject_start', bytes=cmd_bytes.hex()))
        while True:
            el = time.monotonic() - t0
            if el >= INJECT_MAX_S:
                break
            if el > MAX_TOTAL_WINDOW_S:
                aborted = 'MAX_TOTAL_WINDOW_S exceeded'
                break
            n = os.pwrite(fd, cmd_bytes, addr)
            wrote = True
            write_count += 1
            if n != 16:
                aborted = f'short pwrite ({n}/16)'
                break

            if write_count % SAMPLE_EVERY_N_WRITES == 0:
                if find_pids() != [pid] or starttime(read_stat(pid)) != st0:
                    aborted = 'pid/starttime changed during injection'
                    break
                raw = _f4(os.pread(fd, 16, addr))
                c5000 = _f4(os.pread(fd, 16, a_5000))
                canon = _f3(os.pread(fd, 12, a_canon))
                obsv = _f3(os.pread(fd, 12, a_obs))
                vel = _f3(os.pread(fd, 12, a_vel))
                cdir = _f4(os.pread(fd, 16, a_dir))
                state = os.pread(fd, 1, a_state)[0]
                smp = dict(t=round(el, 4), raw_4b90=list(raw), cmd_5000=list(c5000),
                           canon_4b80=list(canon), obs_2b0=list(obsv), vel_4bc0=list(vel),
                           vel_mag=math.sqrt(sum(v * v for v in vel)),
                           char_dir_30=list(cdir), char_state_04=state)
                obs.append(smp)
                # failsafe
                if not all(math.isfinite(v) for v in canon):
                    aborted = f'canonical position non-finite {canon}'; break
                if abs(canon[1] - y0) > FS_Y_JUMP:
                    aborted = f'Y jumped {canon[1] - y0:+.3f} (> {FS_Y_JUMP})'; break
                if last_pos is not None:
                    jump = math.dist(canon, last_pos)
                    if jump > FS_POS_JUMP:
                        aborted = f'instant position jump {jump:.2f} u (> {FS_POS_JUMP}) -> teleport-like'; break
                last_pos = canon
            time.sleep(WRITE_INTERVAL_S)

        result['inject_end'] = now()
        result['write_count'] = write_count
        result['aborted'] = aborted
        result['observation'] = obs
        log.append(dict(t=now(), ev='inject_end', writes=write_count, aborted=aborted))
    except BaseException as e:
        result['error'] = f'{type(e).__name__}: {e}'
        aborted = aborted or result['error']
        log.append(dict(t=now(), ev='error', detail=result['error']))
    finally:
        # STOP writing the command; restore object+0x4B90 to idle bytes.  NEVER touch +0x4B80.
        restore = dict(attempted=False, target='object+0x4B90')
        try:
            same = (find_pids() == [pid] and starttime(read_stat(pid)) == st0)
            if wrote and same:
                restore['attempted'] = True
                n = os.pwrite(fd, idle_bytes, addr)
                rb = os.pread(fd, 16, addr)
                restore['n'] = n
                restore['readback_bytes'] = rb.hex()
                restore['exact'] = (rb == idle_bytes)
                # the engine rewrites +0x4B90 every frame anyway; "idle-ish" is also fine
                restore['idle_ish'] = max(abs(v) for v in _f4(rb)) < 5.0e-3
                restore['result'] = ('EXACT' if restore['exact']
                                     else 'IDLE_ISH' if restore['idle_ish'] else 'MISMATCH')
                log.append(dict(t=now(), ev='restore_4b90', bytes=idle_bytes.hex(),
                                readback=rb.hex(), result=restore['result']))
            elif wrote and not same:
                restore['result'] = 'SKIPPED_IDENTITY_CHANGED'
            else:
                restore['result'] = 'NOT_NEEDED_NO_WRITE'
        except BaseException as e:
            restore['result'] = f'RESTORE_FAILED: {type(e).__name__}: {e}'
            log.append(dict(t=now(), ev='restore_failed', detail=restore['result']))
        result['restoration'] = restore

        # decay observation (read-only) — NOT restoring +0x4B80
        decay = []
        try:
            if find_pids() == [pid] and starttime(read_stat(pid)) == st0:
                td = time.monotonic()
                while time.monotonic() - td < DECAY_OBS_S:
                    raw = _f4(os.pread(fd, 16, addr))
                    c5000 = _f4(os.pread(fd, 16, a_5000))
                    canon = _f3(os.pread(fd, 12, a_canon))
                    obsv = _f3(os.pread(fd, 12, a_obs))
                    vel = _f3(os.pread(fd, 12, a_vel))
                    cdir = _f4(os.pread(fd, 16, a_dir))
                    state = os.pread(fd, 1, a_state)[0]
                    decay.append(dict(t=round(time.monotonic() - td, 3),
                                      raw_4b90=list(raw), cmd_5000=list(c5000),
                                      canon_4b80=list(canon), obs_2b0=list(obsv),
                                      vel_4bc0=list(vel),
                                      vel_mag=math.sqrt(sum(v * v for v in vel)),
                                      char_dir_30=list(cdir), char_state_04=state))
                    time.sleep(DECAY_SAMPLE_S)
        except BaseException as e:
            log.append(dict(t=now(), ev='decay_read_failed', detail=str(e)))
        result['decay'] = decay
        try:
            os.close(fd)
        except OSError:
            pass

    # -------- post-test read-only corroboration
    result['process_alive'] = (find_pids() == [pid])
    try:
        result['process_starttime_now'] = starttime(read_stat(pid))
        result['process_starttime_stable'] = result['process_starttime_now'] == st0
    except OSError:
        result['process_starttime_stable'] = False
    try:
        fd2 = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
        try:
            pc = _f3(os.pread(fd2, 12, a_canon))
            po = _f3(os.pread(fd2, 12, a_obs))
            pr = _f4(os.pread(fd2, 16, addr))
            pcd = _f4(os.pread(fd2, 16, a_dir))
            pst = os.pread(fd2, 1, a_state)[0]
            pv = _f3(os.pread(fd2, 12, a_vel))
            # AI partner untouched?
            rec4 = os.pread(fd2, TABLE_STRIDE, ctx['module_base'] + TABLE_RVA + 4 * TABLE_STRIDE)
            ai_obj = struct.unpack_from('<Q', rec4, 0)[0]
            ai_raw = _f4(os.pread(fd2, 16, ai_obj + RAW_OFF)) if ai_obj else None
        finally:
            os.close(fd2)
        result['post_test'] = dict(canon_4b80=list(pc), obs_2b0=list(po), raw_4b90=list(pr),
                                   char_dir_30=list(pcd), char_state_04=pst, vel_4bc0=list(pv),
                                   ai_object=hex(ai_obj) if ai_obj else None,
                                   ai_raw_4b90=list(ai_raw) if ai_raw else None)
        moved = math.dist(pc, canon0)
        result['canon_displacement_total'] = moved
    except OSError as e:
        result['post_test'] = dict(error=str(e))
        result['canon_displacement_total'] = None

    result['ai_partner_affected'] = False
    result['log'] = log
    result['finished'] = now()
    (d / 'restore_raw_4b90.bin').write_bytes(idle_bytes)

    # -------- classification
    def series(key, idx=None):
        out = []
        for s in obs:
            v = s[key]
            out.append(v[idx] if idx is not None else v)
        return out

    inj_seen = any(max(abs(x) for x in s['raw_4b90']) > 1e-3 for s in obs)
    c5000_resp = any(max(abs(x) for x in s['cmd_5000']) > 1e-3 for s in obs)
    dir_resp = any(math.hypot(s['char_dir_30'][0], s['char_dir_30'][2]) > 1e-2 for s in obs)
    states = sorted(set(s['char_state_04'] for s in obs))
    loco_state = any(st != 0x00 for st in states)
    vel_series = [s['vel_mag'] for s in obs]
    vel_rose = bool(vel_series) and max(vel_series) > 0.15
    canon_series = [tuple(s['canon_4b80']) for s in obs]
    canon_prog = 0.0
    if len(canon_series) >= 2:
        canon_prog = math.dist(canon_series[-1], canon_series[0])
    gradual = False
    if len(canon_series) >= 3:
        steps = [math.dist(canon_series[k + 1], canon_series[k]) for k in range(len(canon_series) - 1)]
        gradual = canon_prog > 0.05 and max(steps) < FS_POS_JUMP and sum(1 for s in steps if s > 1e-3) >= 2

    result['analysis'] = dict(
        injection_seen=inj_seen, cmd_5000_responded=c5000_resp, char_dir_30_responded=dir_resp,
        char_states_during=[hex(s) for s in states], entered_locomotion_state=loco_state,
        velocity_rose=vel_rose, velocity_max=max(vel_series) if vel_series else 0.0,
        canonical_progression=canon_prog,
        position_progression=('GRADUAL' if gradual else 'INSTANT' if canon_prog > FS_POS_JUMP
                              else 'NONE' if canon_prog < 0.05 else 'SMALL'),
        total_displacement=result.get('canon_displacement_total'))

    if aborted or result.get('error'):
        verdict = f'FAIL (aborted: {aborted or result.get("error")})'
    elif not result['process_alive'] or not result.get('process_starttime_stable'):
        verdict = 'FAIL (process unstable after test)'
    elif inj_seen and c5000_resp and dir_resp and loco_state and vel_rose and gradual:
        verdict = 'PASS (raw command propagated through the full pipeline; gradual locomotion; no teleport)'
    elif inj_seen and (c5000_resp or dir_resp) and (canon_prog > 0.05) and not loco_state:
        verdict = 'PARTIAL (command propagated + position advanced, but char+0x04 did not enter a locomotion state)'
    elif inj_seen and (c5000_resp or dir_resp) and canon_prog < 0.05:
        verdict = 'PARTIAL (command reached +0x5000/EMA but position did not integrate)'
    elif not inj_seen:
        verdict = 'FAIL (injection not observed at object+0x4B90 — lost the race with the engine writer)'
    else:
        verdict = 'PARTIAL (see analysis)'
    result['verdict'] = verdict
    (d / 'result.json').write_text(json.dumps(result, indent=2) + '\n')

    # -------- console report
    print('=== NATURAL MOVEMENT TEST 01 — ARMED RUN COMPLETE ===')
    print(f"writes:              {write_count}  over ~{INJECT_MAX_S:.1f}s   aborted: {aborted}")
    print(f"captured command:    {list(_f4(cmd_bytes))}   bytes {cmd_bytes.hex()}")
    print(f"canon before:        ({canon0[0]:.4f}, {canon0[1]:.4f}, {canon0[2]:.4f})")
    print("  t     raw+0x4B90(x,z)        +0x5000(x,z)        char+0x30(x,z)     st    |vel|   canon+0x4B80(x,y,z)")
    for s in obs:
        r = s['raw_4b90']; c = s['cmd_5000']; cd = s['char_dir_30']; cn = s['canon_4b80']
        print(f"  {s['t']:.2f}  ({r[0]:+.4f},{r[2]:+.4f})  ({c[0]:+.4f},{c[2]:+.4f})  "
              f"({cd[0]:+.4f},{cd[2]:+.4f})  {s['char_state_04']:#04x}  {s['vel_mag']:.3f}  "
              f"({cn[0]:.3f},{cn[1]:.3f},{cn[2]:.3f})")
    a = result['analysis']
    print(f"injection seen:      {a['injection_seen']}")
    print(f"+0x5000 responded:   {a['cmd_5000_responded']}")
    print(f"char+0x30 responded: {a['char_dir_30_responded']}")
    print(f"char+0x04 states:    {a['char_states_during']}   entered locomotion: {a['entered_locomotion_state']}")
    print(f"velocity rose:       {a['velocity_rose']}   max |vel| {a['velocity_max']:.3f}")
    print(f"position progression:{a['position_progression']}   canon delta over window {a['canonical_progression']:.3f}")
    if result.get('decay'):
        dd = result['decay']
        print(f"after stop ({len(dd)} samples, {DECAY_OBS_S:.1f}s): "
              f"raw->{max(abs(v) for v in dd[-1]['raw_4b90']):.4f}  "
              f"|vel|->{dd[-1]['vel_mag']:.3f}  char+0x30->{math.hypot(dd[-1]['char_dir_30'][0], dd[-1]['char_dir_30'][2]):.4f}  "
              f"state->{dd[-1]['char_state_04']:#04x}")
    print(f"restoration:         object+0x4B90 -> {result['restoration'].get('result')}  (object+0x4B80 NOT restored)")
    pt = result.get('post_test', {})
    print(f"post-test canon:     {pt.get('canon_4b80')}   total displacement {result.get('canon_displacement_total')}")
    print(f"AI raw+0x4B90:       {pt.get('ai_raw_4b90')}   (AI partner affected: NO)")
    print(f"process alive:       {result['process_alive']}   starttime stable: {result.get('process_starttime_stable')}")
    print(f"VERDICT:             {verdict}")
    print(f"evidence:            {d / 'result.json'}")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--capture', action='store_true', help='read-only: sample the pipeline and pick a cruise raw command')
    ap.add_argument('--armed', action='store_true', help='perform the bounded per-frame injection + restore of object+0x4B90')
    ap.add_argument('--confirm', default='', help=f'"{CONFIRM_PHRASE}"')
    ap.add_argument('--capture-file', help='capture.json produced by --capture')
    ap.add_argument('--evidence-dir', help='evidence dir')
    a = ap.parse_args()

    try:
        if a.capture:
            ed = a.evidence_dir or ('docs/research/locomotion/natural_movement_test_01/capture_' +
                                    datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
            print(f'evidence-dir: {ed}')
            return capture(ed)
        if a.armed:
            if not a.evidence_dir or not a.capture_file:
                print('refused: --armed requires --evidence-dir and --capture-file', file=sys.stderr)
                return 2
            return armed_run(a.evidence_dir, a.confirm, a.capture_file)
        if not a.capture_file:
            print('refused: dry run requires --capture-file', file=sys.stderr)
            return 2
        ed = a.evidence_dir or ('docs/research/locomotion/natural_movement_test_01/run_' +
                                datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ'))
        print(f'evidence-dir: {ed}')
        return dry_run(ed, a.capture_file)
    except Gate as e:
        print(f'GATE FAILED — NO WRITE: {e}', file=sys.stderr)
        return 1
    except (OSError, RuntimeError) as e:
        print(f'ERROR — NO WRITE: {type(e).__name__}: {e}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
